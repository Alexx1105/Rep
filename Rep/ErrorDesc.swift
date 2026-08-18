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
    case insufficientCredits(required: Int, remaining: Int)

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
