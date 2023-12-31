//
//  SKFileParser.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/4.
//

import SKFoundation
import LarkCache

public final class SKFileParser {
    /// 遇到的错误
    enum PError: Error {
        /// 不是文件（可能是文件夹）
        case notFileError
        /// 获取大小失败
        case getFileSizeError
        /// 获取大小失败
        case createSandboxPathError
    }

    /// 获取状态
    public enum Status {
        /// 刚创建
        case empty
        /// 超出了大小
        case reachMaxSize
        /// 获取到信息，无异常
        case fillBaseInfo
    }

    public final class Info: CustomStringConvertible {
        /// 文件名
        public var name: String = ""
        /// 文件大小
        public var filesize: UInt64 = 0
        /// uuid
        public var uuid: String = UUID().uuidString
        /// 导出到沙盒路径
        public var exportPath: SKFilePath?
        /// docsource路径（传给前端的）
        public var docSourcePath: String = ""
        /// 信息类型
        public var status: Status = .empty
        ///视频宽度
        public var width: CGFloat = 0.0
        ///视频高度
        public var height: CGFloat = 0.0
        ///文件类型
        public var fileType = "file"
        
        public init() { }

        public var description: String {
            return "SKVideoParser.info: name=\(name), uuid=\(uuid), filesize=\(filesize), exportPath=\(exportPath), status=\(status) "
        }
    }

    public var fileMaxSize: UInt64 {
        return 10 * 1024 * 1024 * 1024
    }

    public init() {
    }
}
