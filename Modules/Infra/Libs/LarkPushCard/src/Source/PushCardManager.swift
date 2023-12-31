//
//  PushCardManager.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKWindowManager
import EENavigator

final class PushCardManager: PushCardCenterService {

    var window: PushCardWindow?

    static var shared: PushCardManager = PushCardManager()

    private static let logger = Logger.log(PushCardManager.self, category: "PushCardManager")

    private init() {
        LKWindowManager.shared.registerWindow(PushCardWindow.self)
    }

    func post(_ model: Cardable) {
        PushCardManager.shared.post([model])
    }

    func post(_ models: [Cardable]) {
        guard !models.isEmpty else { return }
        StaticFunc.execInMainThread({
            self.createWindowAndVisible()
            self.window?.pushCardController.post(models)
        })
    }

    func remove(with id: String, changeToStack: Bool = false) {
        guard !id.isEmpty else { return }
        StaticFunc.execInMainThread({
            self.createWindowAndVisible()
            self.window?.pushCardController.remove(with: id, changeToStack: changeToStack)
        })
    }

    func removeAll() {
        Self.logger.info("LarkPushCard removeAll, window is Hidden")
        self.window?.isHidden = true
        self.window?.removeFromSuperview()
        self.window = nil
    }

    func update(with id: String) {
        guard !id.isEmpty else { return }
        StaticFunc.execInMainThread({
            self.createWindowAndVisible()
            self.window?.pushCardController.update(with: id)
        })
    }

    private func createWindowAndVisible() {
        if self.window == nil {
            if #available(iOS 13.0, *) {
                self.setupPushCardWindowByConnectScene()
            } else {
                self.setupPushCardWindowByApplicationDelegate()
            }
        }

        guard let window = self.window else { return }
        window.resetConstraints()

        if window.isHidden {
            window.isHidden = false
        }
    }

    @available(iOS 13.0, *)
    private func setupPushCardWindowByConnectScene() {
        if let windowScene = UIApplication.shared.windowApplicationScenes.first as? UIWindowScene,
           let rootWindow = Utility.rootWindowForScene(scene: windowScene) {
            self.window = self.createPushCardWindow(window: rootWindow)
        }
    }

    private func setupPushCardWindowByApplicationDelegate() {
        guard let delegate = UIApplication.shared.delegate,
              let weakWindow = delegate.window,
              let rootWindow = weakWindow else {
            return
        }
        self.window = self.createPushCardWindow(window: rootWindow)
    }

    private func createPushCardWindow(window: UIWindow) -> PushCardWindow {
        let pushWindow = LKWindowManager.shared.createLKWindow(byID: .PushCardWindow, isVirtual: true)
        if #available(iOS 13.0, *) {
            pushWindow?.windowScene = window.windowScene
        }
        return pushWindow as? PushCardWindow ?? PushCardWindow()
    }

    static func calculateCustomViewSize(model: Cardable?) -> CGSize {
        guard let customView = model?.customView else { return .zero }
        if let height = model?.calculateCardHeight(with: Cons.cardWidth), height > 0 {
            return CGSize(width: Cons.cardWidth, height: ceil(height))
        } else {
            customView.snp.makeConstraints { make in
                make.width.equalTo(Cons.cardWidth)
            }
            customView.layoutIfNeeded()
            let size = customView.systemLayoutSizeFitting(CGSize(width: Cons.cardWidth,
                                                                 height: UIView.layoutFittingCompressedSize.height),
                                                          withHorizontalFittingPriority: .fittingSizeLevel,
                                                          verticalFittingPriority: .defaultLow)
            return CGSize(width: Cons.cardWidth, height: ceil(size.height))
        }
    }
}
