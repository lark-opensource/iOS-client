//
//  SKVideoParser.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/26.
//

import SKFoundation
import LarkCache

public final class SKVideoParser {
    /// 解析视频遇到的错误
    enum PError: Error {
        /// 获取视频大小失败： 文件不存在，读取失败等
        case getVideoSizeError
        /// 获取视频信息失败
        case loadAVAssetError
        /// 获取视频信息失败，在iCloud中
        case loadAVAssetIsInCloudError
        /// 创建缓存路径失败
        case createSandboxPathError
    }

    /// 视频信息的获取状态
    enum Status {
        /// 刚创建
        case empty
        /// 超出了可发送范围
        case reachMaxSize
        /// 超出了可发送时长
        case reachMaxDuration
        /// 获取到信息，无异常
        case fillBaseInfo
    }

    class Info: CustomStringConvertible {
        /// 文件名
        var name: String = ""
        /// 文件大小
        var filesize: UInt64 = 0
        /// uuid
        var uuid: String = UUID().uuidString
        /// 导出到沙盒路径
        var exportPath: SKFilePath?
        /// docsource路径（传给前端的）
        var docSourcePath: String = ""
        /// 视频时长（s）
        var duration: TimeInterval = 0
        /// 信息类型
        var status: Status = .empty
        /// 视频高度
        var height: CGFloat = 0.0
        /// 视频宽度
        var width: CGFloat = 0.0
        
        public init() { }

        var description: String {
            return "SKVideoParser.info: name=\(name), uuid=\(uuid), filesize=\(filesize), exportPath=\(exportPath), duration=\(duration), status=\(status) "
        }

    }

    var fileMaxSize: UInt64 {
        return 10 * 1024 * 1024 * 1024
    }
}
