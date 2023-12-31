//
//  UIViewController+SplitViewController.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/8/30.
//

import UIKit
import Foundation

public class LKSplitViewControllerChildrenIdentifier: Equatable {
    public static func == (lhs: LKSplitViewControllerChildrenIdentifier, rhs: LKSplitViewControllerChildrenIdentifier) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public class Identifier: OptionSet {
        public let rawValue: Int

        public static let undefined = Identifier([]) // unknown

        public static let initial = primary // 初始化传入的

        public static let primary = Identifier(rawValue: 1 << 0) // master

        public static let secondary = Identifier(rawValue: 1 << 1) // detail

        /**
         A tag that represents the vc is begin transfered internally.

         Your controllers may be invoked `didMove(toParent:)` when split view controller perform
         merge and split operations internally.
         When this happens, the tag will exist and you can access it to see if it is in this state.
         */
        public static let isTransfering = Identifier(rawValue: 1 << 2)

        required public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    private var identifier: Identifier

    public weak var splitViewController: SplitViewController?

    required public init(rawValue: Int) {
        self.identifier = Identifier(rawValue: rawValue)
    }

    public init(identifier: Identifier) {
        self.identifier = identifier
    }

    public func contains(_ identifier: Identifier) -> Bool {
        return self.identifier.contains(identifier)
    }

    @discardableResult
    public func insert(_ identifier: Identifier) -> (inserted: Bool, memberAfterInsert: Identifier) {
        return self.identifier.insert(identifier)
    }

    @discardableResult
    public func remove(_ identifier: Identifier) -> Identifier? {
        return self.identifier.remove(identifier)
    }
}

extension UIViewController {

    private struct AssociatedKeys {
        static var childrenId = "childrenIdentifier"
        static var customChildrenId = "customChildrenIdentifier"
        static var masterMask = "masterMaskView"
        static var detailMask = "detailMaskView"

        static var lkSupportSecondaryOnly = "Lark.Support.VC.Full.In.Detail.Tag"
        static var lkSupportSecondaryPanGesture = "Lark.Support.VC.Full.Gesture.In.Detail.Tag"
        static var lkSupportSidePanGesture = "Lark.Support.VC.Side.Gesture.In.Detail.Tag"
        static var lkAutoAddFullScreenItem = "Lark.Auto.Add.Full.Item.Tag"
        static var lkFullScreenItem = "Lark.Full.Screen.Item.Tag"
        static var lkSplitAutoBackItem = "Lark.Split.Auto.Back.Item.Tag"
        static var lkSplitAutoSpaceItem = "Lark.Split.Auto.Space.Item.Tag"
        static var lkSplitVcDisplayModeTag = "Lark.Split.Display.Mode.Tag"
        static var lkFullScreenScene = "Lark.VC.Full.Screen.Scene.Tag"
        static var lkKeyCommandToFullScreen = "Lark.KeyCommand.Full.Screen"
        static var lkSupportSecondaryOnlyButton = "Lark.Support.Secondary.Only.Button"
        static var lkSecondaryOnlyButtonItem = "Lark.Secondary.Only.Button.Item"
        static var lkSplitNewVcDisplayModeTag = "Lark.Split.New.Display.Mode.Tag"
    }

    /**
     * LKSplitViewController专用, 不要乱用
     */
    public var childrenIdentifier: LKSplitViewControllerChildrenIdentifier {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.childrenId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.childrenId) as?
            LKSplitViewControllerChildrenIdentifier ?? LKSplitViewControllerChildrenIdentifier(identifier: .undefined)
        }
    }

    /**
     * LKSplitViewController专用, 不要乱用
     */
    public var customChildrenIdentifier: LKSplitViewControllerChildrenIdentifier? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.customChildrenId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.customChildrenId) as?
                LKSplitViewControllerChildrenIdentifier ?? nil
        }
    }

    /// 抽象SplitVC，非继承于UISplitViewController的，包括LKSplitViewController、SKSplitViewController(SpaceKit)、etc..
    public var larkSplitViewController: SplitViewController? {
        if let splitVC = self as? SplitViewController {
            return splitVC
        }
        return parent?.larkSplitViewController
    }

    /// 是否支持当前页面在 SplitDetail 中展示为全屏
    public var supportSecondaryOnly: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryOnly
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryOnly,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 是否支持当前页面在 SplitDetail 中使用快捷键全屏
    public var keyCommandToFullScreen: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkKeyCommandToFullScreen
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkKeyCommandToFullScreen,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 是否支持当前页面在 SplitDetail 中拖拽能力
    public var supportSecondaryPanGesture: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryPanGesture
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryPanGesture,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 是否支持当前页面在 SplitDetail 中拖拽能力
    public var supportSidePanGesture: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSidePanGesture
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSidePanGesture,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 自动添加的 back 按钮
    public var autoBackBarButtonItem: AutoBackBarButtonItem {
        if let item = objc_getAssociatedObject(self, &AssociatedKeys.lkSplitAutoBackItem) as? AutoBackBarButtonItem {
            return item
        }
        let item = AutoBackBarButtonItem(vc: self)
        objc_setAssociatedObject(self, &AssociatedKeys.lkSplitAutoBackItem, item, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return item
    }

    /// 自动添加的 space 按钮
    var autoBackSpaceItem: UIBarButtonItem {
        if let item = objc_getAssociatedObject(self, &AssociatedKeys.lkSplitAutoSpaceItem) as? UIBarButtonItem {
            return item
        }
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = 18
        objc_setAssociatedObject(self, &AssociatedKeys.lkSplitAutoSpaceItem, item, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return item
    }

    /// 是否支持当前页面在 SplitDetail 中展示为全屏
    public var autoAddSecondaryOnlyItem: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkAutoAddFullScreenItem) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkAutoAddFullScreenItem,
                newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 记录上一次 split 的展示 mode
    var splitSplitMode: SplitViewController.SplitMode? {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkSplitNewVcDisplayModeTag
            ) as? SplitViewController.SplitMode
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkSplitNewVcDisplayModeTag,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 是否支持当前页面在 Secondary 视图中加入按钮
    public var supportSecondaryOnlyButton: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryOnlyButton
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkSupportSecondaryOnlyButton,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 全屏展开关闭按钮
    public var secondaryOnlyButtonItem: SecondaryOnlyButtonItem {
        if let item = objc_getAssociatedObject(self, &AssociatedKeys.lkSecondaryOnlyButtonItem) as? SecondaryOnlyButtonItem {
            return item
        }
        let item = SecondaryOnlyButtonItem(vc: self)
        objc_setAssociatedObject(self, &AssociatedKeys.lkSecondaryOnlyButtonItem, item, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return item
    }

    /// 设置当前 vc 全屏展开 scene
    public var fullScreenSceneBlock: (() -> String?)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkFullScreenScene) as? () -> String?
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkFullScreenScene,
                newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    public func addChild(_ vc: UIViewController, inContainer view: UIView) {
        addChild(vc)
        vc.beginAppearanceTransition(true, animated: false)
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        vc.didMove(toParent: self)
        vc.endAppearanceTransition()
    }

    public func removeSelfFromParentVC() {
        view.removeFromSuperview()
        removeFromParent()
    }
}
