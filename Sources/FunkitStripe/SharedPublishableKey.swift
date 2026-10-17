#if canImport(StripeCryptoOnramp) && canImport(UIKit)
  import StripeCore

  /// stripe-ios 26.x's Link seamless sign-in ignores the coordinator's client:
  /// `LinkAccountService.lookupLinkAuthToken` calls
  /// `ConsumerSession.lookupLinkAuthToken` without `with: apiClient`, unlike its
  /// sibling lookups, so the request goes out on `STPAPIClient.shared`. Without
  /// the onramp's key there, sign-in fails with "You did not provide an API key"
  /// and payment then fails at `register_wallet`.
  ///
  /// The host owns the shared client. Funkit sets the onramp's key there only
  /// when it is unset or still holds the key Funkit set before, so a
  /// reconfigured onramp key replaces Funkit's own and never the host's. Drop
  /// this once stripe-ios passes its client.
  @MainActor
  enum SharedPublishableKey {
    enum Outcome: Equatable {
      /// The shared client now has the onramp's key: it was unset, or held the
      /// key Funkit set before.
      case adopted
      /// The shared client already has the onramp's key.
      case alreadySet
      /// The host set another key. It stays, and Link sign-in will fail.
      case hostOwned
    }

    /// The key Funkit last put on the shared client: the only one it replaces.
    /// Process-wide, like the shared client.
    private static var adoptedKey: String?

    @discardableResult
    static func adopt(_ key: String, into client: STPAPIClient = .shared) -> Outcome {
      adopt(key, into: client, adoptedKey: &adoptedKey)
    }

    static func adopt(_ key: String, into client: STPAPIClient, adoptedKey: inout String?) -> Outcome {
      let current = client.publishableKey
      if current == key {
        return .alreadySet
      }
      if current == nil || current == "" || current == adoptedKey {
        client.publishableKey = key
        adoptedKey = key
        return .adopted
      }
      return .hostOwned
    }
  }
#endif
