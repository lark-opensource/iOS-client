//
//  MeesageCardError.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/11.
//

import Foundation

public enum MessageCardError: Error {
    // Lynx 在渲染过程中发生错误
    case lynxRenderFail(Error?)
    // Lynx 在加载过程中发生错误
    case lynxLoadFail(Error?)
    // 内部意外异常
    case internalError(String?)
        
    public var errorCode: Int {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError else { return -1 }
            return error.code
        case .internalError(_):
            return -1;
        }
    }
    
    public var errorType: String {
        switch(self) {
        case .lynxRenderFail(_):
            return "LynxRenderFail"
        case .lynxLoadFail(_):
            return "LynxLoadFail"
        case .internalError(_):
            return "InternalError"
        }
    }
    
    public var domain: String {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError else { return "" }
            return error.domain
        case .internalError(_):
            return "com.openplatform.messagecard"
        }
    }
    
    public var errorMessage: String {
        switch(self) {
        case .lynxRenderFail(let error),
             .lynxLoadFail(let error):
            guard let error = error as? NSError,
                  let messageInfo = error.userInfo["message"] else {
                return "\(self)"
            }
            return "\(messageInfo)"
        case .internalError(let msg):
            return "internal error: \(msg ?? "unknown")"
        }
       
    }
}
