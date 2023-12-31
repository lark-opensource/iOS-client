//
//  UtilDocsShortcutService.swift
//  SKBrowser
//
//  Created by CJ on 2020/8/11.
//

import SKCommon
import SKFoundation

extension DocsJSService {
    /// docs_ipad快捷键
    static let setKeyboardShortcuts = DocsJSService("biz.control.setKeyboardShortcuts")
    static let updateShortcuts = DocsJSService("biz.control.updateKeyboardShortcuts")
}

class UtilDocsShortcutService: BaseJSService {}

extension UtilDocsShortcutService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.setKeyboardShortcuts, .updateShortcuts]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.setKeyboardShortcuts.rawValue:
            guard let callback = params["callback"] as? String else {
                return
            }
            model?.setDocsShortcutCallback(callback)
            self.handleShortcut(params: params)
        case DocsJSService.updateShortcuts.rawValue:
            self.handleShortcut(params: params)
        default:
            break
        }
    }
    
    private func handleShortcut(params: [String: Any]) {
        guard let shortcuts = params["shortcuts"] as? [[String: Any]] else { return }
        var keyCommandsInfo: [UIKeyCommand: String] = [:]
        shortcuts.forEach { item in
            guard let flags = item["flags"] as? [String], let input = item["input"] as? String, let id = item["id"] as? String else {
                DocsLogger.error("shortcut data error: \(item.description)")
                return
            }
            var modifierFlags: UIKeyModifierFlags = []
            for flag in flags {
                switch flag {
                case "cmd":
                    modifierFlags.insert(.command)
                case "opt":
                    modifierFlags.insert(.alternate)
                case "shift":
                    modifierFlags.insert(.shift)
                case "ctrl":
                    modifierFlags.insert(.control)
                default:
                    DocsLogger.error("unsupport shortcut flags")
                    return
                }
            }
            guard let realInput = getRealInput(from: Int(input)) else {
                DocsLogger.error("unsupport shortcut keycode: \(input)")
                return
            }
            let selector = #selector(BrowserViewController.handleShortcutCommand(_:))
            let keyCommand = UIKeyCommand(input: realInput, modifierFlags: modifierFlags, action: selector)
            keyCommandsInfo[keyCommand] = id
        }
        model?.setDocsShortcut(keyCommandsInfo)
    }
    
    private func getRealInput(from keyCode: Int?) -> String? {
        guard let keyCode else { return nil }
        switch keyCode {
        case 8: return "\u{08}"  //backSpace
        case 9: return "\u{09}"  //tab
        case 13: return "\u{0A}" //换行
        case 27: return "\u{1B}" //esc
        case 32: return "\u{20}" //空格
        case 33: return UIKeyCommand.inputPageUp
        case 34: return UIKeyCommand.inputPageDown
        case 35: return "UIKeyInputEnd"
        case 36: return "UIKeyInputHome"
        case 37: return UIKeyCommand.inputLeftArrow
        case 38: return UIKeyCommand.inputUpArrow
        case 39: return UIKeyCommand.inputRightArrow
        case 40: return UIKeyCommand.inputDownArrow
        //case 45: return "Insert"
        case 46: return "\u{7F}" //DEL
        case 48: return "0"
        case 49: return "1"
        case 50: return "2"
        case 51: return "3"
        case 52: return "4"
        case 53: return "5"
        case 54: return "6"
        case 55: return "7"
        case 56: return "8"
        case 57: return "9"
        case 65: return "A"
        case 66: return "B"
        case 67: return "C"
        case 68: return "D"
        case 69: return "E"
        case 70: return "F"
        case 71: return "G"
        case 72: return "H"
        case 73: return "I"
        case 74: return "J"
        case 75: return "K"
        case 76: return "L"
        case 77: return "M"
        case 78: return "N"
        case 79: return "O"
        case 80: return "P"
        case 81: return "Q"
        case 82: return "R"
        case 83: return "S"
        case 84: return "T"
        case 85: return "U"
        case 86: return "V"
        case 87: return "W"
        case 88: return "X"
        case 89: return "Y"
        case 90: return "Z"
        case 112: return "UIKeyInputF1"
        case 113: return "UIKeyInputF2"
        case 114: return "UIKeyInputF3"
        case 115: return "UIKeyInputF4"
        case 116: return "UIKeyInputF5"
        case 117: return "UIKeyInputF6"
        case 118: return "UIKeyInputF7"
        case 119: return "UIKeyInputF8"
        case 120: return "UIKeyInputF9"
        case 121: return "UIKeyInputF10"
        case 122: return "UIKeyInputF11"
        case 123: return "UIKeyInputF12"
        case 186: return ";"
        case 187: return "="
        case 188: return ","
        case 189: return "-"
        case 190: return "."
        case 191: return "/"
        case 192: return "`"
        case 219: return "["
        case 220: return "\u{2F}" //斜线
        case 221: return "]"
        case 222: return "'"
        default:
            return nil
        }
    }
}
