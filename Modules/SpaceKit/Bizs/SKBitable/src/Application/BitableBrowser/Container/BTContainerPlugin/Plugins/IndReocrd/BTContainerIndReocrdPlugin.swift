//
//  BTContainerIndRecordPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/10/19.
//

import SKFoundation
import SKInfra
import SKCommon
import SKBrowser
import LarkStorage
import LarkAccountInterface
import UniverseDesignToast
import SKResource

class BTContainerIndRecordPlugin: BTContainerBasePlugin {
    
    weak var currentIndCardVC: BTController?
    
    private var request: DocsRequest<Any>? // 必须持有住，不然还没请求就自己释放了
    private var metaPrefetchCallbackParams: [String: Any]?
    private var metaCallback: ((_ params: [String: Any]) -> Void)?
    
    private var metaPrefetchTime: Date?
    private var metaPrefetchCallbackTime: Date?
    private var getRecordContentTime: Date?
    
    private static let domain = Domain.biz.ccm.child("bitable").child("onboarding")
    private static let keyHasShowedAddNextRecordTips = "hasShowedAddNextRecordTips"
    
    private lazy var store: KVStore = {
        return KVStores.udkv(space: .user(id: AccountServiceAdapter.shared.currentChatterId), domain: Self.domain)
    }()
    
    override func load(service: BTContainerService) {
        super.load(service: service)
        
        if UserScopeNoChangeFG.YY.bitablePerfOpenInRecordShare, service.isIndRecord {
            // 容器开始加载就立即请求 meta，减少 meta 请求时间
            prefetchMeta()
        }
    }
    
    // nolint: duplicated_code
    func showIndRecord(cardVC: BTController) {
        DocsLogger.btInfo("BTContainerFormViewPlugin.showIndRecord")
        guard let service = service else {
            DocsLogger.btError("showIndRecord invalid service")
            return
        }
        guard let parentVC = service.browserViewController else {
            DocsLogger.btError("showIndRecord invalid parentVC")
            return
        }
        guard cardVC.parent == nil else {
            DocsLogger.btError("cardVC has parent")
            return
        }
        self.currentIndCardVC = cardVC
        
        cardVC.view.removeFromSuperview()
        
        parentVC.addChild(cardVC)
        parentVC.view.addSubview(cardVC.view)
        cardVC.didMove(toParent: parentVC)
        cardVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        service.setIndRecordShow(indRecordShow: true)
        
        showAddNextRecordTipsIfNeeded(on: cardVC.view)
    }
    
    func closeIndRecord() {
        DocsLogger.btInfo("BTContainerFormViewPlugin.closeIndRecord")
        guard let currentIndCardVC = currentIndCardVC else {
            DocsLogger.btError("no currentIndCardVC")
            return
        }
        currentIndCardVC.willMove(toParent: nil)
        currentIndCardVC.removeSelfFromParentVC()
        currentIndCardVC.view.removeFromSuperview()
        currentIndCardVC.didMove(toParent: nil)
        self.currentIndCardVC = nil
        
        service?.setIndRecordShow(indRecordShow: false)
    }
    
    private func prefetchMeta() {
        guard let token = service?.browserViewController?.docsInfo?.token else {
            DocsLogger.btError("invalid token")
            return
        }
        DocsLogger.btInfo("fetch bitable record meta begin")
        self.metaPrefetchTime = Date()
        let path = OpenAPI.APIPath.getBaseRecordMeta(token)
        let request = DocsRequest<Any>(path: path, params: nil)
            .set(method: .GET)
        self.request = request
        request.start { [weak self] (data, _, error) in
            guard let self = self else {
                return
            }
            var params: [String: Any] = [:]
            if let data = data, let result = String(data: data, encoding: .utf8) {
                params["data"] = result
                DocsLogger.btInfo("fetch bitable record meta success")
            } else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.btError("fetch bitable record meta failed: \(error)")
                params["error"] = error.localizedDescription
            }
            self.prefetchMetaResponse(params: params)
        }
    }
    
    private func prefetchMetaResponse(params: [String: Any]) {
        self.metaPrefetchCallbackParams = params
        self.metaPrefetchCallbackTime = Date()
        if let metaCallback = self.metaCallback {
            DocsLogger.btInfo("prefetchMetaResponse callback")
            // 已经有绑定的 callback，直接返回
            metaCallback(params)
            statistic()
            return
        } else {
            DocsLogger.btInfo("prefetchMetaResponse no callback")
        }
    }
    
    func getRecordContent(callback: @escaping (_ params: [String: Any]) -> Void) {
        self.getRecordContentTime = Date()
        if let metaPrefetchCallbackParams = self.metaPrefetchCallbackParams {
            DocsLogger.btInfo("getRecordContent callback")
            // 已经有预加载的数据，直接返回
            callback(metaPrefetchCallbackParams)
            statistic()
            return
        } else {
            DocsLogger.btInfo("getRecordContent no callback")
        }
        // 数据尚未返回，先等等
        self.metaCallback = callback
    }
    
    private func statistic() {
        guard let metaPrefetchTime = self.metaPrefetchTime else {
            return
        }
        guard let getRecordContentTime = self.getRecordContentTime else {
            return
        }
        guard let metaPrefetchCallbackTime = self.metaPrefetchCallbackTime else {
            return
        }
        let now = Date()
        let getRecordContentCost = Int(now.timeIntervalSince(getRecordContentTime) * 1000)
        let metaPrefetchCost = Int(metaPrefetchCallbackTime.timeIntervalSince(metaPrefetchTime) * 1000)
        DocsLogger.btInfo("getRecordContentCost:\(getRecordContentCost)ms, metaPrefetchCost:\(metaPrefetchCost)ms")
    }
    
    private var hasShowedAddNextRecordTips: Bool {
        get {
            return store.bool(forKey: Self.keyHasShowedAddNextRecordTips)
        }
        set {
            store.set(newValue, forKey: Self.keyHasShowedAddNextRecordTips)
        }
    }
    
    private func showAddNextRecordTipsIfNeeded(on view: UIView) {
        guard UserScopeNoChangeFG.YY.baseAddRecordPage, currentIndCardVC?.viewModel.addToken != nil else {
            // 不是从记录新建跳转的场景，不需要提示
            return
        }
        if hasShowedAddNextRecordTips {
            return
        }
        UDToast.showTips(with: BundleI18n.SKResource.Bitable_QuickAdd_ClickMoreToAddNext_Toast, on: view)
        hasShowedAddNextRecordTips = true
    }
}
