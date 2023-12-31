//
//  MinutesError.swift
//  Minutes
//
//  Created by lvdaqian on 2021/6/25.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

struct MinutesError {
    let originError: Error

    var code: Int {
        switch originError {
        case let error as ResponseError:
            return error.rawValue
        case let error as NSError:
            return error.code
        default:
            return -1
        }
    }

    var message: String? {
        switch originError {
        case let error as ResponseError:
            return error.description
        case let error as NSError:
            return error.localizedDescription
        default:
            return nil
        }
    }
}

extension Error {
    var minutes: MinutesError {
        return MinutesError(originError: self)
    }
}
