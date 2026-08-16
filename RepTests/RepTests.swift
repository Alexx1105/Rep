import Foundation
import Testing
@testable import Rep

struct PaymentBillingModelTests {
    @Test
    func billingCustomerDecodesSupabaseColumn() throws {
        let token = UUID(uuidString: "8E6897CB-50EF-4FCE-B385-692105A879E4")!
        let data = Data(#"{"app_account_token":"8E6897CB-50EF-4FCE-B385-692105A879E4"}"#.utf8)

        let customer = try JSONDecoder().decode(BillingCustomerRow.self, from: data)

        #expect(customer.app_account_token == token)
    }

    @Test
    func billingProductDecodesSupabaseColumn() throws {
        let data = Data(#"{"storekit_product_id":"kimchilabs.rep.pro.monthly"}"#.utf8)

        let product = try JSONDecoder().decode(BillingProductRow.self, from: data)

        #expect(product.storekit_product_id == "kimchilabs.rep.pro.monthly")
    }

    @Test
    func purchaseSyncResponseDecodesBackendContract() throws {
        let data = Data(#"""
        {
          "entitlement": {
            "plan": "pro",
            "status": "active",
            "productId": "kimchilabs.rep.pro.monthly",
            "effectiveFrom": "2026-08-14T12:00:00.000Z",
            "effectiveUntil": "2026-09-14T12:00:00.000Z",
            "willAutoRenew": true,
            "version": 2
          },
          "usage": {
            "feature": "ai_credits",
            "allowance": 250,
            "consumed": 40,
            "reserved": 10,
            "remaining": 200,
            "periodStart": "2026-08-14T12:00:00.000Z",
            "periodEnd": "2026-09-14T12:00:00.000Z"
          }
        }
        """#.utf8)

        let response = try JSONDecoder().decode(PurchaseSyncResponse.self, from: data)

        #expect(response.entitlement.plan == .pro)
        #expect(response.entitlement.status == .active)
        #expect(response.entitlement.productId == "kimchilabs.rep.pro.monthly")
        #expect(response.entitlement.willAutoRenew == true)
        #expect(response.usage.feature == "ai_credits")
        #expect(response.usage.allowance == 250)
        #expect(response.usage.consumed == 40)
        #expect(response.usage.reserved == 10)
        #expect(response.usage.remaining == 200)
    }

    @Test
    func unknownBackendEnumValuesFailClosed() throws {
        let plan = try JSONDecoder().decode(BillingPlan.self, from: Data(#""future_plan""#.utf8))
        let status = try JSONDecoder().decode(BillingSubscriptionStatus.self, from: Data(#""future_status""#.utf8))

        #expect(plan == .free)
        #expect(status == .pending)
    }

    @Test
    func resolvedEntitlementDecodesDatabaseColumns() throws {
        let data = Data(#"""
        {
          "effective_plan_key": "ai_max",
          "subscription_status": "grace_period",
          "effective_at": "2026-08-14T12:00:00.000Z",
          "expires_at": "2026-09-14T12:00:00.000Z",
          "auto_renew_enabled": true,
          "entitlement_version": 7
        }
        """#.utf8)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let row = try decoder.decode(ResolvedEntitlementRow.self, from: data)

        #expect(row.effectivePlanKey == .aiMax)
        #expect(row.subscriptionStatus == .grace_period)
        #expect(row.entitlementVersion == 7)
    }

    @Test
    func purchaseSyncRequestUsesBackendKey() throws {
        let data = try JSONEncoder().encode(PurchaseSyncRequest(signedTransaction: "signed-jws"))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(json == ["signedTransaction": "signed-jws"])
    }

    @Test
    func paymentErrorsExposeSafeMessages() {
        #expect(PaymentStoreError.productNotFound("missing.product").errorDescription == "StoreKit product missing.product is unavailable.")
        #expect(PaymentStoreError.backend(code: "server_error", message: "Try again later.").errorDescription == "Try again later.")
    }
}

@MainActor
struct PaymentStoreStateTests {
    @Test
    func startsOnFreeTier() {
        let store = PaymentStore()

        #expect(store.state == .idle)
        #expect(store.currentPlan == .free)
        #expect(store.hasPaidAccess == false)
        #expect(store.products.isEmpty)
        #expect(store.entitlement == nil)
        #expect(store.usage == nil)
    }

    @Test
    func resetForSignOutRestoresSafeDefaults() {
        let store = PaymentStore()

        store.resetForSignOut()

        #expect(store.state == .idle)
        #expect(store.currentPlan == .free)
        #expect(store.hasPaidAccess == false)
        #expect(store.products.isEmpty)
        #expect(store.entitlement == nil)
        #expect(store.usage == nil)
    }
}
