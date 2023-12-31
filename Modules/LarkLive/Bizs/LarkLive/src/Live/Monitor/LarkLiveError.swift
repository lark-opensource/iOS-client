//
//  LarkLiveError.swift
//  LarkLive
//
//  Created by yangyao on 2021/9/17.
//

import Foundation
import MinutesFoundation

struct LarkLiveError {
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
    var larkLive: LarkLiveError {
        return LarkLiveError(originError: self)
    }
}

