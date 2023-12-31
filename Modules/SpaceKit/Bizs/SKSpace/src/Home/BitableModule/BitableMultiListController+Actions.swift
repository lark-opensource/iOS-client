//
//  BitableMultiListController+Actions.swift
//  SKSpace
//
//  Created by ByteDance on 2023/12/14.
//

import Foundation
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import ESPullToRefresh
import LarkContainer

import SKUIKit
import SKResource
import SKFoundation
import SKCommon

import UniverseDesignColor
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkSceneManager
import LarkSplitViewController

import UniverseDesignBadge
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import SKWorkspace


// swiftlint:disable cyclomatic_complexity
 extension BitableMultiListController {
     //MARK: 容器纬度
    func handle(homeAction: SpaceHomeAction) {
        switch homeAction {
        case let .create(intent, sourceView):
            create(with: intent, sourceView: sourceView ?? createButton)
        case let .createFolder(intent):
            createFolder(intent: intent)
        case let .push(viewController):
            userResolver.navigator.push(viewController, from: self)
        case let .present(viewController, popoverConfiguration):
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfiguration?(viewController)
            }
            userResolver.navigator.present(viewController, from: self)
        case let .showHUD(action):
            handle(action: action)
        case .sectionAction(_):
            break
        }
    }

    //MARK: 业务逻辑纬度
    func handle(action: SpaceHomeUI.Action) {
        switch action {
        case let .push(viewController):
            userResolver.navigator.push(viewController, from: self)
        case let .showDetail(viewController):
            userResolver.navigator.docs.showDetailOrPush(viewController, wrap: LkNavigationController.self, from: self)
        case let .present(viewController, popoverConfiguration, completion):
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfiguration?(viewController)
            }
            let from: UIViewController = self.presentedViewController ?? self
            userResolver.navigator.present(viewController, from: from, completion: completion)
        case let .showDeleteFailListView(files: files):
            showDeleteFailView(files: files)
        case let .showHUD(action):
            handle(action: action)
        case .hideHUD:
            UDToast.removeToast(on: view.window ?? view)
        case let .presentOrPush(viewController, popoverConfiguration):
            if SKDisplay.pad {
                popoverConfiguration?(viewController)
                userResolver.navigator.present(viewController, wrap: LkNavigationController.self, from: self)
                return
            }
            userResolver.navigator.push(viewController, from: self)
        case let .toast(content):
            UDToast.showTips(with: content, on: view.window ?? view)
        case .startSpaceUserGuide:
            return
        case .startCloudDriveOnboarding:
            return
        case let .open(entry, context):
            userResolver.navigator.docs.showDetailOrPush(body: entry, context: context, wrap: LkNavigationController.self, from: self, animated: true)
        case let .confirmDeleteAction(file, completion):
            showDeleteConfirmView(file: file, completion: completion)
        case .stopPullToRefresh:
            guard refreshing else { return }
            collectionView.es.stopPullToRefresh()
            return
        case let .stopPullToLoadMore(hasMore):
            collectionView.es.stopLoadingMore()
            footerAnimator.hasMore = hasMore
            if hasMore {
                collectionView.es.resetNoMoreData()
            } else {
                collectionView.es.noticeNoMoreData()
            }
        case let .showRefreshTips(callback):
            showRefreshTipsIfNeed(callback: callback)
        case let .dismissRefreshTips(needScrollToTop):
            dismissRefreshTips()
            if needScrollToTop {
                forceScrollToTop()
            }
        case let .showManualOfflineSuggestion(completion):
            showManualOfflineSuggestion(completion: completion)
        case let .confirmRemoveManualOffline(completion):
            showDeleteConfirmForManualOfflineView(completion: completion)
        case let .showDriveUploadList(folderToken):
            return
        case let .create(intent, sourceView):
            create(with: intent, sourceView: sourceView)
        case let .newScene(scene):
            self.openNewScene(with: scene)
        case .exit:
            // 参考 BaseViewController 的 back 方法实现
            if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
                if self.presentingViewController != nil {
                    dismiss(animated: true, completion: nil)
                }
            } else {
                dismiss(animated: true, completion: nil)
            }
        case let .openWithAnother(file, originName, popoverSourceView: popoverSourceView, arrowDirection: arrowDirection):
            //待优化，more面板V2
            DocsContainer.shared.resolve(DriveVCFactoryType.self)!
                .openDriveFileWithOtherApp(file: file,
                                           originName: originName,
                                           sourceController: self,
                                           sourceRect: popoverSourceView.frame,
                                           arrowDirection: arrowDirection)
        case var .openShare(body):
            //待优化，more面板V2
            let needPopover = SKDisplay.pad && (self.isMyWindowRegularSize())
            body.needPopover = needPopover
            userResolver.navigator.present(body: body, from: self, animated: needPopover)
        case var .exportDocument(body):
            //待优化，more面板V2
            let needPopover = SKDisplay.pad && (self.isMyWindowRegularSize())
            body.hostSize = self.view.bounds.size
            body.needFormSheet = needPopover
            body.hostViewController = self
            userResolver.navigator.present(body: body, from: self, animated: true)
        case let .copyFile(completion):
            //待优化，more面板V2
            completion(self)
        case let .saveToLocal(file, originName):
            DocsContainer.shared.resolve(DriveVCFactoryType.self)!
                .saveToLocal(file: file, originName: originName, sourceController: self)
        case let .openURL(url, context):

            if var newContext = context {
                newContext["showTemporary"] = false
                userResolver.navigator.docs.showDetailOrPush(url, context: newContext, from: self)
            } else {
                userResolver.navigator.docs.showDetailOrPush(url, context: ["showTemporary": false], from: self)
            }
        case let .showUserProfile(userID):
            let profileService = ShowUserProfileService(userId: userID, fromVC: self)
            HostAppBridge.shared.call(profileService)
        case .dismissPresentedVC:
            if let presentedViewController {
                presentedViewController.dismiss(animated: true)
            }
        }
    }
     
    //MARK: toast纬度
    func handle(action: SpaceHomeUI.Action.HUDAction) {
        switch action {
        case let .warning(content):
            UDToast.showWarning(with: content, on: toastDisplayView)
        case let .customLoading(content):
            UDToast.showDefaultLoading(with: content, on: toastDisplayView)
        case let .failure(content):
            UDToast.showFailure(with: content, on: toastDisplayView)
        case let .success(content):
            UDToast.showSuccess(with: content, on: toastDisplayView, delay: 2)
        case let .tips(content):
            UDToast.showTips(with: content, on: toastDisplayView)
        case let .custom(config, operationCallback):
            UDToast.showToast(with: config, on: toastDisplayView, delay: 2, operationCallBack: operationCallback)
        case let .tipsmanualOffline(text, buttonText):
            let opeartion = UDToastOperationConfig(text: buttonText, displayType: .horizontal)
            let config = UDToastConfig(toastType: .info, text: text, operation: opeartion)
            UDToast.showToast(with: config, on: view, delay: 2, operationCallBack: { [weak self]_ in
                guard let self = self else { return }
                NetworkFlowHelper.dataTrafficFlag = true
                UDToast.removeToast(on: self.view)
                })
        }
    }
    
    //MARK: collectionView刷新
    func handle(reloadAction: SpaceHomeUI.ReloadAction) {
        switch reloadAction {
        case .fullyReload:
            collectionView.reloadData()
        case let .reloadSections(sections, animated):
            let sectionSet = IndexSet(sections)
            if animated {
                collectionView.reloadSections(sectionSet)
            } else {
                UIView.performWithoutAnimation {
                    collectionView.reloadSections(sectionSet)
                }
            }
        case let .reloadSectionCell(sectionIndex, animated):
            let sectionIndices = collectionView.indexPathsForVisibleItems.filter { $0.section == sectionIndex }
            guard !sectionIndices.isEmpty else { return }
            if animated {
                collectionView.reloadItems(at: sectionIndices)
            } else {
                UIView.performWithoutAnimation {
                    collectionView.reloadItems(at: sectionIndices)
                }
            }
        case let .update(sectionIndex, inserts, deletes, updates, moves, willUpdate):
            let indexToPathTransform: (Int) -> IndexPath = { IndexPath(item: $0, section: sectionIndex) }
            collectionView.performBatchUpdates({
                willUpdate()
                collectionView.deleteItems(at: deletes.map(indexToPathTransform))
                collectionView.insertItems(at: inserts.map(indexToPathTransform))
                collectionView.reloadItems(at: updates.map(indexToPathTransform))
                moves.forEach { (from, to) in
                    let fromPath = indexToPathTransform(from)
                    let toPath = indexToPathTransform(to)
                    collectionView.moveItem(at: fromPath, to: toPath)
                }
            }, completion: nil)
        case let .getVisableIndexPaths(callback):
            let indexPaths = collectionView.indexPathsForVisibleItems
            callback(indexPaths)
        case let .scrollToCell(indexPath, scrollPosition, animated):
            if !animated && indexPath.section == 0 && indexPath.item == 0 {
                collectionView.setContentOffset(.zero, animated: false)
            } else {
                collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
            }
        }
        updateDecorationView()
        monitorSectionLoadState()
    }

    // 这里单独实现了noticeNoMoreData()的逻辑，ESPullToRefresh的源码被魔改了，结果与预期不对
    private func noticeNoMoreData() {
        collectionView.footer?.stopRefreshing()
        collectionView.footer?.noMoreData = true
        collectionView.footer?.isHidden = true
    }
    
    private var toastDisplayView: UIView {
        let theWindow: UIWindow?
        if let wd = view.window {
            theWindow = wd
        } else { // iOS 12 有可能获取不到所在window, 兜底
            theWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
        return theWindow ?? view
    }
     
    @discardableResult
    private func create(with intent: SpaceCreateIntent, sourceView: UIView) {
        var isEmpty = false
        if let sectionState = internalCollectionView.currentSubSection?.listState {
            if case .empty = sectionState {
                 isEmpty = true
            }
        }
        self.delegate?.createBitableFileIfNeeded(isEmpty: isEmpty)
    }

    private func showManualOfflineSuggestion(completion: @escaping (Bool) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_OfflineSetAvailable)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_OfflineDownloadTip,
                            color: UDColor.textTitle,
                            font: UIFont.systemFont(ofSize: 16),
                            alignment: .center,
                            lineSpacing: 3,
                            numberOfLines: 0)

        // 设置为手动离线
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_OfflineMakeAvailable, dismissCheck: {
             completion(true)
             return true
         })

        // 不用了
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_List_OfflineNeedNot, dismissCheck: {
             completion(false)
             return true
         })
        present(dialog, animated: true)
     }

     private func createFolder(intent: SpaceCreateIntent) {
         let ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
         let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                    module: intent.context.module,
                                                                    ccmOpenSource: ccmOpenSource)
         let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                             mountLocation: intent.context.mountLocation,
                                             createDelegate: self,
                                             createRouter: self,
                                             createButtonLocation: intent.createButtonLocation)
         helper.directlyCreateFolder()
     }
}

//MARK: 文件删除
private extension BitableMultiListController {
    private func showDeleteConfirmView(file: SpaceEntry, completion: @escaping SpaceSectionAction.DeleteCompletion) {
        let ownerID = file.ownerID ?? ""
        var checkBoxTips = ""
        var canDeleteOriginFile = false
        var isNeedCheckBox = false
        if !file.isSingleContainerNode {
            if let userID = User.current.info?.userID, ownerID == userID, file.type != .folder, file.type != .wiki {
                canDeleteOriginFile = true
            }
            if canDeleteOriginFile {
                checkBoxTips = BundleI18n.SKResource.Doc_List_Delete_Source_Item
                isNeedCheckBox = true
            }
        }

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_Remove_Recent_Dialog_Title, checkButton: isNeedCheckBox)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_Remove_Recent_Dialog_Content, checkButton: isNeedCheckBox)
        if isNeedCheckBox {
            dialog.setCheckButton(text: checkBoxTips)
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { () -> Bool in
            completion(false, false)
            return true
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_More_Remove, dismissCheck: { [weak dialog] () -> Bool in
            let shouldDeleteOriginFile = dialog?.isChecked ?? false
            if canDeleteOriginFile, shouldDeleteOriginFile {
                completion(true, true)
            } else {
                completion(true, false)
            }
            return true
        })
        present(dialog, animated: true, completion: nil)
    }

    private func showDeleteConfirmForManualOfflineView(completion: @escaping (Bool) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_OfflineRemoveTitle)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_OfflineRemoveContent)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { () -> Bool in
            completion(false)
            return true
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_More_Remove, dismissCheck: { () -> Bool in
            completion(true)
            return true
        })
        present(dialog, animated: true, completion: nil)
    }
    private func showDeleteFailView(files: [SpaceEntry]) {
        typealias Parser = SpaceList.ItemDataParser

        let models = files.map { (entry) -> DeleteFailListItem in
            let title = Parser.mainTitle(file: entry, shouldShowNoPermBiz: true)
            let listIconType = Parser.listIconType(file: entry, shouldShowNoPermBiz: true, preferSquareDefaultIcon: false)
            var subtitle: String?
            if entry.hasPermission {
                if entry.isShortCut {
                    subtitle = BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder
                } else if let ownerName = entry.owner {
                    subtitle = BundleI18n.SKResource.Doc_Share_ShareOwner + ": " + ownerName
                } else {
                    subtitle = BundleI18n.SKResource.Doc_Share_ShareOwner
                }
            }

            let item = DeleteFailListItem(enable: true,
                                     title: title,
                                     subTitle: subtitle,
                                     isShortCut: entry.isShortCut,
                                     listIconType: listIconType,
                                     hasPermission: entry.hasPermission,
                                     entry: entry)

            return item
        }

        guard !models.isEmpty else {
            DocsLogger.info("fail item is empty")
            return
        }

        if SKDisplay.pad, isMyWindowRegularSize() {
            let viewController = IpadDeleteFailViewController(userResolver: userResolver, items: models)
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            userResolver.navigator.present(nav, from: self)
        } else {
            let viewController = DeleteFailViewController(userResolver: userResolver, items: models)
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            userResolver.navigator.present(nav, from: self)
        }
    }
}

//MARK: 列表更新提示
extension BitableMultiListController {
    public func visableIndicesHelper(sectionIndex: Int) -> () -> [Int] {
        return { [weak self] in
            guard let self = self else { return [] }
            let task: () -> [Int] = {
                let indices = self.collectionView.indexPathsForVisibleItems
                    .filter { $0.section == sectionIndex }
                    .map(\.item)
                return indices
            }
            if Thread.current.isMainThread {
                return task()
            } else {
                return DispatchQueue.main.sync(execute: task)
            }
        }
    }

    private func showRefreshTipsIfNeed(callback: @escaping () -> Void) {
        guard currentShowStyle == .fullScreen else {
            return
        }
        guard refreshTipView == nil else { return }
        let config = SettingConfig.spaceRustPushConfig ?? .default
        if let previousDate = previousTipShowDate {
            let timeInterval = Date().timeIntervalSince(previousDate) * 1000
            if timeInterval < config.minimumTipInterval { return }
        }
        previousTipShowDate = Date()
        let tipView = SpaceListRefreshTipView()
        refreshTipView = tipView
        tipView.alpha = 0
        view.addSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(40)
            make.right.lessThanOrEqualToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(60)
        }
        UIView.animate(withDuration: 0.5) {
            tipView.alpha = 1
        }
        tipView.clickHandler = callback
        // ms 转换为 s
        tipView.set(timeout: config.refreshTipDuration / 1000) { [weak self] in
            self?.dismissRefreshTips()
        }
    }

    private func dismissRefreshTips() {
        guard let tipView = refreshTipView else { return }
        refreshTipView = nil
        UIView.animate(withDuration: 0.5) {
            tipView.alpha = 0
        } completion: { _ in
            tipView.removeFromSuperview()
        }
    }
}
