//
//  SKWebViewActionHelper.swift
//  SKUIKit
//
//  Created by chensi(陈思) on 2022/3/22.
//  


import WebKit
import SKFoundation
import LarkEMM

// _UIEditMenuInteractionMenuController
private let menuSenderClass = "X1VJRWRpdE1lbnVJbnRlcmFjdGlvbk1lbnVDb250cm9sbGVy".fromBase64()

// MARK: - Can Perform Action处理逻辑
protocol _ActionHelperActionDelegate: AnyObject {

    func canPerformUndefinedAction(_ action: Selector, withSender sender: Any?) -> Bool

    func canSuperPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
}

public final class SKWebViewActionHelper {

    weak var delegate: _ActionHelperActionDelegate?

    private var _canPerformActions: [Selector: Bool] = [:]

    private var _menuSAToCAMapping: [String: String] = {
        var menus = ["_lookup:": "LOOK_UP"]
        if #available(iOS 16.0, *) {
            menus["_define:"] = "LOOK_UP"
        }
        return menus
    }()

    private var _menuSAToCAKeys: Set<String> {
        return Set<String>(_menuSAToCAMapping.keys)
    }

    private var _menuSAtoCAValues: Set<String> {
        return Set<String>(_menuSAToCAMapping.values)
    }
    
    private var menuLinkMapping: [String: String] = [
        "CUT": "CUT_LINK",
        "COPY": "COPY_LINK",
        "PASTE": "PASTE_ON_LINK"
    ]
    
    private var isLink: Bool {
        //根据前端设置的action项判断当前为超链接选区
        return _canPerformActions.keys.description.contains("OPEN_LINK") && _canPerformActions.keys.description.contains("EDIT_LINK")
    }

    private var _menuCAtoSAMapping: [String: String] = [
        "select:": "SELECT",
        "selectAll:": "SELECT_ALL",
        "cut:": "CUT",
        "copy:": "COPY",
        "paste:": "PASTE"
    ]

    private var _menuCAtoSAKeys: Set<String> {
        return Set<String>(_menuCAtoSAMapping.keys)
    }

    private var _menuCAtoSAValues: Set<String> {
        return Set<String>(_menuCAtoSAMapping.values)
    }

    private var _menuSAValues: Set<String> {
        if CCMKeyValue.globalUserDefault.bool(forKey: SKUIKitConfig.shared.kGrammarCheckEnabled) {
            return ["replace:"]
        } else {
            return []
        }
    }

    // swiftlint:enable identifier_name

    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        let isMenuSender: Bool
        
        if SKDisplay.pad,
           let sender,
           String(describing: type(of: sender)) == "UIKeyCommand",
           _menuCAtoSAKeys.contains(action.description) {
            //复制、剪切快捷键不应该由气泡菜单接口设置的菜单项控制
            return allowShowAction(action.description) && delegate?.canSuperPerformAction(action, withSender: sender) ?? false
        }
        
        // iOS16气泡菜单为新控件，sender有两种类型
        if #available(iOS 16, *) {
            let senderClass = NSStringFromClass(type(of: sender as AnyObject))
            isMenuSender = (sender is UICommand || senderClass == menuSenderClass)
            
        } else {
            isMenuSender = sender is UIMenuController
        }
        
        if isMenuSender {
            return _decideActionsForMenuSender(action, withSender: sender)  && allowShowAction(action.description)
        } else {
            return _decideActionsForOtherSender(action, withSender: sender) && allowShowAction(action.description)
        }
    }

    func setCanPerformActions(_ canPerformActions: [Selector: Bool]) {
        self._canPerformActions = canPerformActions
    }
    
    private func allowShowAction(_ action: String) -> Bool {
        // FG 开强制隐藏，FG 关时看安全内部的判断
        guard let actionsDescrition = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable) else {
            return true
        }
        let containAction = actionsDescrition.contains(action)
        DocsLogger.info("DocsWebViewActionHelper allowShowAcion: action: \(action.description), result: \(containAction)")
        return containAction
    }

    private func _decideActionsForMenuSender(_ action: Selector, withSender sender: Any?) -> Bool {
        let selStr = action.description
        if _menuSAToCAKeys.contains(selStr) {
            let customSelStr = _menuSAToCAMapping[selStr] ?? "null"
            var canPerform = false
            _canPerformActions.forEach {
                if $0.description == customSelStr {
                    canPerform = $1; return
                }
            }
            return canPerform
        } else if _menuSAtoCAValues.contains(selStr) {
            return false
        } else if _menuCAtoSAKeys.contains(selStr) {
            return false
        } else if _menuCAtoSAValues.contains(selStr) {
            return _canPerformActions[action] == true
        } else if _menuSAValues.contains(selStr) {
            return true
        }
        return _canPerformActions[action] == true
    }

    private func _decideActionsForOtherSender(_ action: Selector, withSender sender: Any?) -> Bool {
        let selStr = action.description
        if _menuCAtoSAKeys.contains(selStr) {
            let customSelStr = _menuCAtoSAMapping[selStr] ?? "null"
            //linkSelStr的作用是将COPY、CUT转为COPY_LINK、CUT_LINK，保证超链接选区时快捷键可用
            let linkSelStr = menuLinkMapping[customSelStr] ?? "null"
            if isLink, linkSelStr == "PASTE_ON_LINK" {
                //超链接选区时前端不会设置粘贴的菜单项，会导致快捷cmd+v粘贴不可用，这里特殊判断下
                return delegate?.canPerformUndefinedAction(action, withSender: sender) ?? false
            }
            var canPerform = false
            _canPerformActions.forEach { if $0.description == customSelStr || $0.description == linkSelStr { canPerform = $1; return } }
            return canPerform
        }
        return delegate?.canPerformUndefinedAction(action, withSender: sender) ?? false
    }
}

@objc public protocol EditorViewGestureDelegate {

    func onLongPress(editorView: UIView?, gestureRecognizer: UIGestureRecognizer)

    func onSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer)

    func onPan(editorView: UIView?, gestureRecognizer: UIPanGestureRecognizer)

    func canStartSlideToSelect(by panGestureRecognizer: UIPanGestureRecognizer) -> Bool
}
