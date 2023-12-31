//
//  OpenNativeTextareaComponentErrno.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/10/8.
//

import Foundation
import LarkWebviewNativeComponent

protocol OpenNativeTextareaComponentErrnoProtocol: OpenNativeComponentErrnoProtocol {}

extension OpenNativeTextareaComponentErrnoProtocol {
    var componentDomain: OpenNativeComponentType { .textarea }
}

enum OpenNativeTextareaErrno: OpenNativeTextareaComponentErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain {
        switch self {
        case .commonInternalError:
            return .common
        case .insertInternalError:
            return .insert
        case .updateInternalError:
            return .update
        case .dispatchAction(let err):
            return err.apiDomain
        case .fireEventInternalError:
            return .fireEvent
        }
    }
    
    var rawValue: Int {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError, .fireEventInternalError:
            return 00
        case .dispatchAction(let err):
            return err.rawValue
        }
    }
    
    var errString: String {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError, .fireEventInternalError:
            return "Internal Error"
        case .dispatchAction(let err):
            return err.errString
        }
    }
    
    case commonInternalError
    case insertInternalError
    case updateInternalError
    case dispatchAction(_ err: OpenNativeTextareaDispatchActionErrno)
    case fireEventInternalError
}

enum OpenNativeTextareaDispatchActionErrno: OpenNativeTextareaComponentErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain { .dispatchAction }
    
    case internalError
    case focusAPIDisable
    case noRefactoringTextArea
    case noTextarea
    
    var rawValue: Int {
        switch self {
        case .internalError:
            return 00
        case .focusAPIDisable:
            return 01
        case .noRefactoringTextArea:
            return 02
        case .noTextarea:
            return 03
        }
    }
    
    var errString: String {
        switch self {
        case .internalError:
            return "Internal Error"
        case .focusAPIDisable:
            return "focusAPIEnable is false"
        case .noRefactoringTextArea:
            return "cannot find refactoringTextArea"
        case .noTextarea:
            return "cannot find textArea"
        }
    }
}
