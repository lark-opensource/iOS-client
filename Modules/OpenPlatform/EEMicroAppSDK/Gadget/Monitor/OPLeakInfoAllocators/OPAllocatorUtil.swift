//
//  OPAllocatorUtil.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/23.
//

import Foundation

struct OPAllocatorUtil {
    /// 根据目标对象获取与之关联的uniqueID信息
    static func getUniqueID(with target: NSObject) -> OPAppUniqueID? {
        var targetUniqueID: OPAppUniqueID? = nil

        switch target {
        case let task as BDPTask:
            targetUniqueID = task.uniqueID
        case let runtime as OPMicroAppJSRuntime:
            targetUniqueID = runtime.uniqueID
        case let appPage as BDPAppPage:
            targetUniqueID = appPage.uniqueID
        default:
            break
        }

        return targetUniqueID
    }

    /// 根据目标对象获取与之关联的当前小程序页面路径信息
    static func getCurrentPagePath(with target: NSObject) -> String? {
        var targetPagePath: String? = nil

        switch target {
        case let task as BDPTask:
            targetPagePath = task.currentPage?.path
        case let appPage as BDPAppPage:
            targetPagePath = appPage.bap_path
        default:
            break
        }

        return targetPagePath
    }

    /// 根据目标对象获取与之关联的当前小程序页面query信息
    static func getCurrentPageQuery(with target: NSObject) -> String? {
        var targetPageQuery: String? = nil

        switch target {
        case let task as BDPTask:
            targetPageQuery = task.currentPage?.queryString
        case let appPage as BDPAppPage:
            targetPageQuery = appPage.bap_queryString
        default:
            break
        }

        return targetPageQuery
    }
}
