//
//  DocsVersionPanelViewModel.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/9/8.
//

import Foundation
import SKUIKit
import SKResource
import SKFoundation
import SwiftyJSON
import UniverseDesignToast
import SpaceInterface
import SKInfra

/// 默认每页的大小
private let pageSize = 20

public final class DocsVersionsPanelViewModel: NSObject {
    
    enum ViewModelAction {
        case reloadData         // 请求数据成功，刷新
        case loadError          // 加载失败
        case loadEmpty          // 结果为空
        case stopLoading        // 停止loading
        case noMoreData         // 没有更多数据
        case resetNoMoreData    // 重置是否有更多数据
        case removeFooter       // 移除table的加载更多
    }
    
    var bindAction: ((ViewModelAction) -> Void)?
    /// 当前版本数据的pagetoken
    private(set) var pageToken: String?
    /// 是否有更多数据
    private var hasMore: Bool = false
    /// 是否在加载中的标记
    private(set) var isLoadingData: Bool = false
    /// 获取版本数据请求
    private var fetchVersionDataRequest: DocsRequest<JSON>?
    /// 版本的源文档token
    private var sourceToken: String
    /// 文档类型
    public var type: DocsType
    /// 历史版本列表数据
    private(set) var versionDatas: [DocsVersionItemData] = []
    // 弹 toast 用
    weak var hostController: UIViewController?
    // 打开来源，统计上报用
    var fromSource: FromSource?
    
    public init(token: String, type: DocsType, fromSource: FromSource? = nil) {
        self.sourceToken = token
        self.type = type
        self.fromSource = fromSource
    }
}

// MARK: - Load data
extension DocsVersionsPanelViewModel {
    func loadData(loadMore: Bool = false) {
        if !DocsNetStateMonitor.shared.isReachable {
            endLoadingData()
            if let window = hostController?.view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_NetInterrupt,
                                       on: window)
            }
            DocsLogger.error("load version history fail network error: \(self.sourceToken.encryptToken)", component: LogComponents.version)
            return
        }
        isLoadingData = true
        fetchVersionHistorys(loadMore: loadMore) { items, success, hasMore, pageToken in
            guard success else {
                self.bindAction?(.loadError)
                return
            }
            if items != nil, items!.count > 0 {
                self.versionDatas.append(contentsOf: items!)
                self.pageToken = pageToken
                self.hasMore = hasMore
                self.bindAction?(.reloadData)
            } else {
                self.bindAction?(.loadEmpty)
            }
            self.endLoadingData()
            self.isLoadingData = false
        }
    }
    
    private func endLoadingData() {
        bindAction?(.stopLoading)
        if versionDatas.count > 0 {
            bindAction?(hasMore ? .resetNoMoreData : .noMoreData)
        } else {
            bindAction?(.removeFooter)
        }
    }
}

extension DocsVersionsPanelViewModel {
    var baseParams: [String: Any] {
        var params: [String: Any] = [String: Any]()
        params["parent_token"] = self.sourceToken
        params["obj_type"] = type.rawValue
        params["page_size"] = pageSize
        return params
    }
    
    func fetchVersionHistorys(loadMore: Bool = false, completion: @escaping ([DocsVersionItemData]?, Bool, Bool, String?) -> Void) {
        var params = baseParams
        if loadMore && hasMore, pageToken != nil {
            params["page_token"] = pageToken
        }
        fetchVersionDataRequest?.cancel()
        fetchVersionDataRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getVersionData, params: params)
            .set(method: .GET)
            .set(headers: ["Content-Type": "application/x-www-form-urlencoded"])
        DocsLogger.info("start request version history: \(self.sourceToken.encryptToken)", component: LogComponents.version)
        fetchVersionDataRequest?.start(result: { [weak self] (object, error) in
            guard let self = self else { return }
            if let error = error {
                DocsLogger.error("get version history failed", error: error, component: LogComponents.version)
                completion(nil, false, false, nil)
                return
            }
            guard let json = object,
                let code = json["code"].int else {
                DocsLogger.error("get version history invalide", component: LogComponents.version)
                completion(nil, false, false, nil)
                return
            }
            if code != 0 { // 解析错误码
                DocsLogger.error("get version history server code: \(code)", component: LogComponents.version)
                completion(nil, false, false, nil)
                return
            }
            guard let data = json["data"].dictionaryObject else {
                DocsLogger.error("get version history failed no data", component: LogComponents.version)
                completion(nil, false, false, nil)
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               let json = try? JSON(data: jsonData) {
                var resultData = [DocsVersionItemData]()
                let hasMore = json["has_more"].boolValue
                let pageToken = json["page_token"].string
                let list = json["version_metas"].array
                list?.forEach({ subData in
                    let subjson = subData 
                    let parentToken = subjson["parent_token"].string
                    let versionNum = subjson["version"].string
                    let versionToken = subjson["token"].string
                    let name = subjson["name"].string
                    let creatorid = subjson["creator_id"].uInt64Value
                    let createtime = subjson["create_time"].uInt64Value
                    let updatetime = subjson["update_time"].uInt64Value
                    
                    guard parentToken != nil, versionNum != nil, versionToken != nil, name != nil else {
                        DocsLogger.error("get version item decode data failed")
                        return
                    }
                    
                    var creator_name: String?
                    var creator_name_en: String?
                    var aliasInfo: UserAliasInfo?
                    if let users = json["users"].dictionaryObject,
                       let userInfo = users["\(creatorid)"] as? NSDictionary {
                        creator_name = userInfo["name"] as? String
                        creator_name_en = userInfo["en_name"] as? String
                        aliasInfo = UserAliasInfo(data: userInfo["display_name"] as? [String: Any] ?? [:])
                    }
                    let item = DocsVersionItemData(docToken: parentToken!,
                                                   versionToken: versionToken!,
                                                   name: name!.trimmingCharacters(in: .whitespacesAndNewlines),
                                                   version: versionNum!,
                                                   createtime: createtime,
                                                   updatetime: updatetime,
                                                   creatorName: creator_name,
                                                   creatorNameEn: creator_name_en,
                                                   aliasInfo: aliasInfo)
                    DocsVersionManager.shared.saveDocsVersionData(type: self.type, token: parentToken!, itemData: item)
                    resultData.append(item)
                })
                DocsLogger.info("get version history success: \(self.sourceToken.encryptToken), count:\(resultData.count)", component: LogComponents.version)
                NotificationCenter.default.post(name: Notification.Name.Docs.updateVersionInfoNotifictaion, object: nil, userInfo: nil)
                completion(resultData, true, hasMore, pageToken)
            } else {
                DocsLogger.error("get version history failed: decode data failed", component: LogComponents.version)
                completion(nil, false, false, nil)
            }
        })
    }
}
