//
//  DataManager.swift
//  DataSource
//
//  Created by weidong fu on 6/1/2018.
//

import Foundation
import SwiftyJSON
import ReSwift
import SKFoundation
import RxSwift
import SKCommon
import SpaceInterface

public enum SpecialError: Int {
    case running = 1024 //请求中
    case notLogged = 1025 //未登录
}

public enum ListDataType {
    case listFile  // 列表模式数据
    case gridFile // 网格模式数据
    case noNet // 表示无网cell，目前用于子文件夹页面，无网状态
    case driveFileUploadStatus // drive文件上传进度cell对应的数据，有需要的列表页展示
    
    public var isFile: Bool {
        switch self {
        case .listFile, .gridFile:
            return true
        default:
            return false
        }
    }
}

public protocol SpaceListData: AnyObject {
    var dataType: ListDataType { get }
    var height: CGFloat { get }
    var file: SpaceEntry? { get }
}

extension DocsLogger {
    public class func debugFileList(tag: DocFolderKey, desc: String) {
        debugWithPrefix("$FileList->", tag: tag.name, desc: desc)
    }
    public class func debugWithPrefix(_ prefix: String, tag: String, desc: String) {
        DocsLogger.info(prefix + "$" + tag + " " + desc)
    }
}
