//
//  BrowserView+Navigator.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/10/31.
//  

import SKFoundation
import SKCommon
import SKUIKit
import EENavigator
import LarkUIKit

extension BrowserView: BrowserNavigator {

    public var currentBrowserVC: UIViewController? {
        return self.navigator?.currentBrowserVC(self)
    }

    public var navigatorFromVC: NavigatorFrom {
        if let from = UIViewController.docs.topMost(of: currentBrowserVC) {
            return from
        } else if let topMostVC = UIViewController.docs.topMost(of: currentBrowserVC) {
            return SKNavigationController(rootViewController: topMostVC)
        } else {
            spaceAssertionFailure("检查一下为什么会调用到这里")
            return SKNavigationController()
        }
    }

    public var preferredModalPresentationStyle: UIModalPresentationStyle {
        return isMyWindowCompactSize() ? .overCurrentContext : .popover
    }

    public var presentedVC: UIViewController? {
        return currentBrowserVC?.presentedViewController
    }

    public func presentClearViewController(_ v: UIViewController, animated: Bool) {
        v.modalPresentationStyle = .overCurrentContext
        currentBrowserVC?.present(v, animated: animated, completion: nil)
    }
    
    public func presentViewController(_ v: UIViewController, animated: Bool, completion: (() -> Void)?) {
        currentBrowserVC?.present(v, animated: animated, completion: completion)
    }

    public func dismissViewController(animated: Bool, completion: (() -> Void)?) {
        currentBrowserVC?.dismiss(animated: animated, completion: completion)
    }
    
    public func pushViewController(_ v: UIViewController) {
        currentBrowserVC?.navigationController?.pushViewController(v, animated: true)
    }

    // canEmpty: iPad 模式下是否可以pop到兜底页
    public func popViewController(canEmpty: Bool) {
        if let vc = currentBrowserVC as? BaseViewController {
            vc.back(canEmpty: canEmpty)
        } else {
            spaceAssertionFailure("currentBrowserVC is not BaseViewController")
            currentBrowserVC?.navigationController?.popViewController(animated: true)
        }
    }

    @discardableResult
    public func requiresOpen(url: URL) -> Bool {
        return navigator?.browserView(self, requiresOpen: url) ?? false
    }
    public func pageIsExistInStack(url: URL) -> Bool {
        return navigator?.pageIsExistInStack(self, url: url) ?? false
    }

    public func showUserProfile(token: String) {
        guard let currentBrowserVC = currentBrowserVC else {
            spaceAssertionFailure("currentBrowserVC cannot be nil")
            return
        }
        showUserProfileAction(token: token, vc: currentBrowserVC)
    }
    
    public func showUserList(data: [UserInfoData.UserData], title: String?) -> UIViewController? {
        guard let currentBrowserVC = currentBrowserVC else {
            spaceAssertionFailure("currentBrowserVC cannot be nil")
            return nil
        }
        
        let vc = UserInfoListViewController(data: data) { info in
            self.showUserProfileAction(token: info.userId, vc: SKDisplay.pad ? currentBrowserVC.presentedViewController! : currentBrowserVC)
        }
        vc.title = title
        vc.supportOrientations = currentBrowserVC.supportedInterfaceOrientations
        if SKDisplay.pad {
            let navVC = LkNavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .formSheet
            currentBrowserVC.present(navVC, animated: true)
        } else {
            currentBrowserVC.navigationController?.pushViewController(vc, animated: true)
        }
        return vc
    }
    
    private func showUserProfileAction(token: String, vc: UIViewController) {
        if !OperationInterceptor.interceptShowUserProfileIfNeed(token,
                                                                from: vc,
                                                                followDelegate: self.vcFollowDelegate) {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                HostAppBridge.shared.call(ShowUserProfileService(userId: token, fileName: self.docsInfo?.title, fromVC: vc))
            }
        }
    }

    public func sendLarkOpenEvent(_ event: LarkOpenEvent) {
        userResolver.docs.editorManager?.sendLarkOpenEvent(self, event: event)
    }

    public func showEnterpriseTopic(query: String,
                                    addrId: String,
                                    triggerView: UIView,
                                    triggerPoint: CGPoint,
                                    clientArgs: String,
                                    clickAction: EnterpriseTopicClickHandle?,
                                    didTapApplink: EnterpriseTopicTapApplinkHandle?,
                                    targetVC: UIViewController) {
        HostAppBridge.shared.call(EnterpriseTopicActionService(action: .show,
                                                               query: query,
                                                               addrId: addrId,
                                                               triggerView: triggerView,
                                                               triggerPoint: triggerPoint,
                                                               targetVC: targetVC,
                                                               clientArgs: clientArgs,
                                                               clickHandle: clickAction,
                                                               tapApplinkHandle: didTapApplink))
    }

    public func dismissEnterpriseTopic() {
        HostAppBridge.shared.call(EnterpriseTopicActionService(action: .dismiss))
    }
    
    public var routerParams: [String: Any]? {
        if let vc = self.currentBrowserVC as? BrowserViewController {
            return vc.fileConfig?.extraInfos
        }
        return nil
    }
}
