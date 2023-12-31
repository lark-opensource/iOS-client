//
//  SyncBlockReferenceViewModel.swift
//  SKDoc
//
//  Created by lijuyou on 2023/8/2.
//

import Foundation
import SKUIKit
import SKResource
import SKFoundation
import SwiftyJSON
import UniverseDesignToast
import SpaceInterface
import SKInfra
import SKCommon

final class SyncBlockReferenceViewModel: NSObject {
    enum ViewModelAction {
        case loading            //加载中
        case reloadData         // 请求数据成功，刷新
        case loadError          // 加载失败
        case loadEmpty          // 结果为空
        case stopLoading        // 停止loading
        case noMoreData         // 没有更多数据
        case resetNoMoreData    // 重置是否有更多数据
        case removeFooter       // 移除table的加载更多
    }
    
    var bindAction: ((ViewModelAction) -> Void)?
    
    private(set) var isLoadingData: Bool = false
    private var fetchDataRequest: DocsRequest<JSON>?
    weak var hostController: UIViewController?
    
    private let docsToken: String
    private let docsType: DocsType
    var syncBlockToken: String {
        config.resourceToken
    }
    let config: ShowSyncedBlockReferencesParam
    private let defaultPageSize = 20
    
    private(set) var referenceListData: SyncBlockReferenceListData?
    private var hasMore: Bool {
        referenceListData?.hasMore ?? false
    }
    var title: String {
        return BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Locations_Tag(num: config.totalCount)
    }
    
    init(docsToken: String, docsType: DocsType, config: ShowSyncedBlockReferencesParam) {
        self.docsToken = docsToken
        self.docsType = docsType
        self.config = config
    }
    
    func loadData(loadMore: Bool = false) {
        if loadMore == false {
            self.bindAction?(.loading)
        }
        if !DocsNetStateMonitor.shared.isReachable {
            endLoadingData()
            if let window = hostController?.view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_NetInterrupt,
                                       on: window)
            }
            DocsLogger.error("loadData fail network error: \(self.syncBlockToken.encryptToken)", component: LogComponents.syncBlock)
            return
        }
        if !loadMore {
            referenceListData = nil
        }
        isLoadingData = true
        fetchData(loadMore: loadMore) { [weak self] success, listData in
            guard let self = self else { return }
            guard success else {
                self.bindAction?(.loadError)
                return
            }
            if self.referenceListData == nil {
                self.referenceListData = listData
            } else if let listData = listData {
                self.referenceListData?.merge(other: listData)
            }
            
            DocsLogger.info("getSyncBlockReference totalCount:\( self.referenceListData?.references?.count ?? -1)", component: LogComponents.syncBlock)
            
            if self.referenceListData?.hasData ?? false {
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
        if referenceListData?.hasData ?? false {
            bindAction?(hasMore ? .resetNoMoreData : .noMoreData)
        } else {
            bindAction?(.removeFooter)
        }
    }
}

extension SyncBlockReferenceViewModel {
    var baseParams: [String: Any] {
        let pageSize = self.config.limit > 0 ? self.config.limit : defaultPageSize
        var params: [String: Any] = [String: Any]()
        params["resource_token"] = self.syncBlockToken
        params["resource_type"] = self.config.resourceType
        params["docx_synced_block_host_token"] = self.docsToken
        params["docx_synced_block_host_type"] = self.docsType.rawValue
        params["limit"] = pageSize
        return params
    }
    
    func fetchData(loadMore: Bool = false, completion: @escaping (Bool, SyncBlockReferenceListData?) -> Void) {
        var params = baseParams
        if loadMore, hasMore, let breakPoint = self.referenceListData?.breakPoint {
            params["break_point"] = breakPoint
        }
        
        fetchDataRequest?.cancel()
        fetchDataRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getSyncBlockReference, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
        DocsLogger.info("getSyncBlockReference start: \(self.syncBlockToken.encryptToken)", component: LogComponents.syncBlock)
        fetchDataRequest?.start(result: { [weak self] (object, error) in
            guard let self = self else {
                completion(false, nil)
                return
            }
            if let error = error {
                DocsLogger.error("getSyncBlockReference failed", error: error, component: LogComponents.syncBlock)
                completion(false, nil)
                return
            }
            guard let json = object?.dictionaryObject,
                  let response = try? CodableUtility.decode(GetSyncBlockReferenceResponse.self, withJSONObject: json) else {
                DocsLogger.error("getSyncBlockReference decode failed", component: LogComponents.syncBlock)
                completion(false, nil)
                return
            }
            guard response.isSuccess, var rspData = response.data else { // 解析错误码
                DocsLogger.error("getSyncBlockReference rsp err:\(response.code), msg:\(String(describing: response.msg))", component: LogComponents.syncBlock)
                completion(false, nil)
                return
            }
            
            if !loadMore {
                if let host = rspData.host, host.isValid {
                    var item = SyncBlockReferenceItem(url: host.url, createTime: 0, objId: "", title: host.title, permitted: host.permitted)
                    if let url = URL(string: host.url),
                       let hostToken = DocsUrlUtil.getFileToken(from: url),
                       hostToken == self.docsToken {
                        item.isCurrent = true
                    }
                    rspData.append(item, insertFirst: true)
                }
                if let parent = rspData.parent, parent.isValid {
                    var item = SyncBlockReferenceItem(url: parent.url, createTime: 0, objId: "", title: parent.title, permitted: parent.permitted)
                    if let url = URL(string: parent.url),
                       let hostToken = DocsUrlUtil.getFileToken(from: url),
                       hostToken == self.docsToken {
                        item.isCurrent = true
                    }
                    item.isSource = true
                    rspData.append(item, insertFirst: true)
                }
            }
            
            DocsLogger.info("getSyncBlockReference success, rsp:\(rspData)", component: LogComponents.syncBlock)
            completion(true, rspData)
        })
    }
}
