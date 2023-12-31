//
//  Navigator+showTemporaryOrPush.swift
//  LarkNavigator
//
//  Created by Yaoguoguo on 2023/6/25.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LKCommonsLogging
import LarkTab
import LarkQuickLaunchInterface
import LarkNavigator
import LarkSetting
import SuiteAppConfig
import LarkTraitCollection

extension Navigatable {
    private func isNaviCompact(from: UIViewController) -> Bool {
        var isCollapsed: Bool = false
            
        if let trait = from.fromViewController?.rootWindow()?.traitCollection ,
            let size = from.fromViewController?.rootWindow()?.bounds.size {
           let newtrait = TraitCollectionKit.customTraitCollection(trait, size)
           isCollapsed = newtrait.horizontalSizeClass == .compact
        }
        
        return isCollapsed
       
    }
    
    // ipad: 有弹窗，先dismiss, 然后showDetail
    // iphone 走push
    public func showTemporary(
        _ viewController: UIViewController,
        other type: NavigatorType = .push,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        prepare: ((UIViewController) -> Void)? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Completion? = nil) {

        func open() {
            switch type {
            case .present:
                self.present(viewController,
                             wrap: wrap,
                             from: from,
                             prepare: prepare,
                             animated: animated,
                             completion: completion)
            case .showDetail:
                self.showDetailOrPush(viewController,
                                      context: context,
                                      wrap: wrap,
                                      from: from,
                                      animated: animated,
                                      completion: completion)
            case .unknow, .push, .didAppear:
                self.push(viewController,
                          from: from,
                          animated: animated,
                          completion: completion)
            }
        }
        

        let isCollapsed = isNaviCompact(from: from)
        let isTemporaryEnable = !AppConfigManager.shared.leanModeIsOn && Display.pad
        if isTemporaryEnable, let vc = viewController as? TabContainable {
            if isCollapsed {
                SuspendManager.shared.addTemporaryTab(vc: vc)
                open()
            } else {
                SuspendManager.shared.showTemporaryTab(vc: vc)
            }
            completion?()
        } else {
            open()
        }
    }

    public func showTemporary<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        other type: NavigatorType = .push,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        prepare: ((UIViewController) -> Void)? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        func open() {
            switch type {
            case .present:
                self.present(body: body,
                             naviParams: naviParams,
                             context: context,
                             wrap: wrap,
                             from: from,
                             prepare: prepare,
                             animated: animated,
                             completion: completion)
            case .showDetail:
                self.showDetailOrPush(body: body,
                                      naviParams: naviParams,
                                      context: context,
                                      wrap: wrap,
                                      from: from,
                                      animated: animated,
                                      completion: completion)
            case .unknow, .push, .didAppear:
                self.push(body: body,
                          naviParams: naviParams,
                          context: context,
                          from: from,
                          animated: animated,
                          completion: completion)
            }
        }

        let isCollapsed = isNaviCompact(from: from)
        
        let isTemporaryEnable = !AppConfigManager.shared.leanModeIsOn && Display.pad
        if isTemporaryEnable, isCollapsed {
        self.getResource(body: body, context: context) { (resource) in
                guard let targetViewController = resource as? TabContainable else {
                    open()
                    return
                }
                if isCollapsed {
                    SuspendManager.shared.addTemporaryTab(vc: targetViewController)
                    open()
                } else {
                    SuspendManager.shared.showTemporaryTab(vc: targetViewController)
                }
            }
        } else {
            open()
        }
    }

    public func showTemporary(
        _ url: URL,
        other type: NavigatorType = .push,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        prepare: ((UIViewController) -> Void)? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {

        func open() {
            switch type {
            case .present:
                self.present(url,
                             context: context,
                             wrap: wrap,
                             from: from,
                             prepare: prepare,
                             animated: animated,
                             completion: completion)
            case .showDetail:
                self.showDetailOrPush(url,
                                      context: context,
                                      wrap: wrap,
                                      from: from,
                                      animated: animated,
                                      completion: completion)
            case .unknow, .push, .didAppear:
                self.push(url,
                          context: context,
                          from: from,
                          animated: animated,
                          completion: completion)
            }
        }

        let isCollapsed = isNaviCompact(from: from)
            
        let isTemporaryEnable = !AppConfigManager.shared.leanModeIsOn && Display.pad
        if isTemporaryEnable, !isCollapsed {
            self.getResource(url, context: context) { (resource) in
                guard let targetViewController = resource as? TabContainable else {
                    open()
                    return
                }
                if isCollapsed {
                    SuspendManager.shared.addTemporaryTab(vc: targetViewController)
                    open()
                } else {
                    SuspendManager.shared.showTemporaryTab(vc: targetViewController)
                }
            }
        } else {
            open()
        }
    }
}
