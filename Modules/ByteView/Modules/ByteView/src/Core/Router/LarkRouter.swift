//
//  LarkRouter.swift
//  ByteView
//
//  Created by kiri on 2021/3/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewNetwork
import ByteViewUI
import UniverseDesignToast

final class LarkRouter {
    private let dependency: RouteDependency
    init(dependency: RouteDependency) {
        self.dependency = dependency
    }

    func openURL(_ url: URL, from: UIViewController? = nil) {
        if let from = from {
            dependency.openURL(url, from: from)
        } else {
            activeWithTopMost { (vc) in
                self.dependency.openURL(url, from: vc)
            }
        }
    }

    func gotoUpgrade(from: UIViewController? = nil) {
        if let from = from {
            dependency.gotoUpgrade(from: from)
        } else {
            activeWithTopMost { (vc) in
                self.dependency.gotoUpgrade(from: vc)
            }
        }
    }

    func launchCustomerService() {
        self.dependency.launchCustomerService()
    }

    func gotoCustomer() {
        activeWithTopMost { vc in
            self.dependency.gotoCustomer(from: vc)
        }
    }

    func goto(scheme: String) {
        guard let url = URL(string: scheme) else { return }
        push(url)
    }

    func gotoDocs(urlString: String, context: [String: Any], from: UIViewController? = nil) {
        if let from = from {
            dependency.gotoDocs(urlString: urlString, context: context, from: from)
            return
        }
        activeWithTopMost { (vc) in
            self.dependency.gotoDocs(urlString: urlString, context: context, from: vc)
        }
    }

    func gotoChat(body: ChatBody, completion: ((UIViewController, Int) -> Void)? = nil) {
        activeWithTopMost { (vc) in
            let window = vc.view.window
            self.dependency.gotoChat(body: body, fromGetter: {
                if let root = window?.rootViewController {
                    return root.vc.topMost
                } else {
                    return vc
                }
            }, completion: completion)
        }
    }

    func gotoUserProfile(userId: String, meetingTopic: String, sponsorName: String, sponsorId: String, meetingId: String, from: UIViewController? = nil) {
        if let vc = from {
            self.dependency.gotoUserProfile(userId: userId, meetingTopic: meetingTopic, sponsorName: sponsorName,
                                            sponsorId: sponsorId, meetingId: meetingId, from: vc)
        } else {
            activeWithTopMost { (vc) in
                self.dependency.gotoUserProfile(userId: userId, meetingTopic: meetingTopic, sponsorName: sponsorName,
                                                sponsorId: sponsorId, meetingId: meetingId, from: vc)
            }
        }
    }

    func gotoGeneralSettings(source: String) {
        activeWithTopMost { (vc) in
            self.dependency.gotoGeneralSettings(source: source, from: vc)
        }
    }

    func gotoChatterPicker(_ msg: String, displayStatus: Int, disableUserKey: String?, disableGroupKey: String?, customView: UIView?, pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?, defaultSelectedMembers: [LivePermissionMember]?, from: UIViewController? = nil) {
        if let from = from {
            dependency.gotoChatterPicker(msg, displayStatus: displayStatus, disableUserKey: disableUserKey, disableGroupKey: disableGroupKey, customView: customView, pickedConfirmCallBack: pickedConfirmCallBack, defaultSelectedMembers: defaultSelectedMembers, from: from)
        } else {
            activeWithTopMost { (vc) in
                self.dependency.gotoChatterPicker(msg, displayStatus: displayStatus, disableUserKey: disableUserKey, disableGroupKey: disableGroupKey, customView: customView, pickedConfirmCallBack: pickedConfirmCallBack, defaultSelectedMembers: defaultSelectedMembers, from: vc)
            }
        }
    }

    func present(_ viewController: UIViewController, animated: Bool = true) {
        activeWithTopMost { vc in
            vc.vc.safePresent(viewController, animated: animated, completion: nil)
        }
    }

    func push(_ vc: UIViewController, animated: Bool = true) {
        activeWithTopMost { topMost in
            if let nav = (topMost as? UINavigationController) ?? topMost.navigationController {
                nav.pushViewController(vc, animated: animated)
            }
        }
    }

    func push(_ url: URL, context: [String: Any] = [:], forcePush: Bool = false, animated: Bool = true,
              completion: ((Bool, Error?) -> Void)? = nil) {
        activeWithTopMost { topMost in
            if topMost.presentingViewController != nil {
                topMost.dismiss(animated: false) {
                    self.push(url, context: context, forcePush: forcePush, animated: animated, completion: completion)
                }
            } else {
                self.dependency.push(url, context: context, from: topMost, forcePush: forcePush, animated: animated, completion: completion)
            }
        }
    }

    func showDetailOrPush(_ url: URL,
                          context: [String: Any] = [:],
                          animated: Bool = true,
                          completion: ((Bool, Error?) -> Void)? = nil) {
        activeWithTopMost { topMost in
            if topMost.presentingViewController != nil {
                topMost.dismiss(animated: false) {
                    self.showDetailOrPush(url, context: context, animated: animated, completion: completion)
                }
            } else {
                self.dependency.showDetailOrPush(url, context: context, from: topMost, animated: animated, completion: completion)
            }
        }
    }

    func canOpen(_ url: URL, context: [String: Any] = [:]) -> Bool {
        return dependency.hasValidNavigableContent(for: url, context: context)
    }

    /// 显示直播认证的alert
    func gotoLiveCert(from: UIViewController, wrap: UINavigationController.Type, callback: ((Result<Void, Error>) -> Void)?) {
        dependency.gotoLiveCert(from: from, wrap: wrap, callback: callback)
    }

    func gotoRVCPage(roomId: String, meetingId: String, from: UIViewController) {
        dependency.gotoRVCPage(roomId: roomId, meetingId: meetingId, from: from)
    }

    func showImagePicker(from: UIViewController, sendButtonTitle: String?, takePhotoEnable: Bool,
                         completion: @escaping (UIViewController, PickedImage?) -> Void) {
        dependency.showImagePicker(from: from, sendButtonTitle: sendButtonTitle, takePhotoEnable: takePhotoEnable, completion: completion)
    }

    func presentOrPushViewController(_ vc: UIViewController, from: UIViewController? = nil,
                                     style: UIModalPresentationStyle, withWrap: Bool = false) {
        if let from = from {
            dependency.presentOrPushViewController(vc, from: from, style: style, withWrap: withWrap)
        } else {
            activeWithTopMost { fromVC in
                self.dependency.presentOrPushViewController(vc, from: fromVC, style: style, withWrap: withWrap)
            }
        }
    }

    func activeWithTopMost(function: String = #function, success: @escaping (UIViewController) -> Void) {
        activeLarkWindow(function: function, success: { (window) in
            if let vc = window.rootViewController?.vc.topMost {
                success(vc)
            } else {
                Logger.ui.warn("cannot find lark topMost, \(function) ignored")
            }
        })
    }

    func showLoading(with text: String = "", disableUserInteraction: Bool = true, on view: UIView? = nil) -> LarkToast {
        let holder = LarkToast()
        Util.runInMainThread { [weak self] in
            if let v = view {
                if !holder.isRemoved {
                    holder.hud = UDToast.showLoading(with: text, on: v, disableUserInteraction: disableUserInteraction)
                }
            } else {
                self?.activeLarkWindow { (window) in
                    if !holder.isRemoved {
                        holder.hud = UDToast.showLoading(with: text, on: window, disableUserInteraction: disableUserInteraction)
                    }
                }
            }
        }
        return holder
    }

    func showToast(with text: String = "", toastType: UDToastType = .info, disableUserInteraction: Bool = true, delay: TimeInterval = 3, on view: UIView? = nil) -> LarkToast {
        let holder = LarkToast()
        let config = UDToastConfig(toastType: toastType, text: text, operation: nil, delay: delay)
        Util.runInMainThread { [weak self] in
            if let v = view {
                if !holder.isRemoved {
                    holder.hud = UDToast.showToast(with: config, on: v, disableUserInteraction: disableUserInteraction)
                }
            } else {
                self?.activeLarkWindow { (window) in
                    if !holder.isRemoved {
                        holder.hud = UDToast.showToast(with: config, on: window, disableUserInteraction: disableUserInteraction)
                    }
                }
            }
        }
        return holder
    }


    private func activeLarkWindow(function: String = #function, success: @escaping (UIWindow) -> Void) {
        let failure: (Error?) -> Void = {
            Logger.ui.warn("cannot find lark window, \(function) ignored, error = \(String(describing: $0))")
        }

        if VCScene.isAuxSceneOpen {
            openMainScene { (w, error) in
                if let window = w {
                    success(window)
                } else {
                    failure(error)
                }
            }
        } else if let window = self.dependency.mainSceneWindow {
            success(window)
        } else {
            failure(nil)
        }
    }

    private func openMainScene(completion: ((UIWindow?, Error?) -> Void)? = nil) {
        Util.runInMainThread {
            VCScene.openScene(info: .main, completion: completion)
        }
    }
}

final class LarkToast {
    fileprivate init() {}
    fileprivate weak var hud: UDToast?
    fileprivate var isRemoved = false
    func remove() {
        isRemoved = true
        Util.runInMainThread { [weak hud] in
            hud?.remove()
        }
    }
}
