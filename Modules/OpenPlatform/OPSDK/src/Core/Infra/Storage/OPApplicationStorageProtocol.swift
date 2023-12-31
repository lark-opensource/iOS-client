//
//  OPApplicationStorageProtocol.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/17.
//

import Foundation
import FMDB
import OPFoundation

/// 应用存储目录类型
@objc
public enum OPApplicationStorageDirType: Int {
    /// 小程序jssdk
    case JSSDK

    /// tab小程序jssdk
    case H5JSSDK

    /// 应用目录
    case app

    /// 大组件文件目录
    case components

    /// 形态临时文件目录，初始化创建，用于js sdk、应用压缩包临时存放
    case tmp
}

public extension OPApplicationStorageDirType {
    /// 不同资源文件的目录名称
    public var relativeDirPath: String {
        switch self {
        case .JSSDK:
            return "JSBundle/__dev__"
        case .H5JSSDK:
            return "JSBundle/__dev__/h5jssdk"
        case .app:
            return "app"
        case .components:
            return "JSBundle/__components__"
        case .tmp:
            return "app_tmp"
        }
    }
}

public extension OPAppType {

    /// 不同应用类型对应的总目录名称
    var relativeDirPath: String {
        switch self {
        case .block:
            return "block"
        case .widget:
            return "tcard"
        case .webApp:
            return "twebapp"
        case .gadget:
            return "tma"
        default:
            assertionFailure("wrong type for file path")
            return "tdefault"
        }
    }
}

/// 应用本地存储管理协议，一个type对应一个
@objc public protocol OPApplicationStorageProtocol: NSObjectProtocol {

    /// 存储管理类型
    var type: OPAppType { get }

    /// 存储的db文件
    var dbQueue: FMDatabaseQueue? { get }

    /// 存储最外层的目录路径
    var baseDir: String { get }

    func fileDir(for type: OPApplicationStorageDirType, createFolderIfNotExist: Bool) throws -> String

    /// 重置操作
    func reset()

    /// 初始化操作
    func setup() throws
}
