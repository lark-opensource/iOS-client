//
//  Alert.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/24.
//

import UniverseDesignActionPanel
import UniverseDesignDialog
import RxSwift
import RxCocoa

public struct Alerts {

    public static func showSheet(source: UIView, from: UIViewController?, title: String?, items: [UDActionSheetItem]) {

        let source = UDActionSheetSource(sourceView: source, sourceRect: source.bounds)
        var config = UDActionSheetUIConfig(popSource: source)
        config.isShowTitle = true
        let sheet = UDActionSheet(config: config)
        items.forEach { sheet.addItem($0) }
        sheet.setCancelItem(text: I18N.Lark_Conditions_CancelButton)
        if let aTitle = title {
            sheet.setTitle(aTitle)
        }
        from?.present(sheet, animated: true, completion: nil)
    }
    
    public struct AlertAction {
        // swiftlint:disable:next nesting
        public enum Style {
            case `default`
            case cancel
            case destructive
            case secondary
        }

        public let title: String
        public let style: Style
        public let handler: (() -> Void)?

        public init(title: String, style: Style, handler: (() -> Void)?) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }

    public static func showAlert(from: UIViewController?, title: String?, content: String?, actions: [AlertAction]) {
        let dialog = UDDialog()
        if let aTitle = title {
            dialog.setTitle(text: aTitle)
        }
        if let aContent = content {
            dialog.setContent(text: aContent)
        }
        actions.forEach { action in
            switch action.style {
            case .default:
                dialog.addPrimaryButton(text: action.title, dismissCompletion: action.handler)
            case .cancel:
                dialog.addCancelButton()
            case .secondary:
                dialog.addSecondaryButton(text: action.title, dismissCompletion: action.handler)
            case .destructive:
                dialog.addDestructiveButton(text: action.title, dismissCompletion: action.handler)
            }
        }
        from?.present(dialog, animated: true, completion: nil)
    }

    public static func showAlertAndGetSignal(from: UIViewController?, title: String?, content: String?, actions: [AlertAction]) -> Observable<UDDialog> {
        let dialog = UDDialog()
        if let aTitle = title {
            dialog.setTitle(text: aTitle)
        }
        if let aContent = content {
            dialog.setContent(text: aContent)
        }
        actions.forEach { action in
            switch action.style {
            case .default:
                dialog.addPrimaryButton(text: action.title, dismissCompletion: action.handler)
            case .cancel:
                dialog.addCancelButton()
            case .secondary:
                dialog.addSecondaryButton(text: action.title, dismissCompletion: action.handler)
            case .destructive:
                dialog.addDestructiveButton(text: action.title, dismissCompletion: action.handler)
            }
        }
        from?.present(dialog, animated: true, completion: nil)
        return .just(dialog)
    }
}
