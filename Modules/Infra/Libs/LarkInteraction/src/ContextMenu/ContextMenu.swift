//
//  ContextMenu.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/20.
//

import UIKit
import Foundation

public struct ContextMenu {

    public var identifier: NSCopying?
    public var previewVC: (() -> UIViewController?)?
    public var menuGroup: ([MenuElement]) -> MenuGroup?

    public init(menu: @escaping ([MenuElement]) -> MenuGroup?) {
        self.menuGroup = menu
    }

    @available(iOS 13.0, *)
    var config: UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(
            identifier: identifier,
            previewProvider: previewVC) { (uiElements) -> UIMenu? in
            let elements = uiElements.map { MenuProxy(element: $0) }
            return self.menuGroup(elements)?.uiMenu()
        }
    }
}

/// 与系统 UIMenuElement 进行映射的数据结构
public protocol MenuElement {
    var title: String { get }
    var image: UIImage? { get }

    @available(iOS 13.0, *)
    func uiElement() -> UIMenuElement
}

/// 对 UIMenu 相关数据结构的封装
public struct MenuElementType {
    /// UIMenuElement.State
    public enum State: Int {
        case off = 0
        case on = 1
        case mixed = 2

        @available(iOS 13.0, *)
        var uiState: UIMenuElement.State {
            switch self {
            case .off:
                return UIMenuElement.State.off
            case .on:
                return UIMenuElement.State.on
            case .mixed:
                return UIMenuElement.State.mixed
            }
        }
    }

    /// UIMenuElement.Attributes
    public struct Attributes: OptionSet {
        public var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        @available(iOS 13.0, *)
        var uiAttributes: UIMenuElement.Attributes {
            return .init(rawValue: self.rawValue)
        }

        public static var disabled: Attributes {
            var value: UInt = 0
            if #available(iOS 13.0, *) {
                value = UIMenuElement.Attributes.disabled.rawValue
            }
            return Attributes(rawValue: value)
        }

        public static var destructive: Attributes {
            var value: UInt = 0
            if #available(iOS 13.0, *) {
                value = UIMenuElement.Attributes.destructive.rawValue
            }
            return Attributes(rawValue: value)
        }

        public static var hidden: Attributes {
            var value: UInt = 0
            if #available(iOS 13.0, *) {
                value = UIMenuElement.Attributes.hidden.rawValue
            }
            return Attributes(rawValue: value)
        }
    }

    /// UIMenu.Options
    public struct MenuOptions: OptionSet {

        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        @available(iOS 13.0, *)
        var uiOptions: UIMenu.Options {
            return .init(rawValue: self.rawValue)
        }

        public static var displayInline: MenuOptions {
            var value: UInt = 0
            if #available(iOS 13.0, *) {
                value = UIMenu.Options.displayInline.rawValue
            }
            return MenuOptions(rawValue: value)
        }

        public static var destructive: MenuOptions {
            var value: UInt = 0
            if #available(iOS 13.0, *) {
                value = UIMenu.Options.destructive.rawValue
            }
            return MenuOptions(rawValue: value)
        }
    }
}

/// MenuProxy 用于转发封装 UIMenuElement
@available(iOS 13.0, *)
public struct MenuProxy: MenuElement {

    public var title: String { originElement.title }
    public var image: UIImage? { originElement.image }

    private var originElement: UIMenuElement

    public init(element: UIMenuElement) {
        self.originElement = element
    }

    public func uiElement() -> UIMenuElement {
        return originElement
    }
}

/// UIAction 的映射
public struct MenuAction: MenuElement {
    public var title: String

    public var image: UIImage?

    public var identifier: String?

    public var discoverabilityTitle: String?

    public var handler: () -> Void

    public var state: MenuElementType.State = .off

    public var attributes: MenuElementType.Attributes = []

    public init(
        title: String,
        image: UIImage? = nil,
        discoverabilityTitle: String? = nil,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.image = image
        self.discoverabilityTitle = discoverabilityTitle
        self.handler = handler
    }

    @available(iOS 13.0, *)
    public func uiElement() -> UIMenuElement {
        var actionID: UIAction.Identifier?
        if let identifier = self.identifier {
            actionID = UIAction.Identifier(rawValue: identifier)
        }
        let handler = self.handler
        return UIAction(
            title: title,
            image: image,
            identifier: actionID,
            discoverabilityTitle: self.discoverabilityTitle,
            attributes: self.attributes.uiAttributes,
            state: self.state.uiState
        ) { (_) in
            handler()
        }
    }
}

/// UIMenu 的映射
public struct MenuGroup: MenuElement {
    public var title: String

    public var image: UIImage?

    public var identifier: String?

    public var options: MenuElementType.MenuOptions = []

    public var children: [MenuElement]

    @available(iOS 13.0, *)
    public func uiElement() -> UIMenuElement {
        return self.uiMenu()
    }

    public init(title: String, image: UIImage?, children: [MenuElement]) {
        self.title = title
        self.image = image
        self.children = children
    }

    @available(iOS 13.0, *)
    func uiMenu() -> UIMenu {
        var menuID: UIMenu.Identifier?
        if let identifier = self.identifier {
            menuID = UIMenu.Identifier(rawValue: identifier)
        }

        return UIMenu(
            title: self.title,
            image: self.image,
            identifier: menuID,
            options: self.options.uiOptions,
            children: self.children.map { $0.uiElement() }
        )
    }
}
