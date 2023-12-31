//
//  BasePermission.swift
//  SKBitable
//
//  Created by yinyuan on 2023/7/25.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import RxSwift

protocol BasePermissionObserver: AnyObject {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool)          // 用于防截屏等，首次监听时会默认发送一次状态
    func initOrUpdateWatermark(shouldShowWatermark: Bool)             // 用于水印，首次监听时会默认发送一次状态
}

extension BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {}
    func initOrUpdateWatermark(shouldShowWatermark: Bool) {}
}

/// 当一个页面需要防截屏或者加水印时，你需要使用这个对象，这里处理了监听逻辑
class BasePermissionHelper: NSObject {
    private let baseContext: BaseContext
    private var lastShouldShowWatermark: Bool = false
    
    private weak var observer: BasePermissionObserver?
    
    private let disposeBag = DisposeBag()

    init(baseContext: BaseContext) {
        self.baseContext = baseContext
        super.init()
        
        setup()
    }
    
    private func setup() {
        guard UserScopeNoChangeFG.YY.bitableReferPermission else {
            return
        }
        let shouldShowWatermark = baseContext.shouldShowWatermark
        let hasCapturePermission = baseContext.hasCapturePermission
        self.lastShouldShowWatermark = shouldShowWatermark
        DocsLogger.info("[BasePermission] BasePermissionHelper setup permissionObj:\(baseContext.permissionObj.description) \(hasCapturePermission) \(shouldShowWatermark)")
        
        // 监听截屏权限变化
        baseContext.permissionEventNotifier?.addObserver(self)
        
        if !UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
            baseContext.permissionService?.onPermissionUpdated
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.onPermissionUpdated()
                }, onError: { error in
                    DocsLogger.error("[BasePermission] BasePermissionHelper permission update error", error: error)
                })
                .disposed(
                    by: disposeBag
                )
        }
        
        // 监听水印变化
        WatermarkManager.shared.addListener(self)
        
        // 主动请求 refer base 的水印信息
        if case .referenceDocument(let objToken) = baseContext.permissionDocumentType {
            WatermarkManager.shared.requestWatermarkInfo(.init(objToken: objToken, type: DocsType.bitable.rawValue))
        }
    }
    
    /// 开始监听变化
    /// - Parameters:
    ///   - observer: 监听器
    ///   - initCurrent: 是否立即使用当前数据进行一次初始化
    func startObserve(observer: BasePermissionObserver, initCurrent: Bool = true) {
        guard UserScopeNoChangeFG.YY.bitableReferPermission else {
            return
        }
        DocsLogger.info("[BasePermission] BasePermissionHelper startObserve permissionObj:\(baseContext.permissionObj.description)")
        
        self.observer = observer
        
        if initCurrent {
            notifyPermissionChange()
        }
    }
    
    private func onPermissionUpdated() {
        if UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
            return
        }
        DocsLogger.info("[BasePermission] BasePermissionHelper handlePermissionUpdated start")
        guard baseContext.isAddRecord || baseContext.isIndRecord else {
            return
        }
        // 需要调用这个方法，把权限更新到 permissionManager 中，否则读取权限时可能不生效
        baseContext.notifyPermissionSDKToSyncPermission()
        
        
        notifyPermissionChange()
    }
    
    private func notifyPermissionChange() {
        
        let hasCapturePermission = baseContext.hasCapturePermission
        let shouldShowWatermark = baseContext.shouldShowWatermark
        self.lastShouldShowWatermark = shouldShowWatermark
        
        DocsLogger.info("[BasePermission] BasePermissionHelper notifyPermissionChange:\(baseContext.permissionObj.description) \(hasCapturePermission) \(shouldShowWatermark)")
        
        self.observer?.initOrUpdateCapturePermission(hasCapturePermission: hasCapturePermission)
        self.observer?.initOrUpdateWatermark(shouldShowWatermark: shouldShowWatermark)
    }
}

extension BasePermissionHelper: DocsPermissionEventObserver {
    func onCopyPermissionUpdated(canCopy: Bool) {
        DocsLogger.btInfo("[BasePermission] BasePermissionHelper onCopyPermissionUpdated: \(canCopy) permissionObj:\(baseContext.permissionObj.description)")
        self.observer?.initOrUpdateCapturePermission(hasCapturePermission: baseContext.hasCapturePermission)
    }
}

extension BasePermissionHelper: WatermarkUpdateListener {
    func didUpdateWatermarkEnable() {
        // 这里不能区分是哪个文档的变化，因此采用 lastShouldShowWatermark 来 diff
        let shouldShowWatermark = baseContext.shouldShowWatermark
        guard lastShouldShowWatermark != shouldShowWatermark else {
            // 没有变化，不需要处理
            return
        }
        self.lastShouldShowWatermark = shouldShowWatermark
        DocsLogger.info("[BasePermission] BasePermissionHelper didUpdateWatermarkEnable: \(shouldShowWatermark) permissionObj:\(baseContext.permissionObj.description)")
        self.observer?.initOrUpdateWatermark(shouldShowWatermark: shouldShowWatermark)
    }
}
