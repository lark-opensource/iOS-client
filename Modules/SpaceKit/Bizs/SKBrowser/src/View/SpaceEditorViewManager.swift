//
//  SpaceEditorViewManager.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/3/26.
//  

import Foundation
import SKCommon
import SKUIKit
import SpaceInterface
import LarkContainer

protocol SpaceEditorLoadingAbility {
    func updateLoadStatus(_ type: LoadingViewType, oldStatus: LoadStatus?)

    //打开文档时显示的loading
    func showLoadingIndicator()
    func hideLoadingIndicator(completion: @escaping () -> Void)
    func clear()
    var identity: String? { get set }
}

protocol SpaceEditorViewManagerDelegate: AnyObject {
    var docsInfo: DocsInfo? { get }
}

extension BrowserView: SpaceEditorViewManagerDelegate {

}

typealias EditorTipAbility = UIView & BannerItem

protocol SapceEditorTipShowAble: EditorTipAbility {
    func setTip(_ type: TipType)
}

struct SpaceEditorViewManagerConfig {
    var loadingAnimation: DocsLoadingViewProtocol?
    var hostView: UIView = .init()
    weak var statusViewDelegate: DocsStatusViewDelegate?
    weak var bannerItemAgent: BannerItemAgent?
    var identity: String!
}

class SpaceEditorViewManager {
    weak var hostView: UIView?
    weak var delegate: SpaceEditorViewManagerDelegate?
    weak var bannerItemAgent: BannerItemAgent?
    var loadingManager: SpaceEditorLoadingAbility?
    let userResolver: UserResolver
    lazy var offlineManager: OfflineViewManager = {
        let offlineManager = OfflineViewManager()
        return offlineManager
    }()
    init?(config: SpaceEditorViewManagerConfig, delegate: SpaceEditorViewManagerDelegate, userResolver: UserResolver) {
        guard let type = delegate.docsInfo?.type  else { return nil }
        self.userResolver = userResolver
        self.delegate = delegate
        self.hostView = config.hostView
        self.bannerItemAgent = config.bannerItemAgent
        loadingManager = SpaceStatusViewManager.statusViewMangerWith(hostView: hostView,
                                                                     delegate: config.statusViewDelegate,
                                                                     userResolver: userResolver)
        loadingManager?.identity = config.identity
    }

    func networkReachableDidChange(_ networkReachable: Bool) {
        if networkReachable {
            bannerItemAgent?.requestHideItem(offlineManager.offlineTipView)
        } else {
            let isVersion = delegate?.docsInfo?.isVersion ?? false
            guard !isVersion else {
                return
            }
            let type: DocsType = delegate?.docsInfo?.type ?? .doc
            offlineManager.updateOfflineTips(with: type, isOfflineCreate: isOfflineCreate)
            bannerItemAgent?.requestShowItem(offlineManager.offlineTipView)
        }
    }

    func setOfflineTipViewStatus(_ status: Bool) {
        bannerItemAgent?.requestChangeItemVisibility(to: status)
    }

    var isOfflineCreate: Bool {
        return delegate?.docsInfo?.objToken.hasPrefix("fake") ?? false
    }

    func clear() {
        loadingManager?.clear()
    }
}
