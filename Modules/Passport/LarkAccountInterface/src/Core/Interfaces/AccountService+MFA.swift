//
//  AccountService+MFA.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/4/17.
//

import Foundation
import UIKit

public enum MFATokenStatus: Int, Codable {
    /// 已经授权过
    case authed = 1
    /// 还未授权
    case unAuthed = 2
}

public enum MFATokenNewStatus: Int, Codable {
    /// 已经授权过
    case valid = 1
    /// 还未授权
    case invalid = 2
}

/// 对外的 MFA 相关能力
public protocol AccountServiceMFA { // user:checked

    // mfa堆栈关闭时的 callback，用于 iPad formsheet dismiss 后不会触发 viewDidAppear回调
    var dismissCallback: (() -> Void)? { get set }

    /// 检查一个 mfa token 是否mfa 授权过
    func checkMFAStatus(token: String,
                        scope: String,
                        unit: String?,
                        onResult: @escaping (MFATokenStatus) -> Void,
                        onError: @escaping (Error) -> Void)

    func startMFA(token: String,
                  scope: String,
                  unit: String?,
                  from: UIViewController,
                  onSuccess: @escaping () -> Void,
                  onError: @escaping (Error) -> Void)
}

public enum NewMFAServiceError: Error {
    case userClosePage
    case noStepData
    case noVCPresent
    case otherError(errorMessage: String)

    public var errorCode: Int {
        switch self {
        case .userClosePage:
            return -1
        case .noStepData:
            return -2
        case .noVCPresent:
            return -3
        case .otherError(_):
            return -4
        }
    }

    public var errorMessage: String {
        switch self {
        case .userClosePage:
            return "Users close the MFA page by themselves."
        case .noStepData:
            return "No step data"
        case .noVCPresent:
            return "No VC present"
        case .otherError(let message):
            return message
        }
    }
}

/// 对外的新版 MFA 相关能力
public protocol AccountServiceNewMFA { // user:current

    // mfa堆栈关闭时的 callback，用于 iPad formsheet dismiss 后不会触发 viewDidAppear回调
    var dismissCallback: (() -> Void)? { get set }

    /// 检查一个 mfa token 是否mfa 授权过
    func checkNewMFAStatus(token: String,
                           scope: String,
                           onResult: @escaping (MFATokenNewStatus) -> Void,
                           onError: @escaping (NewMFAServiceError) -> Void)
    /// 开始一方MFA验证
    func startNewMFA(scope: String,
                     from: UIViewController,
                     onSuccess: @escaping (String) -> Void,
                     onError: @escaping (NewMFAServiceError) -> Void)

    /// 开始三方MFA验证
    func startThirdPartyNewMFA(key: String,
                               from: UIViewController,
                               onSuccess: @escaping (String) -> Void,
                               onError: @escaping (NewMFAServiceError) -> Void)

}
