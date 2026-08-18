//
//  PaymentStoreCreditsManager.swift
//  Rep
//
//  Created by alex haidar on 8/16/26.
//

/* Central manager for the user's current shared AI credit bucket.
 Supabase remains authoritative for reserving and consuming credits. */

import Foundation
import Combine


@MainActor
final class CreditBucketsManager: ObservableObject {
    private init() {}
    
    static let shared = CreditBucketsManager()
    let supabase = SupabaseClientManager.shared
    
    @Published private(set) var current_plan: BillingPlanRow?
    @Published private(set) var buckets: [BillingBucket] = []
    @Published private(set) var current_bucket: BillingBucket?
    
    
    var remaining_credits: Int {
        guard let current_bucket else { return 0 }
        
        return max(current_bucket.allowance - current_bucket.consumed - current_bucket.reserved, 0)
    }
    
    var has_available_credits: Bool {
        self.remaining_credits > 0
    }
    
    
    func canAfford(credits: Int) -> Bool {
        guard credits > 0 else {
            return false
        }
        return self.remaining_credits >= credits
    }
    
    
    func requireCredits(_ credits: Int) throws {
        guard credits > 0 else { throw CreditBucketError.invalidCreditAmount }
        
        guard self.current_bucket != nil else { throw CreditBucketError.noCurrentBucket }
        guard self.canAfford(credits: credits) else { throw CreditBucketError.insufficientCredits(required: credits, remaining: self.remaining_credits)}
    }
    
    
    func isBucketCurrent(bucket: BillingBucket, plan: BillingPlanRow, date: Date = Date()) -> Bool {
        guard bucket.plan_id == plan.id else { return false }
        guard bucket.feature_key == .ai_credits else { return false }
        guard bucket.period_start <= date else { return false }
        
        if let period_end = bucket.period_end {
            return date < period_end
        }
        
        return bucket.bucket_type == .lifetime
    }
    
    
    func refreshBillingCredits(plan: BillingPlan) async throws {
        let billingPlan = try await self.supabase.fetchBillingPlanTiers(plan: plan)
        let billingBuckets = try await self.supabase.fetchBillingBucketForCrediting(planID: billingPlan.id)
        
        guard let currentBucket = billingBuckets.first(where: {
            self.isBucketCurrent(bucket: $0, plan: billingPlan)}) else {
            self.current_plan = billingPlan
            self.buckets = billingBuckets
            self.current_bucket = nil
            throw CreditBucketError.noCurrentBucket
        }
        
        self.current_plan = billingPlan
        self.buckets = billingBuckets
        self.current_bucket = currentBucket
    }
    
    
    func applyUpdatedBucket(_ bucket: BillingBucket) {
        guard bucket.feature_key == .ai_credits else { return }
        
        if let index = self.buckets.firstIndex(where: {
            $0.id == bucket.id
        }) {
            self.buckets[index] = bucket
        } else {
            self.buckets.insert(bucket, at: 0)
        }
        
        if let current_plan, self.isBucketCurrent(bucket: bucket, plan: current_plan) {
            self.current_bucket = bucket
        }
    }
    
    
    func reset() {
        self.current_plan = nil
        self.current_bucket = nil
        self.buckets = []
    }
}

