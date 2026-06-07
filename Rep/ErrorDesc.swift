//
//  ErrorDesc.swift
//  Rep
//
//  Created by alex haidar on 4/1/26.
//

import Foundation

enum ErrorDesc: LocalizedError {        //TODO: log all local errors here
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
}

enum ErrorDefinition: Error {
    case emptyContent
}

public enum SupabaseError: LocalizedError {
    case upsertError
    case nilDataError
}
