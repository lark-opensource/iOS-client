//
//  File.swift
//  LKWindowManager
//
//  Created by 白镜吾 on 2022/10/27.
//

import Foundation
import UIKit
import UniverseDesignTheme
import LarkExtensions

extension UIWindow {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NotificationCenter.default.post(name: LKWindow.didHitNotification, object: nil)
        return super.hitTest(point, with: event)
    }
}

extension LKWindow {
    public static let didHitNotification: NSNotification.Name = NSNotification.Name("LKWindowDidHitNotificationName")
}

open class LKWindow: LKBaseWindow, LKWindowProtocol {

    open class func canCreate(by config: LKWindowConfig) -> Bool {
        return false
    }

    open class func create(by config: LKWindowConfig) -> LKWindow? {
        let window = LKWindow()
        window.identifier = config.identifier.rawValue
        window.windowIdentifier = window.identifier
        window.windowLevel = config.level
        return window
    }

    open var identifier: String = ""

    open private(set) var virtualKeyWindow: LKVirtualWindow?

    private var didActivateNotiObject: NSObjectProtocol?
    private var didDisconnectNotiObject: NSObjectProtocol?
    private var didEnterBackgroundNotiObject: NSObjectProtocol?
    private var didBecomeActiveNotiObject: NSObjectProtocol?

    private var virtualWindowMap: [UIWindow.Level: [LKVirtualWindow]] = [:]

    open var isAutoRelease: Bool {
        return true
    }

    open override var rootViewController: UIViewController? {
        didSet {
            rootViewController?.view.backgroundColor = .clear
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            self.windowScene = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene
            self.observeSceneNotification()
        }
        Utility.execOnlyUnderIOS16 {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.observeKeyWindowDidChangeNotification),
                                                   name: UIWindow.didBecomeKeyNotification,
                                                   object: nil)
        }

        self.backgroundColor = .clear
    }

    @available(iOS 13.0, *)
    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        self.observeSceneNotification()
        Utility.execOnlyUnderIOS16 {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.observeKeyWindowDidChangeNotification),
                                                   name: UIWindow.didBecomeKeyNotification,
                                                   object: nil)
        }

        self.backgroundColor = .clear
        self.rootViewController?.view.backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else {
            return nil
        }
        // 点击位置必须在视图区域内，否则返回 nil
        guard self.point(inside: point, with: event) else {
            return nil
        }
        // 倒序遍历子视图
        for subview in subviews.reversed() {
            let insidePoint = convert(point, to: subview)
            // iPad rootViewController view的superview不是window ，会相应hittest。
            if let hitView = subview.hitTest(insidePoint, with: event),
               hitView != self.rootViewController?.view.superview {
                return hitView
            }
        }
        return nil
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.virtualWindowMap.values.forEach { windows in
            windows.forEach { window in
                window.frame = self.bounds
            }
        }
    }

    @objc
    private func observeKeyWindowDidChangeNotification() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        guard let keyWindow = UIApplication.shared.keyWindow else { return }

        guard let kwSupportedInterfaceOrientations = keyWindow.rootViewController?.supportedInterfaceOrientations else { return }

        guard kwSupportedInterfaceOrientations == .portrait else { return }
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        self.didActivateNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                DispatchQueue.main.async {
                    guard let scene = noti.object as? UIWindowScene else {
                        return
                    }
                    if self?.windowScene?.activationState != .foregroundActive {
                        self?.windowScene = scene
                    }
                }
            }

        self.didDisconnectNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                DispatchQueue.main.async {
                    guard let scene = noti.object as? UIWindowScene else {
                        return
                    }
                    if self?.windowScene == scene {
                        self?.windowScene = Utility.findForegroundActiveScene()
                    }
                }
            }

        self.didEnterBackgroundNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didEnterBackgroundNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                DispatchQueue.main.async {
                    guard let scene = noti.object as? UIWindowScene else {
                        return
                    }
                    if self?.windowScene == scene {
                        self?.windowScene = Utility.findForegroundActiveScene()
                    }
                }
            }

        self.didBecomeActiveNotiObject = NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: nil) { [weak self] (noti) in
                        DispatchQueue.main.async {
                            self?.overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
                            self?.overrideUserInterfaceStyle = UDThemeManager.userInterfaceStyle
                        }
                    }
    }

    open func addVirtualWindow(_ window: LKVirtualWindow) {
        window.setSuperWindow(self)
        
        if let virtualWindows = self.virtualWindowMap[window.windowLevel], !virtualWindows.isEmpty {
            var newVirtualWindows = virtualWindows
            newVirtualWindows.append(window)
            if let last = virtualWindows.last {
                self.insertSubview(window, aboveSubview: last)
            }
            self.virtualWindowMap[window.windowLevel] = newVirtualWindows
        } else {
            let floor = self.searchWindowLevelFloor(window.windowLevel)
            if let last = self.virtualWindowMap[floor]?.last {
                self.insertSubview(window, aboveSubview: last)
            } else {
                self.addSubview(window)
                self.bringSubviewToFront(window)
            }
            self.virtualWindowMap[window.windowLevel] = [window]
        }

        window.frame = self.bounds
    }

    open func addVirtualWindowVC(_ vc: UIViewController) {
        if let root = rootViewController as? LKWindowRootController {
            root.addVirtualWindowVC(vc)
        } else {
            rootViewController?.addChild(vc)
        }
    }

    open func removeVirtualWindow(_ window: LKVirtualWindow) {

        if let virtualWindows = self.virtualWindowMap[window.windowLevel] {
            var newVirtualWindows = virtualWindows
            newVirtualWindows.removeAll {
                return $0.identifier == window.identifier
            }
            if newVirtualWindows.isEmpty {
                self.virtualWindowMap.removeValue(forKey: window.windowLevel)
            } else {
                self.virtualWindowMap[window.windowLevel] = newVirtualWindows
            }
        }

        guard self.isAutoRelease, self.virtualWindowMap.isEmpty else {
            return
        }

        self.isHidden = true
        LKWindowManager.shared.remove(self)
    }

    open func makeKeyByVirtualWindow(_ window: LKVirtualWindow, isVisible: Bool = false) {
        if isVisible {
            self.makeKeyAndVisible()
            window.isHidden = false
        } else {
            self.makeKey()
        }

        virtualKeyWindow?.resignKey()
        self.virtualKeyWindow = window
    }

    open override func becomeKey() {
        super.becomeKey()

        self.virtualKeyWindow?.becomeKey()
    }

    open override func resignKey() {
        super.resignKey()

        self.virtualKeyWindow?.resignKey()
        self.virtualKeyWindow = nil
    }

    private func searchWindowLevelFloor(_ level: UIWindow.Level) -> UIWindow.Level {
        let keys = self.virtualWindowMap.keys.sorted {
            return $0 < $1
        }

        var floor = keys.first ?? self.windowLevel

        guard !keys.isEmpty else {
            return level
        }

        keys.forEach {
            guard !(virtualWindowMap[$0]?.isEmpty ?? true) else {
                return
            }

            if $0 < level, $0 > floor {
                floor = $0
            } else if $0 == level {
                floor = $0
            }
        }

        return floor
    }
}
