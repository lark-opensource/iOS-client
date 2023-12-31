//
//  BrowserViewController+Shortcut.swift
//  SKBrowser
//
//  Created by CJ on 2020/8/11.
//

import SKUIKit
import SKCommon

// 需求文档：https://bytedance.larksuite.com/docs/doccnkJy4EyQRdyEFhVjfdjwZhc
private let defaultSelecter: Selector = #selector(BrowserViewController.handleShortcutCommand(_:))

public struct DocsKeyCommandInfo {
    let flags: UIKeyModifierFlags
    let input: String
    let id: String
    init(flags: UIKeyModifierFlags, input: String, id: String) {
        self.flags = flags
        self.input = input
        self.id = id
    }
}

class DocsKeyCommands {
    
    //按顺序存储快捷键keys
    var keys: [UIKeyCommand]
    var infos: [UIKeyCommand: String]
    
    init(_ infos: [UIKeyCommand: String]) {
        self.keys = Array(infos.keys)
        self.infos = infos
    }
    
    func append(input: String, modifierFlags: UIKeyModifierFlags, id: String) {
        self.append([UIKeyCommand(input: input, modifierFlags: modifierFlags, action: defaultSelecter): id])
    }
    
    func append(_ other: [UIKeyCommand: String]) {
        infos.merge(other: other)
        keys.insert(contentsOf: other.keys, at: .zero)
    }
}

extension BrowserViewController {
    func defaultKeyCommandInfos() -> [UIKeyCommand: String] {
        guard SKDisplay.pad else {
            return [:]
        }
        var defaultKeyCommandInfos = [
            UIKeyCommand(input: "1", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h1.rawValue,
            UIKeyCommand(input: "2", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h2.rawValue,
            UIKeyCommand(input: "3", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h3.rawValue,
            UIKeyCommand(input: "4", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h4.rawValue,
            UIKeyCommand(input: "5", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h5.rawValue,
            UIKeyCommand(input: "6", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h6.rawValue,
            UIKeyCommand(input: "7", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h7.rawValue,
            UIKeyCommand(input: "8", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h8.rawValue,
            UIKeyCommand(input: "9", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.h9.rawValue,

            UIKeyCommand(input: "x", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.strikethrough.rawValue,
            UIKeyCommand(input: "7", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.orderedlist.rawValue,
            UIKeyCommand(input: "8", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.unorderedlist.rawValue,
            UIKeyCommand(input: "t", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.checkbox.rawValue,
            UIKeyCommand(input: "s", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.insertSeparator.rawValue,
            UIKeyCommand(input: "c", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.codelist.rawValue,
            UIKeyCommand(input: "l", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.alignleft.rawValue,
            UIKeyCommand(input: "r", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.alignright.rawValue,
            UIKeyCommand(input: "e", modifierFlags: [.command, .shift], action: defaultSelecter): BarButtonIdentifier.aligncenter.rawValue,
            UIKeyCommand(input: "c", modifierFlags: [.command, .control], action: defaultSelecter): BarButtonIdentifier.inlinecode.rawValue
            ]
        if let type = docsInfo?.inherentType, type == .docX {
            defaultKeyCommandInfos.merge(other: [
                UIKeyCommand(input: "\u{3e}", modifierFlags: [.command], action: defaultSelecter): BarButtonIdentifier.blockquote.rawValue,
                UIKeyCommand(input: "0", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.normalText.rawValue,
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.control, .shift], action: defaultSelecter): BarButtonIdentifier.moveUpBlock.rawValue,
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.control, .shift], action: defaultSelecter): BarButtonIdentifier.moveDownBlock.rawValue,
                UIKeyCommand(input: "A", modifierFlags: [.command], action: defaultSelecter): BarButtonIdentifier.selectAllBlock.rawValue,
                UIKeyCommand(input: "M", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.commentAction.rawValue,
                UIKeyCommand(input: "H", modifierFlags: [.command, .alternate], action: defaultSelecter): BarButtonIdentifier.textHighLight.rawValue
            ])
            if LKFeatureGating.hyperLinkEnable {
                defaultKeyCommandInfos.merge(other: [UIKeyCommand(input: "K", modifierFlags: [.command], action: defaultSelecter):
                                                    BarButtonIdentifier.hyperLink.rawValue])
            }
        }
        return defaultKeyCommandInfos
    }
}

extension BrowserViewController {
    func _handleShortcutCommand(_ command: UIKeyCommand) {
        let commandIdentifier = docsKeyCommands.infos[command] ?? ""
        let jsMethod = browerEditor?.shortcutCallback ?? ""
        if !commandIdentifier.isEmpty && !jsMethod.isEmpty {
            let params: [String: Any] = ["id": commandIdentifier]
            browerEditor?.jsEngine.callFunction(DocsJSCallBack(jsMethod), params: params, completion: nil)
        }
    }
}

extension Array where Element == UIKeyCommand {
    func process() -> Array {
        forEach { command in
            let repeatableConstant = "repeatable"
            if command.responds(to: Selector(repeatableConstant)) {
                command.setValue(false, forKey: repeatableConstant)
            }
            #if swift(>=5.5)
            if #available(iOS 15, *) {
                command.wantsPriorityOverSystemBehavior = true
            }
            #endif
        }
        return self
    }
}
