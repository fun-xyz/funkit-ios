// Crypto Onramp calls ported from stripe-react-native 0.76.0
// (ios/StripeSdkImpl.swift, ios/OnrampErrors.swift; MIT, © Stripe, Inc.).
// Unlike that module, this runs on a dedicated STPAPIClient and leaves
// StripeAPI.defaultPublishableKey, stripeAccount, appInfo and the 3-D Secure
// globals alone. One exception: STPAPIClient.shared gets the onramp's key when
// the host left it unset, because stripe-ios's Link seamless sign-in reads it
// (see SharedPublishableKey). stripe-ios's signed-in Link account is also
// process-wide, so Link lookup and logout here reach the host's Link session.

#if canImport(StripeCryptoOnramp) && canImport(UIKit)
  import Foundation
  import Funkit
  import PassKit
  import UIKit
  import os
  import StripeCore
  import StripePayments
  @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
  @_spi(CryptoOnrampAlpha) import StripePaymentSheet

  public enum FunkitStripe {
    /// stripe-ios versions this adapter has passed the coexistence tests on.
    /// Others build (Package.swift admits the 26.x range) but log a warning.
    /// None yet in the 26.13 range: 26.14.0 joins once docs/stripe.md's
    /// coexistence matrix passes on it.
    public static let testedStripeVersions: Set<String> = []
  }

  extension FunkitStripeConfiguration {
    /// Stripe's Crypto Onramp on the host's stripe-ios.
    ///
    /// - Parameters:
    ///   - publishableKey: The `pk_` key of the account the onramp settles into.
    ///     Used on a dedicated API client only.
    ///   - merchantDisplayName: Shown on Stripe's sheets.
    ///   - merchantIdentifier: The Apple Pay merchant ID in the host's
    ///     entitlements, with Stripe's payment processing certificate.
    ///   - urlScheme: The host's URL scheme, for Stripe's redirects.
    public static func onramp(
      publishableKey: String,
      merchantDisplayName: String,
      merchantIdentifier: String? = nil,
      urlScheme: String? = nil
    ) -> FunkitStripeConfiguration {
      FunkitStripeConfiguration(
        publishableKey: publishableKey,
        merchantDisplayName: merchantDisplayName,
        merchantIdentifier: merchantIdentifier,
        urlScheme: urlScheme,
        adapter: FunkitStripeOnramp()
      )
    }
  }

  /// Answers connect-rn's `useOnramp` calls, by stripe-react-native's method
  /// names and result shapes.
  @MainActor
  public final class FunkitStripeOnramp: FunkitStripeAdapting {
    private static let logger = Logger(subsystem: "xyz.fun.funkit", category: "stripe")

    private var apiClient: STPAPIClient?
    private var coordinator: CryptoOnrampCoordinator?
    /// Kept for the checkout's 3-D Secure sheet, which holds it weakly.
    private var authenticationContext: AuthenticationContext?
    /// The latest call's context: its flow's container is where sheets present.
    private var callContext: FunkitStripeCallContext?

    public nonisolated init() {}

    public nonisolated func handle(
      method: String,
      arguments: FunkitJSON,
      configuration: FunkitStripeCallContext,
      reverse: FunkitReverseCaller
    ) async -> FunkitJSON {
      await dispatch(method: method, arguments: arguments, configuration: configuration, reverse: reverse)
    }

    public func handleOpenURL(_ url: URL) -> Bool {
      StripeAPI.handleURLCallback(with: url)
    }

    private func dispatch(
      method: String,
      arguments: FunkitJSON,
      configuration: FunkitStripeCallContext,
      reverse: FunkitReverseCaller
    ) async -> FunkitJSON {
      callContext = configuration
      do {
        switch method {
        case "initialise":
          return initialise(configuration)
        case "isPlatformPaySupported":
          return .fields(["supported": .bool(StripeAPI.deviceSupportsApplePay())])
        case "configureOnramp":
          return try await configureOnramp(arguments)
        case "hasLinkAccount":
          let email = try arguments.requiredString("email")
          return .fields(["hasLinkAccount": .bool(try await requireCoordinator().hasLinkAccount(with: email))])
        case "registerLinkUser":
          return try await registerLinkUser(arguments)
        case "authenticateUserWithToken":
          return try await authenticateUserWithToken(arguments)
        case "registerWalletAddress":
          return try await registerWalletAddress(arguments)
        case "attachKycInfo":
          try await requireCoordinator().attachKYCInfo(info: try Self.kycInfo(arguments["info"]))
          return .object([:])
        case "presentKycInfoVerification":
          return try await presentKycInfoVerification(arguments)
        case "verifyIdentity":
          return try await verifyIdentity()
        case "logout":
          try await requireCoordinator().logOut()
          return .object([:])
        case "collectPaymentMethod":
          return try await collectPaymentMethod(arguments, configuration: configuration)
        case "createCryptoPaymentToken":
          let token = try await requireCoordinator().createCryptoPaymentToken()
          return .fields(["cryptoPaymentToken": .string(token)])
        case "performCheckout":
          return try await performCheckout(arguments, reverse: reverse)
        case "onrampAuthorize":
          return try await authorize(arguments)
        default:
          return OnrampErrorMapper.error(code: .failed, message: "Unsupported Stripe call \(method).")
        }
      } catch let error as AdapterError {
        return error.result
      } catch let error as KycInfoError {
        return error.result
      } catch {
        return OnrampErrorMapper.failed(error)
      }
    }

    // MARK: - Setup

    /// Builds the dedicated client. stripe-react-native's `initialise` wrote the
    /// shared client and global key here instead (V2 in the design's register).
    private func initialise(_ configuration: FunkitStripeCallContext) -> FunkitJSON {
      if apiClient?.publishableKey != configuration.publishableKey {
        apiClient = STPAPIClient(publishableKey: configuration.publishableKey)
        coordinator = nil
      }
      if SharedPublishableKey.adopt(configuration.publishableKey) == .hostOwned {
        Self.logger.warning(
          "STPAPIClient.shared holds another publishable key; Stripe's Link sign-in uses it and will fail for the onramp"
        )
      }
      if !FunkitStripe.testedStripeVersions.contains(STPAPIClient.STPSDKVersion) {
        Self.logger.warning(
          "stripe-ios \(STPAPIClient.STPSDKVersion, privacy: .public) is outside FunkitStripe's tested versions"
        )
      }
      return .object([:])
    }

    private func configureOnramp(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      guard let apiClient else { throw AdapterError.notInitialised }
      let configuration = Self.onrampConfiguration(arguments)
      coordinator = try await CryptoOnrampCoordinator.create(
        apiClient: apiClient,
        appearance: configuration.appearance,
        cryptoCustomerID: configuration.cryptoCustomerID,
        additionalSDKVersions: [SDKVersion(name: "funkit-swift", version: FunkitStripeVersion.current)],
        countryHint: configuration.countryHint
      )
      return .object([:])
    }

    private func requireCoordinator() throws -> CryptoOnrampCoordinator {
      guard apiClient != nil else { throw AdapterError.notInitialised }
      guard let coordinator else { throw AdapterError.notConfigured }
      return coordinator
    }

    // MARK: - Link

    private func registerLinkUser(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      let info = arguments["info"]
      let customerID = try await requireCoordinator().registerLinkUser(
        email: info?["email"]?.stringValue ?? "",
        fullName: info?["fullName"]?.stringValue,
        phone: info?["phone"]?.stringValue ?? "",
        country: info?["country"]?.stringValue ?? ""
      )
      return .fields(["customerId": .string(customerID)])
    }

    private func authenticateUserWithToken(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      let token = try arguments.requiredString("linkAuthTokenClientSecret")
      do {
        try await requireCoordinator().authenticateUserWithToken(token)
        return .object([:])
      } catch let error as CryptoOnrampCoordinator.Error {
        if case .seamlessSignInTokenInvalid(let reason) = error {
          return OnrampErrorMapper.error(code: .failed, message: reason ?? error.localizedDescription)
        }
        throw error
      }
    }

    private func authorize(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      let intentID = try arguments.requiredString("linkAuthIntentId")
      let result = try await requireCoordinator().authorize(linkAuthIntentId: intentID, from: try presenter())
      switch result {
      case .consented(let customerID):
        return .fields(["status": "Consented", "customerId": .string(customerID)])
      case .denied:
        return .fields(["status": "Denied"])
      case .canceled:
        return OnrampErrorMapper.error(code: .canceled, message: "Authorization was cancelled")
      }
    }

    private func registerWalletAddress(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      let address = try arguments.requiredString("address")
      let networkName = try arguments.requiredString("network")
      guard let network = CryptoNetwork(rawValue: networkName) else {
        return OnrampErrorMapper.error(code: .unknown, message: "Invalid network: \(networkName)")
      }
      try await requireCoordinator().registerWalletAddress(walletAddress: address, network: network)
      return .object([:])
    }

    // MARK: - KYC

    private func presentKycInfoVerification(_ arguments: FunkitJSON) async throws -> FunkitJSON {
      let updatedAddress = arguments["updatedAddress"].flatMap { $0 == .null ? nil : Self.kycAddress($0) }
      let result = try await requireCoordinator().verifyKYCInfo(updatedAddress: updatedAddress, from: try presenter())
      switch result {
      case .confirmed:
        return .fields(["status": "Confirmed"])
      case .updateAddress:
        return .fields(["status": "UpdateAddress"])
      case .canceled:
        return OnrampErrorMapper.error(code: .canceled, message: "KYC info verification was cancelled")
      }
    }

    private func verifyIdentity() async throws -> FunkitJSON {
      let result = try await requireCoordinator().verifyIdentity(from: try presenter())
      switch result {
      case .completed:
        return .object([:])
      case .canceled:
        return OnrampErrorMapper.error(code: .canceled, message: "Identity verification was cancelled")
      }
    }

    // MARK: - Payment

    private func collectPaymentMethod(
      _ arguments: FunkitJSON,
      configuration: FunkitStripeCallContext
    ) async throws -> FunkitJSON {
      let type: PaymentMethodType
      switch arguments["paymentMethod"]?.stringValue {
      case "Card":
        type = .card
      case "BankAccount":
        type = .bankAccount
      case "CardAndBankAccount":
        type = .cardAndBankAccount
      case "PlatformPay":
        guard let applePay = arguments["platformPayParams"]?["applePay"] else {
          return OnrampErrorMapper.error(code: .failed, message: "You must provide the `applePay` parameter.")
        }
        type = .applePay(
          paymentRequest: try ApplePayRequest.make(applePay, merchantIdentifier: configuration.merchantIdentifier)
        )
      case let other:
        return OnrampErrorMapper.error(code: .failed, message: "Unsupported payment method: \(other ?? "none")")
      }

      let result = try await requireCoordinator().collectPaymentMethod(type: type, from: try presenter())
      switch result {
      case .canceled:
        return OnrampErrorMapper.error(code: .canceled, message: "Payment collection was cancelled")
      case .completed(let displayData, let kycInfo):
        return .fields([
          "displayData": Self.displayDataJSON(displayData),
          "kycInfo": kycInfo.map(Self.kycInfoJSON),
        ])
      @unknown default:
        return OnrampErrorMapper.error(code: .failed, message: "Received an unexpected payment collection result")
      }
    }

    /// Stripe asks for the onramp session's client secret mid-checkout; connect-rn
    /// fetches it from Fun's backend. A missing answer fails the checkout, as in
    /// stripe-react-native.
    private func performCheckout(_ arguments: FunkitJSON, reverse: FunkitReverseCaller) async throws -> FunkitJSON {
      let sessionID = try arguments.requiredString("onrampSessionId")
      let context = AuthenticationContext(adapter: self)
      authenticationContext = context
      defer { authenticationContext = nil }
      let result = try await requireCoordinator().performCheckout(
        onrampSessionId: sessionID,
        authenticationContext: context
      ) { onrampSessionID in
        let answer = await reverse("checkoutClientSecret", .fields(["onrampSessionId": .string(onrampSessionID)]))
        guard let clientSecret = answer?.stringValue else {
          throw AdapterError.missingClientSecret
        }
        return clientSecret
      }
      switch result {
      case .completed:
        return .object([:])
      case .canceled:
        return OnrampErrorMapper.error(code: .canceled, message: "Checkout was cancelled")
      }
    }

    // MARK: - Presentation

    /// The top of the presentation stack over Funkit's container, which sits in
    /// the window the host passed to `deposit(_:in:)`. With no flow open, the
    /// foreground window's.
    func presenter() throws -> UIViewController {
      guard var top = callContext?.presentingViewController ?? Self.foregroundRoot() else {
        throw AdapterError.noPresenter
      }
      while let presented = top.presentedViewController, !presented.isBeingDismissed {
        top = presented
      }
      return top
    }

    private static func foregroundRoot() -> UIViewController? {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
      let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
      return window?.rootViewController
    }

    private final class AuthenticationContext: NSObject, STPAuthenticationContext {
      private weak var adapter: FunkitStripeOnramp?

      init(adapter: FunkitStripeOnramp) {
        self.adapter = adapter
      }

      @MainActor func authenticationPresentingViewController() -> UIViewController {
        (try? adapter?.presenter()) ?? UIViewController()
      }
    }
  }

  /// Keeps the adapter's version independent of the wrapper's internals.
  enum FunkitStripeVersion {
    static let current = "0.1.0"
  }

  enum AdapterError: Error {
    case notInitialised
    case notConfigured
    case noPresenter
    case missingArgument(String)
    case missingClientSecret
    case applePay(String)

    var result: FunkitJSON {
      switch self {
      case .notInitialised:
        return OnrampErrorMapper.error(
          code: .failed,
          message: "Stripe has not been initialized. Initialize Stripe in your app with the StripeProvider component or the initStripe method."
        )
      case .notConfigured:
        return OnrampErrorMapper.error(code: .failed, message: "Onramp is not configured.")
      case .noPresenter:
        return OnrampErrorMapper.error(code: .failed, message: "No window to present Stripe from.")
      case .missingArgument(let name):
        return OnrampErrorMapper.error(code: .failed, message: "Missing argument \(name).")
      case .missingClientSecret:
        return OnrampErrorMapper.error(code: .failed, message: "Failed to provide checkout client secret")
      case .applePay(let message):
        return OnrampErrorMapper.error(code: .failed, message: message)
      }
    }
  }

  extension FunkitJSON {
    func requiredString(_ key: String) throws -> String {
      guard let value = self[key]?.stringValue else { throw AdapterError.missingArgument(key) }
      return value
    }
  }
#endif
