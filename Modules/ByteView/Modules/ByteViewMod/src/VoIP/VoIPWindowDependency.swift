//
//  WindowDependencyImpl.swift
//  LarkVoIP
//
//  Created by Prontera on 2021/1/21.
//

import Foundation
import LarkVoIP
#if LarkMod
import LKCommonsLogging
import LarkSuspendable

final class VoIPWindowDependency: WindowDependency {

    var lastSize: CGSize = .zero
    let key = "byteview_voip_key"
    static private let logger = Logger.log(VoIPWindowDependency.self, category: "VoIPWindowDependency")

    // 是否使用外部window
    var externalWindowEnable: Bool {
        return SuspendManager.isFloatingEnabled
    }

    // 获取外部window的展示位置
    func getTargetOrigin(with size: CGSize) -> CGPoint {
        guard externalWindowEnable else {
            return .zero
        }
        lastSize = size
        let emptyView = UIView()
        SuspendManager.shared.addCustomView(emptyView, size: size, forKey: key)
        SuspendManager.shared.suspendWindow?.layoutIfNeeded()
        let origin = SuspendManager.shared.customFrame(forKey: key)?.origin ?? .zero
        Self.logger.info("getTargetOrigin:\(origin)")
        return origin
    }

    // 获取外部window的展示区域
    func getTargetFrame() -> CGRect {
        guard externalWindowEnable else {
            return .zero
        }
        let frame = SuspendManager.shared.customFrame(forKey: key) ?? .zero
        Self.logger.info("getTargetFrame:\(frame)")
        return frame
    }

    // 把VC移交给外部window
    func addViewController(with vc: UIViewController, size: CGSize) {
        guard externalWindowEnable else {
            return
        }
        lastSize = size
        SuspendManager.shared.removeCustomView(forKey: key)
        SuspendManager.shared.addCustomViewController(vc, size: size, forKey: key)
        Self.logger.info("addViewController:\(vc) size:\(size)")
    }

    // 替换外部window的VC
    func replaceViewController(with vc: UIViewController) {
        guard externalWindowEnable else {
            return
        }

        let size = SuspendManager.shared.customFrame(forKey: key)?.size ?? lastSize
        let previousVC = SuspendManager.shared.removeCustomViewController(forKey: key)
        SuspendManager.shared.addCustomViewController(vc, size: size, forKey: key)
        Self.logger.info("replaceViewController:\(vc) size:\(size), previousVC:\(String(describing: previousVC))")
    }

    // 从外部window移除并获取移交的VC
    func removeViewController() -> UIViewController? {
        guard externalWindowEnable else {
            return nil
        }
        let vc = SuspendManager.shared.removeCustomViewController(forKey: key)
        Self.logger.info("removeViewController:\(String(describing: vc))")
        return vc
    }

    func addView(with view: UIView, size: CGSize) {
        guard externalWindowEnable else {
            return
        }
        return SuspendManager.shared.addCustomView(view, size: size, forKey: key)
    }

    func removeView() -> UIView? {
        guard externalWindowEnable else {
            return nil
        }
        return SuspendManager.shared.removeCustomView(forKey: key)
    }
}

#else

final class DefaultVoIPWindowDependency: WindowDependency {
    // 是否使用外部window
    var externalWindowEnable: Bool {
        return false
    }

    // 获取外部window的展示位置
    func getTargetOrigin(with size: CGSize) -> CGPoint {
        .zero
    }

    // 获取外部window的展示区域
    func getTargetFrame() -> CGRect {
        .zero
    }

    // 把VC移交给外部window
    func addViewController(with vc: UIViewController, size: CGSize) {
    }

    // 替换外部window的VC
    func replaceViewController(with vc: UIViewController) {
    }

    // 从外部window移除并获取移交的VC
    func removeViewController() -> UIViewController? {
        nil
    }

    func addView(with view: UIView, size: CGSize) {
    }

    func removeView() -> UIView? {
        nil
    }
}

#endif
