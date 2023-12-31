//
//  ByteViewDialog+Builder.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/14.
//

import Foundation
import ByteViewCommon
import RichLabel
import UIKit
import UniverseDesignDialog

extension ByteViewDialog {
    public final class Builder {

        public func show(animated: Bool = true, in vc: UIViewController? = nil, completion: ((ByteViewDialog) -> Void)? = nil) {
            Util.runInMainThread {
                self.config.build().show(animated: animated, in: vc, completion: completion)
            }
        }

        private var config: Config
        public init() {
            config = Config()
        }

        @discardableResult
        public func title(_ title: String?) -> Self {
            config.title = title
            return self
        }

        @discardableResult
        public func titlePosition(_ titlePosition: ByteViewDialogConfig.TitlePosition) -> Self {
            config.titlePosition = titlePosition
            return self
        }

        @discardableResult
        public func message(_ message: String?) -> Self {
            config.content = .message(message)
            return self
        }

        @discardableResult
        public func contentView(_ contentView: UIView) -> Self {
            config.content = .view(contentView)
            return self
        }

        @discardableResult
        public func checkbox(_ cfg: ByteViewDialogConfig.CheckboxConfiguration) -> Self {
            config.additionalContent = .checkbox(cfg)
            return self
        }

        @discardableResult
        public func choice(_ cfg: ByteViewDialogConfig.ChoiceConfiguration) -> Self {
            config.additionalContent = .choice(cfg)
            return self
        }

        @discardableResult
        public func button(_ button: UIButton) -> Self {
            config.content = .view(button)
            return self
        }

        @discardableResult
        public func linkText(_ linkText: LinkText, alignment: NSTextAlignment = .left, handler: @escaping (Int, LinkComponent) -> Void) -> Self {
            config.content = .linkText(linkText, alignment, handler)
            return self
        }

        @discardableResult
        public func contentHeight(_ contentHeight: CGFloat?) -> Self {
            config.contentHeight = contentHeight
            return self
        }

        /// 特化横屏布局（固定宽度）
        @discardableResult
        public func adaptsLandscapeLayout(_ adaptsLandscapeLayout: Bool) -> Self {
            config.adaptsLandscapeLayout = adaptsLandscapeLayout
            return self
        }

        @discardableResult
        public func colorTheme(_ colorTheme: ByteViewDialogConfig.ColorTheme?) -> Self {
            if let colorTheme = colorTheme {
                config.colorTheme = colorTheme
            }
            return self
        }

        @discardableResult
        public func buttonsAxis(_ buttonsAxis: ByteViewDialogConfig.ButtonsAxis) -> Self {
            config.buttonsAxis = buttonsAxis
            return self
        }

        @discardableResult
        public func leftTitle(_ leftTitle: String?) -> Self {
            config.leftTitle = leftTitle
            return self
        }

        @discardableResult
        public func leftHandler(_ leftHandler: ((ByteViewDialog) -> Void)?) -> Self {
            config.leftHandler = leftHandler
            return self
        }

        @discardableResult
        public func rightTitle(_ rightTitle: String?) -> Self {
            config.rightTitle = rightTitle
            return self
        }

        @discardableResult
        public func rightHandler(_ rightHandler: ((ByteViewDialog) -> Void)?) -> Self {
            config.rightHandler = rightHandler
            return self
        }

        /// 右边按钮的特殊逻辑（倒计时、禁用等）
        @discardableResult
        public func rightType(_ rightType: ByteViewDialogConfig.RightType?) -> Self {
            config.rightType = rightType
            return self
        }

        /// 控制会议结束后自动消失
        @discardableResult
        public func needAutoDismiss(_ needAutoDismiss: Bool) -> Self {
            config.needAutoDismiss = needAutoDismiss
            return self
        }

        @discardableResult
        public func inVcScene(_ inVcScene: Bool) -> Self {
            config.inVcScene = inVcScene
            return self
        }

        /// 控制点击按钮后是否弹窗消失
        @discardableResult
        public func manualDismiss(_ manualDismiss: Bool) -> Self {
            config.manualDismiss = manualDismiss
            return self
        }

        /// dialog 标记
        @discardableResult
        public func id(_ id: ByteViewDialogIdentifier) -> Self {
            config.id = id
            return self
        }

        /// 控制 window 层级（Alert 基础上）
        @discardableResult
        public func level(_ level: CGFloat) -> Self {
            config.level = level
            return self
        }
    }

    private struct Config {
        var id: ByteViewDialogIdentifier?
        var title: String?
        var content: ByteViewDialogConfig.Content = .none
        var additionalContent: ByteViewDialogConfig.AdditionalContent = .none
        var titlePosition: ByteViewDialogConfig.TitlePosition = .center
        var contentHeight: CGFloat?
        var adaptsLandscapeLayout: Bool = false
        var colorTheme: ByteViewDialogConfig.ColorTheme = .followSystem
        var buttonsAxis: ByteViewDialogConfig.ButtonsAxis = .normal
        var leftTitle: String?
        var leftHandler: ((ByteViewDialog) -> Void)?
        var rightTitle: String?
        var rightHandler: ((ByteViewDialog) -> Void)?
        var rightType: ByteViewDialogConfig.RightType?
        var needAutoDismiss: Bool = false
        var inVcScene: Bool = true
        var manualDismiss: Bool = false
        var level: CGFloat = 1

        func build() -> ByteViewDialog {
            let config = ByteViewDialogConfig()

            config.titlePosition = titlePosition
            config.buttonsAxis = buttonsAxis
            config.colorTheme = colorTheme
            config.contentHeight = contentHeight
            config.adaptsLandscapeLayout = adaptsLandscapeLayout

            config.showConfig.id = id
            config.showConfig.level = level
            config.showConfig.needAutoDismiss = needAutoDismiss
            config.showConfig.inVcScene = inVcScene
            config.showConfig.level = level

            switch additionalContent {
            case .none:
                break
            case .checkbox(let checkboxConfig):
                config.checkboxConfig = checkboxConfig
            case .choice(let choiceConfig):
                config.choiceConfig = choiceConfig
            }

            let dialog = ByteViewDialog(configuration: config)
            if let title = title {
                dialog.setTitle(text: title)
            }
            dialog.setContent(content: content, additionalContent: additionalContent)
            if let title = leftTitle {
                dialog.addButton(title: title, handler: { [weak dialog] in
                    guard let dialog = dialog else { return }
                    leftHandler?(dialog)
                    if !manualDismiss {
                        dialog.dismiss()
                    }
                })
            }
            if let title = rightTitle {
                dialog.addButton(title: title, isSpecial: true, handler: { [weak dialog] in
                    guard let dialog = dialog else { return }
                    rightHandler?(dialog)
                    if !manualDismiss {
                        dialog.dismiss()
                    }
                })
                if let rightType = rightType, case let .countDown(time) = rightType {
                    dialog.setupRightButtonCountDown(originTitle: title, time: time)
                } else if let rightType = rightType, case let .autoCountDown(duration, updator) = rightType {
                    dialog.setupRightButtonCountDown(duration: duration, updator: updator)
                } else if let rightType = rightType, case let .enableIf(updator) = rightType {
                    dialog.setupRightButtonEnable(updator: updator)
                }
            }
            return dialog
        }
    }
}
