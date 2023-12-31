//
//  Internal.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/1.
//

import Foundation

func castOrThrow<T>(_ resultType: T.Type, _ object: Any, error: Error = SuiteCodableError.cast) throws -> T {
    guard let returnValue = object as? T else {
        throw error
    }

    return returnValue
}
