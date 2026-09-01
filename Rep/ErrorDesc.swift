//
//  ErrorDesc.swift
//  Rep
//
//  Created by alex haidar on 4/1/26.
//

import Foundation


enum ErrorDesc: LocalizedError {
    case authTokenError
    case urlRequestError
    case parsingError
    case encodeError
    case decodeError
    case paginationError
    case callsiteError
    case persistenceError
    case nilValue
    case supabaseQueryError
    case supabaseUpsertError
    case syncError
    case concurrencyError
    case oauthError
    case swiftDataQueryError
    case photoUploadError
    case serverError
    case responseError
    case fileProcessingError
    case ssetextStreamEventError
    case sessionError
    case urlResponseError
    case webSocketError
    case extractError
    case permissionDenied
    case floatError
    case configError
    case liveActivityError
    case taskError
}

enum ErrorDefinition: Error {
    case emptyContent
}

public enum SupabaseError: LocalizedError {
    case upsertError
    case nilDataError
}

enum CreditBucketError: LocalizedError, Sendable {
    case invalidCreditAmount
    case noCurrentBucket
    case insufficientCredits(required: Decimal, remaining: Decimal)

    var errorDescription: String? {
        switch self {
        case .invalidCreditAmount:
            return "Credit cost must be greater than zero."

        case .noCurrentBucket:
            return "Rep could not find a current AI credit bucket."

        case .insufficientCredits(let required, let remaining):
            return "This action requires \(required) credits, but only \(remaining) remain."
        }
    }
}

enum PaymentStoreError: LocalizedError, Sendable {
    case noAuthenticatedUser
    case billingCustomerNotFound
    case invalidAppAccountToken
    case noProductsAvailable
    case entitlementsFailure
    case insufficientTokens
    case productNotFound(String)
    case unverifiedTransaction(String)
    case backend(code: String, message: String)
    
    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "Sign in before loading or purchasing a subscription."
        case .billingCustomerNotFound:
            return "Rep could not find a billing profile for this account."
        case .invalidAppAccountToken:
            return "Rep received an invalid StoreKit account token."
        case .noProductsAvailable:
            return "No active StoreKit products are available."
        case .productNotFound(let productID):
            return "StoreKit product \(productID) is unavailable."
        case .unverifiedTransaction(let message):
            return "StoreKit could not verify this transaction: \(message)"
        case .entitlementsFailure:
            return "failed to return user entitlements"
        case .insufficientTokens:
            return "more credits needed"
        case .backend(_, let message):
            return message
        }
    }
}
