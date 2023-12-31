//
//  DocsRestoreEmptyView.swift
//  SKCommon
//
//  Created by majie.7 on 2022/11/2.
//

import Foundation
import SKUIKit
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignColor
import SKResource
import SnapKit
import RxSwift
import SKFoundation
import EENavigator
import UniverseDesignToast
import LarkUIKit
import SpaceInterface


public enum RestoreType {
    case space(objToken: String, objType: DocsType)
    case wiki(wikiToken: String)
}

private enum RestorePramas {
    case space(nodeToken: String)
    case wiki(wikiToken: String, spaceID: String, targetType: Int)
}

public final class DocsRestoreEmptyView: UIView {
    
    private lazy var emptyView: UDEmptyView = {
        let config = UDEmptyConfig(description: .init(descriptionText: deletedTip),
                                   type: iconType)
        let view = UDEmptyView(config: config)
        return view
    }()
    
    var currentTopMost: UIViewController? {
        guard let rootVC = window?.rootViewController else {
            spaceAssertionFailure("cannot get rootVC")
            return nil
        }
        return UIViewController.docs.topMost(of: rootVC)
    }
    
    private let restoreType: RestoreType
    public var restoreCompeletion: (() -> Void)?
    public var restoreFaileCompeltion: ((DocsRestoreFailedInfo) -> Void)?
    public var isFolder: Bool {
        if case .space(_, let objType) = restoreType, objType == .folder {
            return true
        }
        return false
    }
    
    private var deletedTip: String {
        switch restoreType {
        case .space(_, let objType):
            if objType == .sync {
                return BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Deleted_Toast
            } else {
                return BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Common_Empty
            }
        case .wiki:
            return BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Common_Empty
        }
    }

    private var iconType: UDEmptyType {
        switch restoreType {
        case .space(_, let objType):
            if objType == .sync {
                return .vcRecycleBin
            } else {
                return .noContent
            }
        case .wiki:
            return .noContent
        }
    }
    
    private let disposeBag = DisposeBag()
    
    public convenience init(type: RestoreType) {
        self.init(frame: .zero, type: type)
        self.setupView()
        self.checkCanRestoreStatusRoute()
    }
    
    public init(frame: CGRect, type: RestoreType) {
        self.restoreType = type
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func checkCanRestoreStatusRoute() {
        switch restoreType {
        case let .space(objToken, objType):
            if objType.needCheckRestoreFromDeleted {
                checkSpaceRestoreStatus(objToken: objToken, objType: objType)
            }
        case let .wiki(wikiToken):
            checkWikiRestoreStatus(wikiToken: wikiToken)
        }
    }
    
    private func checkSpaceRestoreStatus(objToken: String, objType: DocsType) {
        DocsRestoreHandler.checkDocsDeletedCanRestore(token: objToken, type: objType)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (canRestore, nodeToken) in
                guard canRestore, let nodeToken else {
                    DocsLogger.info("the space docs can not support restore from trash")
                    self?.reportShowDeleteView(canRestore: false)
                    return
                }
                self?.showRestoreButton(pramas: .space(nodeToken: nodeToken))
            }) { [weak self] error in
                DocsLogger.error("the space docs check the restore status failed, error: \(error)")
                self?.reportShowDeleteView(canRestore: false)
            }.disposed(by: disposeBag)
    }
    
    private func checkWikiRestoreStatus(wikiToken: String) {
        DocsRestoreHandler.checkWikiDocsDeletedCanRestore(wikiToken: wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] (canRestore, spaceID, targetType) in
                guard canRestore, let spaceID, let targetType else {
                    self?.reportShowDeleteView(canRestore: false)
                    DocsLogger.info("the wiki docs can not support restore from trash")
                    return
                }
                self?.showRestoreButton(pramas: .wiki(wikiToken: wikiToken, spaceID: spaceID, targetType: targetType))
            }) { [weak self] error in
                DocsLogger.error("the wiki docs check the restore status failed, error: \(error)")
                self?.reportShowDeleteView(canRestore: false)
            }.disposed(by: disposeBag)
    }
    
    private func showRestoreButton(pramas: RestorePramas) {
        var config = emptyView.config
        config.primaryButtonConfig = .init((BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Restore_Button, { [weak self] button in
            let button = button as? UDButton
            button?.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Restoring_Toast_Mob, for: .normal)
            button?.config.loadingIconColor = UDColor.primaryOnPrimaryFill
            button?.config.type = .custom(type: (size: CGSize(width: 86, height: 32),
                                                 inset: 5,
                                                 font: UIFont.systemFont(ofSize: 14),
                                                 iconSize: CGSize(width: 12, height: 12)))
            button?.config.loadingColor = .init(borderColor: .clear,
                                                backgroundColor: UDColor.primaryContentLoading,
                                                textColor: UDColor.udtokenBtnPriTextDisabled)
            button?.showLoading()
            self?.restoreRoute(pramas: pramas, compeletion: {
                button?.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Restore_Button, for: .normal)
                button?.hideLoading()
            })
            self?.reportRestoreButtonClick()
        }))
        emptyView.update(config: config)
        reportShowDeleteView(canRestore: true)
    }
    
    private func restoreRoute(pramas: RestorePramas, compeletion: @escaping (() -> Void)) {
        switch pramas {
        case let .space(nodeToken):
            spaceRestore(token: nodeToken, compeletion: compeletion)
        case let .wiki(wikiToken, spaceID, targetType):
            wikiRestore(wikiToken: wikiToken, spaceID: spaceID, targetType: targetType, compeletion: compeletion)
        }
    }
    
    private func spaceRestore(token: String, compeletion: @escaping (() -> Void)) {
        DocsRestoreHandler.docsRestore(nodeToken: token)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] in
                guard let self = self else { return }
                self.restoreCompeletion?()
                self.showSuccess()
                if !self.isFolder {
                    //文件夹场景跳到一个folderVC，在跳转阶段有loading，如果remove会导致短时间的白屏
                    self.removeFromSuperview()
                }
                
            }) {[weak self] error in
                self?.reportRestoreResultView(success: false)
                DocsLogger.error("restore the space docs error, error: \(error)")
                if let rxError = error as? RxError, case .timeout = rxError {
                    //超时弹窗
                    self?.showFailure()
                } else if let restoreError = error as? RestoreNetWorkError {
                    self?.restoreFailedHadnler(error: restoreError)
                } else {
                    self?.showFailure()
                }
                compeletion()
            }.disposed(by: disposeBag)
    }
    
    private func wikiRestore(wikiToken: String, spaceID: String, targetType: Int, compeletion: @escaping (() -> Void)) {
        DocsRestoreHandler.wikIRestore(wikiToken: wikiToken,
                                       spaceID: spaceID,
                                       targetType: targetType)
        .observeOn(MainScheduler.instance)
        .subscribe(onSuccess: {[weak self] in
            self?.restoreCompeletion?()
            self?.showSuccess()
            self?.removeFromSuperview()
        }) {[weak self] error in
            self?.reportRestoreResultView(success: false)
            if let restoreError = error as? RestoreNetWorkError {
                self?.restoreFailedHadnler(error: restoreError)
            } else {
                self?.showFailure()
            }
            DocsLogger.error("restore the wiki docs error, error: \(error)")
            compeletion()
        }.disposed(by: disposeBag)
    }
    
    private func showSuccess() {
        UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_Restored_Toast, on: self.window ?? self)
        reportRestoreResultView(success: true)
    }
    
    private func showFailure() {
        UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_Wiki_CannotRestore_Toast, on: self.window ?? self)
    }
    
    private func restoreFailedHadnler(error: RestoreNetWorkError) {
        switch error {
        case let .permissionError(failedInfo):
            showRestoreFailedPanel(failedInfo: failedInfo)
        case .unknown:
            showFailure()
        }
    }
    
    private func showRestoreFailedPanel(failedInfo: DocsRestoreFailedInfo) {
        guard let currentTopMost else {
            showFailure()
            DocsLogger.error("can not present restore failed panel, currentTopMost is nil")
            return
        }
        let vc = DocsRestoreFailePanel(info: failedInfo)
        let nav = LkNavigationController(rootViewController: vc)
        vc.clickCompeletion = { type in
            nav.dismiss(animated: true)
            switch type {
            case let .at(id):
                HostAppBridge.shared.call(ShowUserProfileService(userId: id, fromVC: currentTopMost))
            case let .toWiki(url):
                Navigator.shared.push(url, from: currentTopMost)
            }
        }
        
        nav.setNavigationBarHidden(true, animated: false)
        nav.transitioningDelegate = vc.panelFormSheetTransitioningDelegate
        nav.modalPresentationStyle = .formSheet
        nav.presentationController?.delegate = vc.adaptivePresentationDelegate
        currentTopMost.present(nav, animated: true)
    }
}

extension DocsRestoreEmptyView {
    func reportShowDeleteView(canRestore: Bool) {
        let params: [String: Any] = ["is_recover_button_show": canRestore]
        DocsTracker.newLog(enumEvent: .docsDeleteView, parameters: params)
    }
    
    func reportRestoreButtonClick() {
        let params: [String: Any] = ["click": "recover_docs", "target": "ccm_docs_page_view"]
        DocsTracker.newLog(enumEvent: .docsDeleteRestoreClick, parameters: params)
    }
    
    func reportRestoreResultView(success: Bool) {
        let params: [String: Any] = ["if_success": success]
        DocsTracker.newLog(enumEvent: .docsResotreResultView, parameters: params)
    }
}
