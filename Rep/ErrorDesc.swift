//
//  ErrorDesc.swift
//  Rep
//
//  Created by alex haidar on 4/1/26.
//

import Foundation

enum ErrorDesc: LocalizedError {        ///start using this for logging local errors
    case authTokenError
    case urlRequestError
    case parsingError
    case encodeError
    case decodeError
    case paginationError
    case callsiteError
    case persistenceError
    case nilValue
}
