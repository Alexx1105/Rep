//
//  SupabaseServer.swift
//  Rep
//
//  Created by alex haidar on 3/28/26.

/* Supabase db table write operations
 should all run through here */
import Foundation
import Supabase
import CryptoKit
import StoreKit


let supabaseDBClient: SupabaseClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")


@MainActor
public final class SupabaseClientManager: ObservableObject {
    public static let shared = SupabaseClientManager()
    
    
    public func supabaseNotionUpsert(token: String, pageID: String, row: String, pageTitle: String, content_hash: String) async {
        do {
            guard !token.isEmpty && !row.isEmpty && !pageID.isEmpty else { throw SupabaseError.nilDataError }
            
            let schema: PushToSupabaseNotion = PushToSupabaseNotion(token: token, page_data: row, page_id: pageID, page_title: pageTitle, content_hash: content_hash)
            let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, content_hash, page_data, page_title").execute()
            
            print("[notion page] page data successfully inserted ✅:", send)
        } catch {
            print("supabse insertion errror ❗️", SupabaseError.upsertError, error)
        }
    }
    
    
    public func supabaseOpenaiChatUpsert(openaiID: String, title: String, content: String, token: String) async {
        let hash: Data = Data(content.utf8)
        let hashed = SHA256.hash(data: hash).map { String(format: "%02x", $0) }.joined()
        
        do {
            guard !openaiID.isEmpty && !title.isEmpty && !content.isEmpty && !token.isEmpty else { throw SupabaseError.nilDataError }
            
            let schema: PushToSupabaseOpenAi = PushToSupabaseOpenAi(token: token, openaiID: openaiID, title: title, content: content, contentHash: hashed)
            let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, page_data, page_title").execute()
            
            print("==========\npage data successfully inserted ✅:", send)
        } catch {
            print("[openai chat] supabse insertion errror ❗️", SupabaseError.upsertError, error)
        }
    }
    
    
    public func supabaseAudioTranscriptionNotesUpsert(userId: String, title: String, fullNotes: String, token: String) async throws {    ///shared by mobile & desktop
        let hash: Data = Data(fullNotes.utf8)
        let hashed = SHA256.hash(data: hash).map { String(format: "%02x", $0) }.joined()
        
        guard !userId.isEmpty && !title.isEmpty && !fullNotes.isEmpty else { throw ErrorDesc.nilValue }
        
        let schema: PushToSupabaseRepDesktopNotes = PushToSupabaseRepDesktopNotes(token: token, userId: userId, title: title, fullNotes: fullNotes, contentHash: hashed)
        let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, page_data, page_title").execute()
        print("==========\npage data successfully inserted ✅:", send)
    }
    
    
    func upsertRepMobileNotes(fullNotes: String, userId: String, title: String) async throws {
        guard !fullNotes.isEmpty && !userId.isEmpty && !title.isEmpty else { throw ErrorDesc.nilValue }
        
        let token: String = await PushTokenManager.generatePushToken()
        
        for transcribedNote in fullNotes.split(separator: "\n") {
            let desktopNote = String(transcribedNote).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !desktopNote.isEmpty else { continue }
            
            try await supabaseAudioTranscriptionNotesUpsert(userId: userId, title: title, fullNotes: desktopNote, token: token)
            print("rep desktop helper transcription notes successfully upserted into supabase ✅")
        }
    }
    
    
    func upsertRepDesktopNotes(fullNotes: String, userId: String, title: String) async throws {
        guard !fullNotes.isEmpty && !userId.isEmpty && !title.isEmpty else { throw ErrorDesc.nilValue }
        
        let token: String = await PushTokenManager.generatePushToken()
        
        for transcribedNote in fullNotes.split(separator: "\n") {
            let desktopNote = String(transcribedNote).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !desktopNote.isEmpty else { continue }
            
            try await supabaseAudioTranscriptionNotesUpsert(userId: userId, title: title, fullNotes: desktopNote, token: token)
            print("rep desktop helper transcription notes successfully upserted into supabase ✅")
        }
    }
    
    
    func getBillingProducts() async throws -> [Product] {
        let configuredProducts: [BillingProductRow] = try await supabaseDBClient.from("billing_products").select("storekit_product_id").eq("is_active", value: true).execute().value
        
        let productIDs = Set(configuredProducts.map(\.storekit_product_id))
        guard !productIDs.isEmpty else { throw PaymentStoreError.noProductsAvailable }
    
        let fetchedProducts = try await Product.products(for: productIDs)
        let products = fetchedProducts.sorted { lhs, rhs in
            if lhs.price == rhs.price {
                return lhs.id < rhs.id
            }
            return lhs.price < rhs.price
        }
        
        guard !products.isEmpty else { throw PaymentStoreError.noProductsAvailable }
        return products
    }
    
    
    func loadAppAccountToken() async throws -> UUID {
        let session = try await supabaseDBClient.auth.session
        guard !session.isExpired else { throw ErrorDesc.authTokenError }
        
        let rows: [BillingCustomerRow] = try await supabaseDBClient.from("billing_customers").select("app_account_token").eq("user_id", value: session.user.id.uuidString).limit(1).execute().value
        guard let customer = rows.first else { throw PaymentStoreError.billingCustomerNotFound }
        
        let appAccountToken: UUID = customer.app_account_token
        return appAccountToken
    }
    
    
    func fetchBillingPlanTiers(plan: BillingPlan) async throws -> BillingPlanRow {
        return try await supabaseDBClient.from("billing_plans").select().eq("plan_key", value: plan.rawValue).eq("is_active", value: true).single().execute().value
    }
    
    
    func fetchBillingFeatureId(feature: BillingFeature) async throws -> UUID {
        let feature: BillingFeautureId = try await supabaseDBClient.from("billing_features").select("id").eq("feature_key", value: feature.rawValue).single().execute().value
        return feature.id
    }
    
    
    func fetchBillingBucketForCrediting(featureId: UUID) async throws -> BillingBucketCredits {
        let session = try await supabaseDBClient.auth.session
        
        return try await supabaseDBClient.from("usage_buckets").select("""
                                                                id, user_id, feature_id, bucket_type, allowance,
                                                                consumed:consumed_units, reserved:reserved_units, period_start, period_end
                                                                """).eq("user_id", value: session.user.id.uuidString).eq("feature_id", value: featureId.uuidString)
                                                                    .order("period_start", ascending: false).limit(1).single().execute().value
    }
}
