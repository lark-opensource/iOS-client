//
//  SceneButtonItem.swift
//  LarkSplitViewController
//
//  Created by 郭怡然 on 2022/11/25.
//

import UIKit
import Foundation
import LarkSceneManager
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor

public final class SceneButtonItem: UIView {
    private var button: UIButton = UIButton()
    public weak var targetVC: UIViewController? {
        didSet {
            if #available(iOS 13.0, *) {
                updateIcon()
            }
        }
    }
    private var clickCallBack: ((UIButton) -> Void)?
    private var sceneKey: String
    private var sceneId: String

    public static var tintColorEnable: Bool = false
    public static var iconTintColor: UIColor?

    public var tintColorEnable: Bool = SceneButtonItem.tintColorEnable {
        didSet {
            if #available(iOS 13.0, *) {
                self.updateIcon()
            } else {
                return
            }
        }
    }
    public var iconTintColor: UIColor? = SceneButtonItem.iconTintColor {
        didSet {
            if #available(iOS 13.0, *) {
                self.updateIcon()
            } else {
                return
            }
        }
    }

    /// - Parameters:
    ///   - targetVC:          button所在的vc
    ///   - clickCallBack:          点击 scene Button 后发生的事件
    ///   - getSceneCallBack:           传入要进行激活的 scene
    public init(clickCallBack: ((UIButton) -> Void)?, sceneKey: String, sceneId: String) {
        self.clickCallBack = clickCallBack
        self.sceneId = sceneId
        self.sceneKey = sceneKey
        super.init(frame: .zero)
        if #available(iOS 13.0, *) {
            self.addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.width.equalTo(24)
            }
            button.addTarget(self, action: #selector(SceneItemClicked), for: .touchUpInside)
            updateIcon()
            NotificationCenter.default.addObserver(self, selector: #selector(updateIcon), name: NSNotification.Name("SceneDidBecomeActiveNotificationKey"), object: nil)
        } else {
            return
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        if self.targetVC == nil {
            self.targetVC = self.findViewController()
        }
        super.didMoveToSuperview()
    }

    @objc
    func SceneItemClicked(sender: UIButton) {
        self.clickCallBack?(sender)
    }

    @available(iOS 13.0, *)
    @objc
    func updateIcon() {
        button.setImage(self.getSceneIcon(targetVC: targetVC) , for: .normal)
        let scene = LarkSceneManager.Scene(
            key: sceneKey,
            id: sceneId
        )
        button.isEnabled = self.getState(scene: scene)
        button.setImage(self.getSceneIcon(targetVC: targetVC).withTintColor(UIColor.ud.iconDisabled), for: .disabled)
    }

    @available(iOS 13.0, *)
    public func getState(scene: Scene) -> Bool {
        let uiScene = SceneManager.shared.connectedScene(scene: scene)
        let isEnabled = !(uiScene?.activationState == .foregroundActive)
        return isEnabled
    }

    @available(iOS 13.0, *)
    public func getSceneIcon(targetVC: UIViewController?) -> UIImage {
        guard #available(iOS 15.0, *) else { return UDIcon.sepwindowOutlined }
        guard let targetVC = targetVC else { return UDIcon.sepwindowOutlined }
        let currentScene = targetVC.currentScene() as? UIWindowScene

        let tintColor: UIColor
        if let iconTintColor = self.iconTintColor {
            tintColor = iconTintColor
        } else {
            tintColor = UDColor.iconN1
        }

        /// 回滚需求，为了之后可能会加回来暂时注释
//        switch currentScene?.shape {
//        case .fullScreen:
//            return UDIcon.multipleWindowsRightOutlined.withTintColor(tintColor)
//        case .slideOver(_):
//            return UDIcon.multipleWindowsRightOutlined.withTintColor(tintColor)
//        case .split(.right, _):
//            return UDIcon.multipleWindowsLeftOutlined.withTintColor(tintColor)
//        default:
//            return UDIcon.multipleWindowsRightOutlined.withTintColor(tintColor)
//        }

        return UDIcon.sepwindowOutlined.withTintColor(tintColor)

    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
