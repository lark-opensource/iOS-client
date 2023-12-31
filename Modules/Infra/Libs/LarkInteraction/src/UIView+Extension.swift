//
//  UIViewExtension.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

private struct AssociatedKeys {
    static var lkInteractions = "Lark.Interactions.Tag"
    static var lkTableDragDelegate = "Lark.table.drag.Tag"
    static var lkTableDropDelegate = "Lark.table.drop.Tag"
    static var lkTextFieldDragDelegate = "Lark.text.field.drag.Tag"
    static var lkTextFieldDropDelegate = "Lark.text.field.drop.Tag"
    static var lkTextViewDragDelegate = "Lark.text.view.drag.Tag"
    static var lkTextViewDropDelegate = "Lark.text.view.drop.Tag"

    static var lkDragContainerProxyTag = "Lark.Interactions.Drag.Container.Proxy.Tag"

    static var lkButtonPointerStyleTag = "Lark.Interactions.Button.Pointer.Style.Tag"
}

extension UIView {
    /// 添加 Lark Interaction
    public func addLKInteraction(_ interaction: Interaction) {

        // 判断 interaction 是否支持当前平台
        guard interaction.platforms.contains(UIDevice.current.userInterfaceIdiom) else {
            return
        }

        self.isUserInteractionEnabled = true

        var lkInteractions = self.lkInteractions
        lkInteractions.append(interaction)
        self.lkInteractions = lkInteractions

        self.addInteraction(interaction.uiInteraction)
    }

    /// 删除 Lark Interaction
    public func removeLKInteraction(_ interaction: Interaction) {

        var lkInteractions = self.lkInteractions
        lkInteractions.removeAll { (lkinteraction) -> Bool in
            return lkinteraction.hash == interaction.hash
        }
        self.lkInteractions = lkInteractions

        self.removeInteraction(interaction.uiInteraction)
    }

    /// 当前 Lark Interaction
    public private(set) var lkInteractions: [Interaction] {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkInteractions) as? [Interaction] ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.lkInteractions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 当前 UIView drag container proxy
    public var dragContainerProxy: DragContainer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkDragContainerProxyTag) as? DragContainer
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkDragContainerProxyTag,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension UITableView {
    /// 设置 lark TableViewDragDelegate，强持有
    public var lkTableDragDelegate: TableViewDragDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTableDragDelegate) as? TableViewDragDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTableDragDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.dragDelegate = newValue
        }
    }
    /// 设置 lark TableViewDropDelegate，强持有
    public var lkTableDropDelegate: TableViewDropDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTableDropDelegate) as? TableViewDropDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTableDropDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.dropDelegate = newValue
        }
    }
}

extension UITextField {
    /// 设置 lark TextViewDragDelegate，强持有
    public var lkTextDragDelegate: TextViewDragDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTextFieldDragDelegate) as? TextViewDragDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTextFieldDragDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.textDragDelegate = newValue
        }
    }
    /// 设置 lark TextViewDropDelegate，强持有
    public var lkTextDropDelegate: TextViewDropDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTextFieldDropDelegate) as? TextViewDropDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTextFieldDropDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.textDropDelegate = newValue
        }
    }
}

extension UITextView {
    /// 设置 lark TextViewDragDelegate，强持有
    public var lkTextDragDelegate: TextViewDragDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTextViewDragDelegate) as? TextViewDragDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTextViewDragDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.textDragDelegate = newValue
        }
    }
    /// 设置 lark TextViewDropDelegate，强持有
    public var lkTextDropDelegate: TextViewDropDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkTextViewDropDelegate) as? TextViewDropDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkTextViewDropDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.textDropDelegate = newValue
        }
    }
}

@available(iOS 13.4, *)
extension UIButton {
    /// 设置 pointer style
    public var lkPointerStyle: PointerStyle? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.lkButtonPointerStyleTag) as? PointerStyle
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.lkButtonPointerStyleTag,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.update(pointerStyle: newValue)
        }
    }
}
