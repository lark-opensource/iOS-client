//
//  ResourceError.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

extension Result {
    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }

    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }
}

public enum ResourceError: Error, CustomStringConvertible, CustomDebugStringConvertible {

    /// 找不到资源
    case noResource
    /// 找不到索引表
    case noIndexTable
    /// 资源类型错误
    case resourceTypeError
    /// 资源转化发生错误
    case transformFailed
    /// 资源文件加载错误
    case indexFileLoadFailed
    /// 自定义错误
    case custom(Error)
    /// 未知错误
    case unknow

    public var description: String {
        let message: String
        switch self {
        case .noResource:
            message = "don't have resource data"
        case .noIndexTable:
            message = "don't have indexTable"
        case .resourceTypeError:
            message = "resource convert type wrong"
        case .transformFailed:
            message = "resource convert transform failed"
        case .custom(let error):
            message = "custom error \(error)"
        case .indexFileLoadFailed:
            message = "failed to load index file"
        case .unknow:
            message = "unknow error"
        }
        return "resource error: \(message)"
    }

    public var debugDescription: String {
        return self.description
    }
}
