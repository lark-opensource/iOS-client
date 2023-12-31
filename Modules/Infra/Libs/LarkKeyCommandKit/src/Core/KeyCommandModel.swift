//
//  KeyCommandModel.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/5.
//

import UIKit
import Foundation

//swiftlint:disable missing_docs

/*
 KeyCommandBaseInfo/KeyCommandInfo 是 UIKeyCommand 的映射
 包含 command 的基础信息
 */

public class KeyCommandBaseInfo {

    public var discoverabilityTitle: String?

    public var input: String

    public var modifierFlags: UIKeyModifierFlags

    public init(
        input: String,
        modifierFlags: UIKeyModifierFlags,
        discoverabilityTitle: String? = nil) {
        self.input = input
        self.modifierFlags = modifierFlags
        self.discoverabilityTitle = discoverabilityTitle
    }

    public func keyCommand() -> UIKeyCommand {
        if let discoverabilityTitle = self.discoverabilityTitle {
            if #available(iOS 13.0, *) {
                return UIKeyCommand(
                    action: defaultSelecter,
                    input: self.input,
                    modifierFlags: self.modifierFlags,
                    discoverabilityTitle: discoverabilityTitle
                ).nonRepeating
            } else {
                return UIKeyCommand(
                    input: self.input,
                    modifierFlags: self.modifierFlags,
                    action: defaultSelecter,
                    discoverabilityTitle: discoverabilityTitle
                ).nonRepeating
            }
        } else {
            return UIKeyCommand(
                input: self.input,
                modifierFlags: self.modifierFlags,
                action: defaultSelecter
            ).nonRepeating
        }
    }
}

///
@available(iOS 13.0, *)
public final class KeyCommandInfo: KeyCommandBaseInfo {

    public var title: String = ""

    public var image: UIImage?

    public var propertyList: Any?

    public var attributes: UIMenuElement.Attributes

    public var state: UIMenuElement.State

    public var alternates: [UICommandAlternate]

    public init(
        title: String,
        image: UIImage? = nil,
        input: String,
        modifierFlags: UIKeyModifierFlags = [],
        propertyList: Any? = nil,
        alternates: [UICommandAlternate] = [],
        discoverabilityTitle: String? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off) {
        self.title = title
        self.image = image
        self.propertyList = propertyList
        self.attributes = attributes
        self.state = state
        self.alternates = alternates
        super.init(
            input: input,
            modifierFlags: modifierFlags,
            discoverabilityTitle: discoverabilityTitle
        )
    }

    public override func keyCommand() -> UIKeyCommand {
        return UIKeyCommand(
            title: self.title,
            image: self.image,
            action: defaultSelecter,
            input: self.input,
            modifierFlags: self.modifierFlags,
            propertyList: self.propertyList,
            alternates: self.alternates,
            discoverabilityTitle: self.discoverabilityTitle,
            attributes: self.attributes,
            state: self.state
        ).nonRepeating
    }
}
//swiftlint:enable missing_docs

extension KeyCommandBaseInfo: Hashable {
    public static func == (lhs: KeyCommandBaseInfo, rhs: KeyCommandBaseInfo) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(input)
        hasher.combine(modifierFlags.rawValue)
    }
}

/// 默认响应快捷键的 selector
let defaultSelecter: Selector = #selector(UIResponder.handleKeyboardCommand(_:))

extension UIResponder {
    @objc
    func handleKeyboardCommand(_ command: UIKeyCommand) {
        KeyCommandKit.shared.handle(keyCommand: command)
    }
}
