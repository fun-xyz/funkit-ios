// Mappers ported from stripe-react-native 0.76.0 (ios/Mappers.swift,
// ios/OnrampErrors.swift, ios/Errors.swift, ios/ApplePayUtils.swift; MIT,
// © Stripe, Inc.). Result shapes match its JavaScript types exactly, since
// connect-rn reads them unchanged.

#if canImport(StripeCryptoOnramp) && canImport(UIKit)
  import Foundation
  import Funkit
  import PassKit
  import UIKit
  import StripeCore
  @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
  @_spi(CryptoOnrampAlpha) import StripePaymentSheet

  enum OnrampErrorMapper {
    enum Code: String {
      case failed = "Failed"
      case canceled = "Canceled"
      case unknown = "Unknown"
    }

    /// `{ error: { code, message, localizedMessage, … } }`, as stripe-react-native resolves.
    static func error(code: Code, message: String?) -> FunkitJSON {
      envelope([
        "code": .string(code.rawValue),
        "message": FunkitJSON(message),
        "localizedMessage": FunkitJSON(message),
        "declineCode": .null,
        "stripeErrorCode": .null,
        "type": .null,
      ])
    }

    static func failed(_ error: Error) -> FunkitJSON {
      if let apiError = error as? StripeCryptoOnrampAPIError {
        var fields = common(apiError, onrampErrorType: onrampErrorType(apiError))
        fields["type"] = FunkitJSON(apiError.type)
        fields["reason"] = FunkitJSON(apiError.reason)
        fields["requestId"] = FunkitJSON(apiError.requestID)
        fields["apiErrorCode"] = .string(apiError.code)
        fields["apiErrorType"] = FunkitJSON(apiError.type)
        fields["apiErrorMessage"] = FunkitJSON(apiError.apiMessage)
        fields["apiUserMessage"] = FunkitJSON(apiError.apiUserMessage)
        return envelope(fields)
      }
      if let onrampError = error as? StripeCryptoOnrampError {
        let type = onrampError.code == "app_attestation_unavailable" ? "AppAttestationUnavailableError" : nil
        return envelope(common(onrampError, onrampErrorType: type))
      }
      let root = rootError(error as NSError)
      return envelope([
        "code": .string(Code.failed.rawValue),
        "message": .string(root.localizedDescription),
        "localizedMessage": .string(root.localizedDescription),
        "declineCode": .null,
        "stripeErrorCode": .null,
        "type": .null,
      ])
    }

    private static func common(_ error: StripeCryptoOnrampError, onrampErrorType: String?) -> [String: FunkitJSON] {
      [
        "code": .string(Code.failed.rawValue),
        "message": .string(error.userMessage),
        "localizedMessage": .string(error.localizedDescription),
        "declineCode": .null,
        "stripeErrorCode": .string(error.code),
        "type": .null,
        "developerMessage": .string(error.developerMessage),
        "userMessage": .string(error.userMessage),
        "docUrl": FunkitJSON(error.docURL?.absoluteString),
        "onrampErrorType": FunkitJSON(onrampErrorType),
      ]
    }

    private static func onrampErrorType(_ error: StripeCryptoOnrampAPIError) -> String {
      switch error.code {
      case "link_failed_to_attest_request": return "AppAttestationError"
      case "crypto_onramp_invalid_wallet_ownership_signature": return "InvalidWalletOwnershipSignatureError"
      case "crypto_onramp_wallet_ownership_challenge_expired": return "WalletOwnershipChallengeExpiredError"
      case "crypto_onramp_invalid_wallet_ownership_challenge": return "InvalidWalletOwnershipChallengeError"
      case "crypto_onramp_wallet_not_found": return "WalletNotFoundError"
      case "crypto_onramp_unsupported_network": return "UnsupportedNetworkError"
      default: return "UncategorizedApiError"
      }
    }

    private static func envelope(_ fields: [String: FunkitJSON]) -> FunkitJSON {
      .object(["error": .object(fields)])
    }

    private static func rootError(_ error: NSError) -> NSError {
      guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return error }
      return rootError(underlying)
    }
  }

  enum KycInfoError: Error {
    case invalidField(String)

    var result: FunkitJSON {
      switch self {
      case .invalidField(let field):
        return OnrampErrorMapper.error(code: .unknown, message: "Invalid format for field: \(field)")
      }
    }
  }

  extension FunkitStripeOnramp {
    static func kycInfo(_ json: FunkitJSON?) throws -> KycInfo {
      guard let json, json.objectValue != nil else {
        throw AdapterError.missingArgument("info")
      }
      return KycInfo(
        firstName: normalized(json["firstName"]),
        lastName: normalized(json["lastName"]),
        idNumber: normalized(json["idNumber"]),
        address: try json["address"].map { value throws -> StripeCryptoOnramp.Address in
          guard value.objectValue != nil else { throw KycInfoError.invalidField("address") }
          return kycAddress(value)
        },
        dateOfBirth: try json["dateOfBirth"].map(dateOfBirth),
        birthCountry: normalized(json["birthCountry"]),
        birthCity: normalized(json["birthCity"]),
        nationalities: try json["nationalities"].map { value throws -> [String] in
          guard let array = value.arrayValue else { throw KycInfoError.invalidField("nationalities") }
          return array.compactMap(normalized)
        }
      )
    }

    static func kycAddress(_ json: FunkitJSON) -> StripeCryptoOnramp.Address {
      StripeCryptoOnramp.Address(
        city: normalized(json["city"]),
        country: normalized(json["country"]),
        line1: normalized(json["line1"]),
        line2: normalized(json["line2"]),
        postalCode: normalized(json["postalCode"]),
        state: normalized(json["state"])
      )
    }

    private static func dateOfBirth(_ json: FunkitJSON) throws -> KycInfo.DateOfBirth {
      // Whole numbers in range: `Int(_: Double)` traps on `1e100`.
      func part(_ key: String, _ range: ClosedRange<Int>) throws -> Int {
        guard let value = json[key]?.doubleValue, let whole = Int(exactly: value), range.contains(whole) else {
          throw KycInfoError.invalidField("dateOfBirth")
        }
        return whole
      }
      return KycInfo.DateOfBirth(day: try part("day", 1...31), month: try part("month", 1...12), year: try part("year", 1900...9999))
    }

    static func kycInfoJSON(_ info: KycInfo) -> FunkitJSON {
      .fields([
        "firstName": FunkitJSON(info.firstName),
        "lastName": FunkitJSON(info.lastName),
        "idNumber": FunkitJSON(info.idNumber),
        "address": info.address.map { address in
          .fields([
            "city": FunkitJSON(address.city),
            "country": FunkitJSON(address.country),
            "line1": FunkitJSON(address.line1),
            "line2": FunkitJSON(address.line2),
            "postalCode": FunkitJSON(address.postalCode),
            "state": FunkitJSON(address.state),
          ])
        },
        "dateOfBirth": info.dateOfBirth.map {
          .fields([
            "day": .number(Double($0.day)), "month": .number(Double($0.month)), "year": .number(Double($0.year)),
          ])
        },
        "birthCountry": FunkitJSON(info.birthCountry),
        "birthCity": FunkitJSON(info.birthCity),
        "nationalities": info.nationalities.map { .array($0.map(FunkitJSON.string)) },
      ])
    }

    static func displayDataJSON(_ data: PaymentMethodDisplayData) -> FunkitJSON {
      let type: String
      switch data.paymentMethodType {
      case .card: type = "Card"
      case .bankAccount: type = "BankAccount"
      case .applePay: type = "ApplePay"
      }
      let png = data.icon.pngData()?.base64EncodedString() ?? ""
      return .fields([
        "icon": .string("data:image/png;base64," + png),
        "label": .string(data.label),
        "type": .string(type),
        "sublabel": FunkitJSON(data.sublabel),
      ])
    }

    /// connect-rn sends only `style`; the colour overrides are ported for parity.
    static func linkAppearance(_ json: FunkitJSON?) -> LinkAppearance {
      func color(_ scheme: String, _ key: String) -> UIColor? {
        json?[scheme]?[key]?.stringValue.flatMap(UIColor.init(funkitHex:))
      }
      func dynamic(_ key: String) -> UIColor? {
        let dark = color("darkColors", key)
        let light = color("lightColors", key)
        guard let dark, let light else { return dark ?? light }
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
      }
      let primary = dynamic("primary")
      let selectedBorder = dynamic("borderSelected")
      let contentOnPrimary = dynamic("contentOnPrimary")
      let colors: LinkAppearance.Colors? =
        primary == nil && selectedBorder == nil && contentOnPrimary == nil
        ? nil
        : LinkAppearance.Colors(primary: primary, contentOnPrimary: contentOnPrimary, selectedBorder: selectedBorder)

      let button = json?["primaryButton"]
      let primaryButton = button.map {
        LinkAppearance.PrimaryButtonConfiguration(
          cornerRadius: $0["cornerRadius"]?.doubleValue.map { CGFloat($0) },
          height: $0["height"]?.doubleValue.map { CGFloat($0) }
        )
      }
      return LinkAppearance(
        colors: colors,
        primaryButton: primaryButton,
        style: userInterfaceStyle(json?["style"]?.stringValue),
        reduceLinkBranding: true
      )
    }

    private static func userInterfaceStyle(_ style: String?) -> PaymentSheet.UserInterfaceStyle {
      switch style {
      case "ALWAYS_LIGHT": return .alwaysLight
      case "ALWAYS_DARK": return .alwaysDark
      default: return .automatic
      }
    }

    private static func normalized(_ value: FunkitJSON?) -> String? {
      guard let string = value?.stringValue else { return nil }
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
  }

  /// The subset of stripe-react-native's Apple Pay request connect-rn sends.
  /// Unlike `ApplePayUtils`, it never sets `StripeAPI.additionalEnabledApplePayNetworks`,
  /// which is process-wide and the host's.
  enum ApplePayRequest {
    static func make(_ json: FunkitJSON, merchantIdentifier: String?) throws -> PKPaymentRequest {
      guard let merchantIdentifier else {
        throw AdapterError.applePay("You must provide merchantIdentifier")
      }
      guard let items = json["cartItems"]?.arrayValue, !items.isEmpty else {
        throw AdapterError.applePay("`cartItems` cannot be empty.")
      }
      guard let country = json["merchantCountryCode"]?.stringValue else {
        throw AdapterError.applePay("You must provide the country")
      }
      guard let currency = json["currencyCode"]?.stringValue else {
        throw AdapterError.applePay("You must provide the payment currency")
      }
      let request = StripeAPI.paymentRequest(
        withMerchantIdentifier: merchantIdentifier,
        country: country,
        currency: currency
      )
      request.paymentSummaryItems = try items.map(summaryItem)
      let billingFields = json["requiredBillingContactFields"]?.arrayValue?.compactMap(\.stringValue) ?? []
      request.requiredBillingContactFields = Set(billingFields.compactMap(contactField))
      return request
    }

    private static func summaryItem(_ item: FunkitJSON) throws -> PKPaymentSummaryItem {
      guard let label = item["label"]?.stringValue, let amount = item["amount"]?.stringValue else {
        throw AdapterError.applePay("Each cart item needs a label and an amount.")
      }
      let decimal = NSDecimalNumber(string: amount, locale: Locale(identifier: "en_US_POSIX"))
      guard decimal != .notANumber else {
        throw AdapterError.applePay("Invalid amount \(amount).")
      }
      let type: PKPaymentSummaryItemType = item["paymentType"]?.stringValue == "Pending" ? .pending : .final
      return PKPaymentSummaryItem(label: label, amount: decimal, type: type)
    }

    private static func contactField(_ name: String) -> PKContactField? {
      switch name {
      case "emailAddress": return .emailAddress
      case "name": return .name
      case "phoneNumber": return .phoneNumber
      case "phoneticName": return .phoneticName
      case "postalAddress": return .postalAddress
      default: return nil
      }
    }
  }

  extension UIColor {
    /// `#RRGGBB` or `#RRGGBBAA`.
    convenience init?(funkitHex hex: String) {
      let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
      guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else { return nil }
      let hasAlpha = digits.count == 8
      let red = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
      let green = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
      let blue = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
      let alpha = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
      self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
  }
#endif
