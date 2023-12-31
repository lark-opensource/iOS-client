//
//  AccountError.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/26.
//

import Foundation

public enum AccountError: Error {
    case setAccessTokenFailed
    case toCChatterNotRegister
    case toCActiveCancel
    case noCurrentAccount
    case suiteLoginError(errorMessage: String)
    case switchUserVerifyCancel
    case toCAndNeedActive
    case notFoundTargetUser
    case autoSwitchFail
    case badNetwork
    case dataParseError
    case switchUserFatalError
    case switchUserNeedVerify(nextStep: String)
    case switchUserCheckNetError
    case switchUserInterrupted
    case switchUserCrossEnvFailed
    case switchUserRustFailed(rawError: Error)
    case switchUserRollbackError(rawError: Error)
    case switchUserDeviceInfoError
    case switchUserGetDeviceDomainError
    case switchUserSetupCookieError
    case switchUserTimeout
}

extension AccountError: LocalizedError {

    public var errorDescription: String? {
            switch self {
            case .setAccessTokenFailed:
                return "set access token failed"
            case .toCChatterNotRegister:
                return "toC chatter not register"
            case .toCActiveCancel:
                return "toC active cancel"
            case .noCurrentAccount:
                return "no current user"
            case .suiteLoginError(let msg):
                return "suiteLogin error: \(msg)"
            case .switchUserVerifyCancel:
                return "switch user cancel"
            case .toCAndNeedActive:
                return "toC need active"
            case .notFoundTargetUser:
                return "switch user failed with target user not found"
            case .autoSwitchFail:
                return "auto switch failed"
            case .badNetwork:
                return "bad network"
            case .dataParseError:
                return "data parse error"
            case .switchUserFatalError:
                return "switch user fatal error"
            case .switchUserNeedVerify(let step):
                return "switch user need verify, next step: \(step)"
            case .switchUserCheckNetError:
                return "switch user no connection"
            case .switchUserInterrupted:
                return "switch user interrupted"
            case .switchUserCrossEnvFailed:
                return "switch user failed with cross env"
            case .switchUserRollbackError(let rawError):
                return "switch user rollback error with raw error: \(rawError)"
            case .switchUserDeviceInfoError:
                return "switch user cannot get target user device info"
            case .switchUserGetDeviceDomainError:
                return "switch user get device domain error"
            case .switchUserRustFailed(let rawError):
                return "switch user rust fail with raw error: \(rawError)"
            case .switchUserSetupCookieError:
                return "switch user failed to setup cookie"
            case .switchUserTimeout:
                return "switch user request timeout"
            }
        }
}
