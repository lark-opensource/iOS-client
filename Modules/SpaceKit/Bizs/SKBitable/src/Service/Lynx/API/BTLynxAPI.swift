//
//  BTLynxAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/8.
//

import Foundation
import LarkLynxKit
import BDXLynxKit
import SKFoundation
import LarkContainer

open class BTLynxAPIBaseResult {
    private let dataString: String?
    public init(dataString: String? = nil) {
        self.dataString = dataString
    }

    open func toJSONDict() -> [AnyHashable: Any] {
        if let dataString = dataString {
            return ["result": "ok", "data": dataString]
        }
        return ["result": "ok"]
    }
}

public protocol BTLynxAPIErrorCodeProtocol: CustomStringConvertible, CustomDebugStringConvertible /* RawRepresentable */ {
    // errCode 取值
    var rawValue: Int { get }

    // errCode 对应的 errMsg
    var errMsg: String { get }
}

extension BTLynxAPIErrorCodeProtocol {
    public var description: String {
        return "errCode: \(rawValue), errMsg: \"\(errMsg)\""
    }

    public var debugDescription: String {
        return description
    }
}


public final class BTLynxAPIError: NSObject, Error {
    public let code: BTLynxAPICommonErrorCode
    private var userInfo: [String: AnyHashable] = [:]
    public init(
        code: BTLynxAPICommonErrorCode
    ) {
        self.code = code
        super.init()
    }
    
    func toJSONDict() -> [AnyHashable: Any] {
        return ["result": "fail", "errMsg": code.errMsg, "errCode": code.rawValue, "userInfo": userInfo]
    }
    
    func insertUserInfo(key: String, value: String) -> BTLynxAPIError{
        self.userInfo[key] = value
        return self
    }
}

public enum BTLynxAPICommonErrorCode: Int, BTLynxAPIErrorCodeProtocol {
    case ok                 = 0
    case unknow             = 100
    case internalError      = 101
    case paramsError        = 102
    case serverError        = 103
    
    public var errMsg: String {
        switch self {
        case .ok:                        return "ok"
        case .unknow:                    return "unknow error"
        case .internalError:             return "internal error"
        case .paramsError:               return "param error"
        case .serverError:               return "server error"
        }
    }
}


public enum BTLynxAPIBaseResponse<Result: BTLynxAPIBaseResult> {
    case failure(error: BTLynxAPIError)
    case success(data: Result?)
}

typealias BTLynxAPICallback<R: BTLynxAPIBaseResult> = (BTLynxAPIBaseResponse<R>) -> ()

protocol BTLynxAPI {
    static var apiName: String { get }
    
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback: BTLynxAPICallback<BTLynxAPIBaseResult>?)
}
