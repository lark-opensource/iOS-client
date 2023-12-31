////
////  Models.swift
////
////  Created by JackZhao on 2021/12/31.
////  Copyright © 2021 JACK. All rights reserved.
////
//

import Foundation

public enum FlowChartError: Error {
    case normalError(_ description: String, extraInfo: [String: String] = [:])              // 默认错误
    case dataError(_ description: String, extraInfo: [String: String] = [:])                // 资源错误
    case downloadFailed(_ description: String, extraInfo: [String: String] = [:])           // 下载 错误
    case bussinessError(_ description: String, extraInfo: [String: String] = [:])           // 业务逻辑错误
    case unknownError(_ description: String, extraInfo: [String: String] = [:])             // 未知或极端错误(比如self被异常释放等)

    public func getDescription() -> String {
        switch self {
        case .normalError(let toast, _):
            return toast
        case .dataError(let toast, _):
            return toast
        case .downloadFailed(let toast, _):
            return toast
        case .bussinessError(let toast, _):
            return toast
        case .unknownError(let toast, _):
            return toast
        }
    }

    public func getExtraInfo() -> [String: String] {
        switch self {
        case .normalError(_, let info):
            return info
        case .dataError(_, let info):
            return info
        case .downloadFailed(_, let info):
            return info
        case .bussinessError(_, let info):
            return info
        case .unknownError(_, let info):
            return info
        }
    }
}

// swiftlint:disable all
public enum FlowChartValue<I> {
    case success(I)
    case error(FlowChartError)
}

public enum FlowChartResponse {
    case success(_ identify: String, extraInfo: [String: String] = [:])
    case failure(_ identify: String, error: FlowChartError)
}

func fcAbstractMethod(file: StaticString = #fileID, line: UInt = #line) -> Swift.Never {
    fcFatalError("Abstract method", file: file, line: line)
}

func fcFatalError(_ lastMessage: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) -> Swift.Never {
    fatalError(lastMessage(), file: file, line: line)
}
// swiftlint:enable all
