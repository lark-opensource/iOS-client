//
//  LarkWindowDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSuspendable
import ByteView
import ByteViewCommon
import LarkContainer
import RxSwift
#if LarkMod
import LarkWaterMark
#endif

class LarkWindowDependency: WindowDependency {
    private static let logger = Logger.getLogger("Window")
    var lastSize: CGSize = .zero
    let key = "byteview_key"
    let disposeBag = DisposeBag()
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 是否使用外部window
    var isExternalWindowEnabled: Bool {
        return SuspendManager.isFloatingEnabled
    }

    // 获取外部window的展示位置
    func getTargetOrigin(with size: CGSize) -> CGPoint {
        guard isExternalWindowEnabled else {
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
        guard isExternalWindowEnabled else {
            return .zero
        }
        let frame = SuspendManager.shared.customFrame(forKey: key) ?? .zero
        Self.logger.info("getTargetFrame:\(frame)")
        return frame
    }

    // 把VC移交给外部window
    func addViewController(with vc: UIViewController, size: CGSize) {
        guard isExternalWindowEnabled else {
            return
        }
        lastSize = size
        if vc.parent != nil {
            vc.willMove(toParent: nil)
            vc.removeFromParent()
            vc.beginAppearanceTransition(false, animated: false)
        }
        SuspendManager.shared.removeCustomView(forKey: key)
        SuspendManager.shared.addCustomViewController(vc, size: size, forKey: key)
        #if LarkMod
        if let service = try? userResolver.resolve(assert: WaterMarkService.self) {
            service.darkModeWaterMarkView.take(1).subscribe(onNext: { view in
                Util.runInMainThread {
                    SuspendManager.shared.updateWatermark(view)
                }
            }).disposed(by: disposeBag)
        }
        #endif
        Self.logger.info("addViewController:\(vc) size:\(size)")
    }

    // 替换外部window的VC
    func replaceViewController(with vc: UIViewController) {
        guard isExternalWindowEnabled else {
            return
        }

        let size = SuspendManager.shared.customFrame(forKey: key)?.size ?? lastSize
        let previousVC = SuspendManager.shared.removeCustomViewController(forKey: key)
        SuspendManager.shared.addCustomViewController(vc, size: size, forKey: key)
        Self.logger.info("replaceViewController:\(vc) size:\(size), previousVC:\(String(describing: previousVC))")
    }

    // 从外部window移除并获取移交的VC
    func removeViewController() -> UIViewController? {
        guard isExternalWindowEnabled else {
            return nil
        }
        _ = removeView()
        let vc = SuspendManager.shared.removeCustomViewController(forKey: key)
        if let viewController = vc,
           viewController.parent != nil {
            viewController.willMove(toParent: nil)
            viewController.removeFromParent()
            viewController.beginAppearanceTransition(false, animated: false)
        }
        SuspendManager.shared.removeWatermark()
        Self.logger.info("removeViewController:\(String(describing: vc))")
        return vc
    }

    func addView(with view: UIView, size: CGSize) {
        guard isExternalWindowEnabled else {
            return
        }
        return SuspendManager.shared.addCustomView(view, size: size, forKey: key)
    }

    func removeView() -> UIView? {
        guard isExternalWindowEnabled else {
            return nil
        }
        return SuspendManager.shared.removeCustomView(forKey: key)
    }

    // 小窗的时候更新一下支持的方向
    public func updateSupportedInterfaceOrientations() {
        #if swift(>=5.7)
        if #available(iOS 16.0, *), Display.phone {
            SuspendManager.shared.suspendWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        #endif
    }
}
