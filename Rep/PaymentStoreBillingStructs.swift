//
//  PaymentStoreBillingStructs.swift
//  Rep
//
//  Created by alex haidar on 8/15/26.
//
/* Billing struct definitions for the payment store here */
import Foundation



enum BillingPlan: String, Codable, Sendable {
    case free
    case pro
    case aiMax = "ai_max"
    
    
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = BillingPlan(rawValue: value) ?? .free
    }
}


enum BillingSubscriptionStatus: String, Codable, Sendable {
    case active
    case grace_period = "grace_period"
    case billing_retry = "billing_retry"
    case expired
    case revoked
    case refunded
    case pending
    
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = BillingSubscriptionStatus(rawValue: value) ?? .pending
    }
}


struct EntitlementSnapshot: Codable, Sendable {
    let plan: BillingPlan
    let status: BillingSubscriptionStatus
    let productId: String?
    let effectiveFrom: String
    let effectiveUntil: String?
    let willAutoRenew: Bool?
    let version: Int
}


struct UsageSnapshot: Codable, Sendable {
    let feature: String
    let allowance: Decimal
    let consumed: Decimal
    let reserved: Decimal
    let remaining: Decimal
    let periodStart: String?
    let periodEnd: String?
}


struct PurchaseSyncResponse: Codable, Sendable {
    let entitlement: EntitlementSnapshot
    let usage: UsageSnapshot
}


enum PaymentState: Equatable, Sendable {
    case idle
    case loading
    case ready
    case purchasing(productID: String)
    case pending
    case cancelled
    case failed(message: String)
}


struct ResolvedEntitlementRow: Decodable, Sendable {
    let effective_plan_key: BillingPlan
    let subscription_status: BillingSubscriptionStatus
    let effective_at: String
    let expires_at: String?
    let auto_renew_enabled: Bool?
    let entitlement_version: Int
}


struct BillingCustomerRow: Decodable, Sendable {
    let app_account_token: UUID
}


struct BillingProductRow: Decodable, Sendable {
    let storekit_product_id: String
}


struct ResolveEntitlementParameters: Encodable, Sendable {
    let p_user_id: UUID
}


struct PurchaseSyncRequest: Encodable, Sendable {
    let signedTransaction: String
}

struct ErrorEnvelope: Decodable {
    struct ErrorBody: Decodable {
        let errorCode: String
        let message: String
    }
    
    let error: ErrorBody
}


struct BillingPlanRow: Identifiable, Codable {
    let id: UUID
    let plan_key: BillingPlan
    let display_name: String
    let tier_order: Int
    let is_active: Bool
}


struct BillingBucketCredits: Identifiable, Codable {
    let id: UUID
    let user_id: UUID
    let feature_id: UUID
    let bucket_type: CreditBucketType
    let allowance: Decimal
    let consumed: Decimal
    let reserved: Decimal
    
    let period_start: Date
    let period_end: Date?
}

enum BillingFeature: String, Codable {
    case ai_credits
    case notion_auto_sync
}

enum CreditBucketType: String, Codable {
    case lifetime
    case billing_period
}

struct BillingSseResponse: Decodable {
    let rep_billing: BillingResponseBody
}

struct BillingResponseBody: Decodable {
    let bucket: BillingBucketCredits
}

struct BillingFeautureId: Identifiable, Codable {
    let id: UUID
}

struct AudioStartResponse: Decodable {      ///unified wrapper for both audio billing and audio session
    let session: AudioSession.SessionData
    let bucket: BillingBucketCredits
    let idempotency_key: UUID
    let authorized_duration_seconds: Decimal
}


