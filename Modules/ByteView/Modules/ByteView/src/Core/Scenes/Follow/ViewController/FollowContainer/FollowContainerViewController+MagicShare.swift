//
//  FollowContainerViewController+MagicShare.swift
//  ByteView
//
//  Created by Prontera on 2020/4/13.
//

import Foundation
import RxSwift

extension FollowContainerViewController: InMeetFollowListener {

    /// 复用WebView，释放等待回收的延时
    static let reuseWebViewDelay: TimeInterval = 0.25

    /// 当前FollowContaienrVC的[WrapperVC]中的VC数量
    private var currentNavigationWrapperVCCount: Int {
        navigationWrapperViewController.viewControllers.count
    }

    /// MagicShare页面有变化时推送
    /// - Parameter event: MagicShare页面变化事件
    func didReceiveFollowEvent(_ event: InMeetFollowEvent) {
        Self.logger.debug("follow container did receive follow event, type: \(event.action)")
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.updateDocument(event.document,
                                status: event.status,
                                createSource: event.createSource,
                                clearStoredPos: event.clearStoredPos,
                                updateStyle: event.action)
            if event.document.user == self.viewModel.meeting.account, event.document.initSource == .initDirectly {
                self.switchToOverlayIfNeeded()
            }
        }
    }

    /// 根据不同的action类型，触发MagicShare的页面变化
    /// - Parameters:
    ///   - document: 新文档
    ///   - status: 文档的状态
    ///   - createSource: 文档创建来源，埋点使用
    ///   - clearStoredPos: 文档是否需要清理“回到上次位置”标记
    ///   - updateStyle: 触发妙享页面变化的action类型
    // disable-lint: long function
    private func updateDocument(_ document: MagicShareDocument,
                                status: MagicShareDocumentStatus,
                                createSource: MagicShareRuntimeCreateSource,
                                clearStoredPos: Bool,
                                updateStyle: InMeetFollowEvent.Action) {
        Self.logger.debug("follow container will update document to: \(document), by: \(updateStyle), shareID: \(document.shareID), status: \(status.description), createSource: \(createSource), clearStoredPos: \(clearStoredPos)")

        let oldRuntime = viewModel.manager.currentRuntime

        // 【1】现有wrapperVCs停止发出/应用妙享数据
        let wrapperVCs: [MagicShareWrapperViewController] = navigationWrapperViewController.viewControllers.compactMap { (vc: UIViewController) -> MagicShareWrapperViewController? in
            if let wrapperVC = (vc as? MagicShareWrapperViewController) {
                wrapperVC.stop()
                return wrapperVC
            }
            return nil
        }
        let currentWrapperVC: MagicShareWrapperViewController? = wrapperVCs.last

        // 【2】恢复主讲人方向指向
        if [.popTo, .replace, .updateStatus].contains(updateStyle) {
            viewModel.directionSubject.onNext(viewModel.manager.currentRuntime?.getLastDirection() ?? .free)
        } else if updateStyle == .reload {
            viewModel.resetPresenterDirection()
        }

        // 【3】dismiss掉当前页面顶部的vc，避免横竖屏切换导致SnapshotController无法消失
        if updateStyle == .popTo {
            let documentVC = currentWrapperVC?.runtime.documentVC
            if let presentedVC = documentVC?.presentedViewController {
                presentedVC.dismiss(animated: false)
            }
        }

        // 【4】查看是否可以复用当前文档，不必新建
        var newWrapperVC: MagicShareWrapperViewController?
        var isCurrentWrapperVCReuseable: Bool = false
        if [.replace, .updateStatus].contains(updateStyle),
           let validVC = currentWrapperVC,
           validVC.isTheSame(with: document) {
            validVC.updateDocument(document)
            switch status {
            case .sharing:
                validVC.startRecord()
            case .following:
                validVC.startFollow()
            case .sstomsFollowing:
                validVC.startSSToMSFollow()
            case .free, .sstomsFree:
                break
            }
            validVC.runtime.resetCreateSource(createSource)
            if updateStyle == .replace {
                handleReturnToLastLocation(runtime: validVC.runtime, clearStoredPos: clearStoredPos)
            } else if updateStyle == .updateStatus {
                if !clearStoredPos {
                    validVC.runtime.setReturnToLastLocation()
                }
            }
            viewModel.manager.currentRuntime = validVC.runtime
            newWrapperVC = validVC
            isCurrentWrapperVCReuseable = true
        }

        // 【5】创建并加载新文档
        let shouldDelayNextDocument: Bool = oldRuntime != nil
        let isWrapperVCsEmpty = wrapperVCs.isEmpty

        if newWrapperVC == nil, shouldDelayNextDocument, !isWrapperVCsEmpty, viewModel.meeting.setting.isMagicShareWebViewReuseEnabled {
            // 【5.1】当前有文档，则先释放文档，再延时加载新文档
            // 【5.1.1】释放当前文档
            oldRuntime?.replaceWithEmptyFollowAPI()
            oldRuntime?.documentVC.willMove(toParent: nil)
            oldRuntime?.documentVC.view.removeFromSuperview()
            oldRuntime?.documentVC.removeFromParent()
            oldRuntime?.documentVC.didMove(toParent: nil)
            navigationWrapperViewController.setViewControllers([MagicSharePlaceholderViewController()], animated: false)


            // 【5.1.2】延迟创建、加载新文档
            let hasCurrentWrapperVC = currentWrapperVC != nil
            let action = DispatchWorkItem(block: { [weak self] in
                self?.dispatchOperation(document: document,
                                        createSource: createSource,
                                        status: status,
                                        updateStyle: updateStyle,
                                        clearStoredPos: clearStoredPos,
                                        isWrapperVCsEmpty: isWrapperVCsEmpty,
                                        isCurrentWrapperVCReuseable: isCurrentWrapperVCReuseable,
                                        hasCurrentWrapperVC: hasCurrentWrapperVC)
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.reuseWebViewDelay, execute: action)
            self.dispatchAction = action
        } else {
            // 【5.2】不需要释放当前文档，则直接创建并加载新文档
            // 【5.2.1】创建新文档
            if newWrapperVC == nil {
                let (runtime, isNew) = self.viewModel.createRuntime(with: document,
                                                                    createSource: createSource,
                                                                    participantsCount: self.viewModel.manager.meeting.participant.currentRoom.count,
                                                                    forceCreate: self.viewModel.manager.isReloading || self.isGalleryCellMode)
                if isNew {
                    MagicShareTracksV2.trackDocumentLoad(shareId: document.shareID ?? "",
                                                         followType: status,
                                                         subLoadType: self.viewModel.manager.isReloading ? .refresh : .normal,
                                                         pageToken: document.token ?? document.ccmToken ?? "",
                                                         isUseUniqueWebView: viewModel.meeting.setting.isMagicShareWebViewReuseEnabled)
                }
                newWrapperVC = MagicShareWrapperViewController(runtime: runtime, meeting: self.viewModel.meeting, context: self.viewModel.context)
                if updateStyle == .reload {
                    self.viewModel.manager.isReloading = false
                }
                switch status {
                case .sharing:
                    newWrapperVC?.startRecord()
                case .following:
                    newWrapperVC?.startFollow()
                case .sstomsFollowing:
                    newWrapperVC?.startSSToMSFollow()
                case .free, .sstomsFree:
                    break
                }
                if updateStyle == .push {
                    if runtime.canBackToLastPosition {
                        if self.viewModel.manager.clearLocationOnNextDocument {
                            runtime.setClearStoredLocation()
                            self.viewModel.manager.clearLocationOnNextDocument = false
                        } else if !(isNew && clearStoredPos) {
                            runtime.setReturnToLastLocation()
                        }
                    }
                } else if [.popTo, .updateStatus].contains(updateStyle) {
                    if !(isNew && clearStoredPos) {
                        runtime.setReturnToLastLocation()
                    }
                } else if updateStyle == .replace {
                    self.handleReturnToLastLocation(runtime: runtime, clearStoredPos: (clearStoredPos && isNew))
                }
            }

            // 【5.2.2】筛查新页面是否正常
            guard let validNewWrapperVC = newWrapperVC else {
                Logger.vcFollow.warn("no valid new wrapper vc, \(updateStyle) operation failed")
                return
            }

            // 如果在reuseWebViewDelay期间收到了新的action，直接舍弃未执行的跳转
            self.dispatchAction?.cancel()

            // 【6】组织页面显示逻辑
            switch updateStyle {
            case .push:
                if !wrapperVCs.isEmpty {
                    self.navigationWrapperViewController.pushViewController(validNewWrapperVC, animated: true) { [weak self] in
                        self?.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
                    }
                } else {
                    self.navigationWrapperViewController.setViewControllers([], animated: false)
                    self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
                }
            case .popTo:
                if let validCurrentWrapperVC = currentWrapperVC {
                    self.navigationWrapperViewController.setViewControllers([validNewWrapperVC, validCurrentWrapperVC], animated: false)
                    self.navigationWrapperViewController.popToViewController(validNewWrapperVC, animated: true)
                } else {
                    self.navigationWrapperViewController.setViewControllers([], animated: false)
                    self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
                }
            case .replace, .updateStatus:
                if !isCurrentWrapperVCReuseable {
                    self.navigationWrapperViewController.setViewControllers([], animated: false)
                    self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
                } else {
                    Logger.vcFollow.debug("\(updateStyle) msWrapperVC ignored due to reuse")
                }
            case .reload:
                self.navigationWrapperViewController.setViewControllers([], animated: false)
                self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
            }
        }
    }

    private func dispatchOperation(document: MagicShareDocument,
                                   createSource: MagicShareRuntimeCreateSource,
                                   status: MagicShareDocumentStatus,
                                   updateStyle: InMeetFollowEvent.Action,
                                   clearStoredPos: Bool,
                                   isWrapperVCsEmpty: Bool,
                                   isCurrentWrapperVCReuseable: Bool,
                                   hasCurrentWrapperVC: Bool) {
        let newVC: MagicShareWrapperViewController?
        // 【5】无法复用，则创建新文档实例
        let (runtime, isNew) = self.viewModel.createRuntime(with: document,
                                                            createSource: createSource,
                                                            participantsCount: self.viewModel.manager.meeting.participant.currentRoom.count,
                                                            forceCreate: self.viewModel.manager.isReloading || self.isGalleryCellMode)
        if isNew {
            MagicShareTracksV2.trackDocumentLoad(shareId: document.shareID ?? "",
                                                 followType: status,
                                                 subLoadType: self.viewModel.manager.isReloading ? .refresh : .normal,
                                                 pageToken: document.token ?? document.ccmToken ?? "",
                                                 isUseUniqueWebView: viewModel.meeting.setting.isMagicShareWebViewReuseEnabled)
        }
        newVC = MagicShareWrapperViewController(runtime: runtime, meeting: self.viewModel.meeting, context: self.viewModel.context)
        if updateStyle == .reload {
            self.viewModel.manager.isReloading = false
        }
        switch status {
        case .sharing:
            newVC?.startRecord()
        case .following:
            newVC?.startFollow()
        case .sstomsFollowing:
            newVC?.startSSToMSFollow()
        case .free, .sstomsFree:
            break
        }
        if updateStyle == .push {
            if runtime.canBackToLastPosition {
                if self.viewModel.manager.clearLocationOnNextDocument {
                    runtime.setClearStoredLocation()
                    self.viewModel.manager.clearLocationOnNextDocument = false
                } else if !(isNew && clearStoredPos) {
                    runtime.setReturnToLastLocation()
                }
            }
        } else if [.popTo, .updateStatus].contains(updateStyle) {
            if !(isNew && clearStoredPos) {
                runtime.setReturnToLastLocation()
            }
        } else if updateStyle == .replace {
            self.handleReturnToLastLocation(runtime: runtime, clearStoredPos: (clearStoredPos && isNew))
        }

        // 【5.1】筛查新页面是否正常
        guard let validNewWrapperVC = newVC else {
            Logger.vcFollow.warn("no valid new wrapper vc, \(updateStyle) operation failed")
            return
        }

        // 【6】组织页面显示逻辑
        switch updateStyle {
        case .push:
            if !isWrapperVCsEmpty {
                self.navigationWrapperViewController.pushViewController(validNewWrapperVC, animated: true) { [weak self] in
                    self?.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
                }
            } else {
                self.navigationWrapperViewController.setViewControllers([], animated: false)
                self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
            }
        case .popTo:
            if hasCurrentWrapperVC {
                self.navigationWrapperViewController.setViewControllers([validNewWrapperVC, MagicSharePlaceholderViewController()], animated: false)
                self.navigationWrapperViewController.popToViewController(validNewWrapperVC, animated: true)
            } else {
                self.navigationWrapperViewController.setViewControllers([], animated: false)
                self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
            }
        case .replace, .updateStatus:
            if !isCurrentWrapperVCReuseable {
                self.navigationWrapperViewController.setViewControllers([], animated: false)
                self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
            } else {
                Logger.vcFollow.debug("\(updateStyle) msWrapperVC ignored due to reuse")
            }
        case .reload:
            self.navigationWrapperViewController.setViewControllers([], animated: false)
            self.navigationWrapperViewController.setViewControllers([validNewWrapperVC], animated: false)
        }
    }

    // enable-lint: long function
}

extension FollowContainerViewController {

    func handleReturnToLastLocation(runtime: MagicShareRuntime, clearStoredPos: Bool) {
        let canClearOrReturn: Bool = runtime.canBackToLastPosition
        let storedClearOnThisTime: Bool = self.viewModel.manager.clearLocationOnNextDocument
        switch (clearStoredPos, storedClearOnThisTime, canClearOrReturn) {
        case (true, true, true), (false, true, true), (true, false, true):
            runtime.setClearStoredLocation()
            self.viewModel.manager.clearLocationOnNextDocument = false
        case (true, _, false), (_, true, false):
            self.viewModel.manager.clearLocationOnNextDocument = true
        default:
            runtime.setReturnToLastLocation()
            self.viewModel.manager.clearLocationOnNextDocument = false
        }
    }

}

extension FollowContainerViewController {

    private func switchToOverlayIfNeeded() {
        container?.fullScreenDetector.postInterruptEvent()
    }

    func didUpdateMyselfInterpreterStatus(_ status: Bool) {
        viewModel.isInterpreterComponentDisplayRelay.accept(status)
    }

}

private extension UINavigationController {

    /// push成功后执行completion方法，为MS进入新文档增加“假动画”效果
    /// - Parameters:
    ///   - viewController: 被push的文档
    ///   - animated: 是否有动画
    ///   - completion: 动画执行结束后的操作
    func pushViewController(_ viewController: UIViewController,
                            animated: Bool,
                            completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in
            completion()
        }
    }

}
