//
//  BTEventParamsGenerator.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/8/1.
//  


import SKFoundation
import SKCommon
import SKBrowser

protocol BTEventBaseDataType {
    var baseId: String { get }
    var tableId: String { get }
    var viewId: String { get }
}

/// 前端通过 biz.bitable.updateTableInfo 接口传递给客户端的一些全局信息，目前主要用于埋点
final class BTGlobalTableInfo {
    // MARK: - public

    struct TableData: Codable {
        let baseId: String
        let tableId: String
        let isSyncTable: Bool
    }

    struct ViewData: Codable {
        let baseId: String
        let tableId: String
        let viewId: String
        /// 卡片视图布局类型
        let gridViewLayoutType: BTTableLayoutSettings.ViewType?
    }
    
    static func updateCurrentTableInfo(_ data: TableData) {
        rwlock.wait()
        tables[data.baseId] = data
        rwlock.signal()
    }
    
    static func updateCurrentViewInfo(_ data: ViewData) {
        rwlock.wait()
        views[data.baseId] = data
        rwlock.signal()
    }
    
    static func currentTableInfoForBase(_ baseId: String) -> TableData? {
        rwlock.wait()
        let data = tables[baseId]
        rwlock.signal()
        return data
    }
    
    static func currentViewInfoForBase(_ baseId: String) -> ViewData? {
        rwlock.wait()
        let data = views[baseId]
        rwlock.signal()
        return data
    }
    
    // MARK: - private
    
    // 存放当前 table 的信息
    private static var tables: [String: TableData] = [:]
    
    // 存放当前 view 的信息
    private static var views: [String: ViewData] = [:]
    
    // 读写锁
    private static var rwlock = DispatchSemaphore(value: 1)
}

struct BTEventParamsGenerator {
    
    static func createCommonParams(by hostDocInfo: DocsInfo?, baseData: BTEventBaseDataType) -> [String: String] {
        var commonParams: [String: String] = [:]
        var type = "bitable_app"
        if let hostDocInfo = hostDocInfo {
            commonParams = DocsParametersUtil.createCommonParams(by: hostDocInfo)
            if hostDocInfo.isDoc {
                type = "bitable_doc_block"
            } else if hostDocInfo.isSheet {
                type = "bitable_sheet_block"
            }
        }
        var businessParams = [
            "bitable_type": type,
            "is_full_screen": "true",
            "bitable_id": DocsTracker.encrypt(id: baseData.baseId),
            "table_id": baseData.tableId,
            "view_id": baseData.viewId,
            "view_type": "grid"
        ]
        
        if let table = BTGlobalTableInfo.currentTableInfoForBase(baseData.baseId) {
            businessParams["is_sync_table"] = table.isSyncTable ? "true" : "false"
        }
        commonParams.merge(other: businessParams)
        return commonParams
    }
}
