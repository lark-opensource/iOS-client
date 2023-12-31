//
//  ByteViewDialogConfig.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/17.
//

import Foundation
import ByteViewCommon
import RichLabel
import UniverseDesignDialog

final public class ByteViewDialogConfig {

    public enum ButtonsAxis {
        case normal
        case horizontal
        case vertical
    }

    public struct AlertColors: Equatable {
        public var background: UIColor
        public var title: UIColor
        public var content: UIColor
        public var buttonTitle: UIColor
        public var buttonSpecialTitle: UIColor
        public var buttonBackground: UIColor
        public var line: UIColor
    }

    public enum TitlePosition {
        case left, center, right
    }

    public enum ColorTheme {
        case followSystem
        case handsUpConfirm
        case redLight
        case tendencyConfirm
        case firstButtonBlue
        case rightGreen

        public static var defaultTheme: ColorTheme = .followSystem
    }

    public typealias CountDownUpdator = (UInt) -> String?
    public typealias EnableUpdator = (((Bool) -> Void)?) -> Void

    public enum RightType {
        case normal
        case countDown(time: TimeInterval)
        case autoCountDown(duration: UInt, updator: CountDownUpdator)
        case enableIf(_ updator: EnableUpdator)
    }

    public struct CheckboxConfiguration {
        let content: String
        let isChecked: Bool
        let affectLastButtonEnabled: Bool
        let itemImageSize: CGSize

        public init(content: String,
                    isChecked: Bool = false,
                    affectLastButtonEnabled: Bool = false,
                    itemImageSize: CGSize = CGSize(width: 24.0, height: 24.0)) {
            self.content = content
            self.isChecked = isChecked
            self.affectLastButtonEnabled = affectLastButtonEnabled
            self.itemImageSize = itemImageSize
        }
    }

    public struct ChoiceConfiguration {
        var items: [AnyChoiceItem]
        var itemImageSize: CGSize
        var itemSpacing: CGFloat
        /// 相对 contentView 底部的距离
        var topPadding: CGFloat
        // disable-lint: magic number
        public init(items: [AnyChoiceItem] = [],
                    itemImageSize: CGSize = CGSize(width: 20.0, height: 20.0),
                    itemSpacing: CGFloat = 18.0,
                    topPadding: CGFloat = 20.0) {
            self.items = items
            self.itemImageSize = itemImageSize
            self.itemSpacing = itemSpacing
            self.topPadding = topPadding
        }
        // enable-lint: magic number
    }

    public enum Content {
        case none
        case message(String?)
        case view(UIView)
        case linkText(LinkText, NSTextAlignment, ((Int, LinkComponent) -> Void))
    }

    public enum AdditionalContent {
        case none
        case checkbox(CheckboxConfiguration)
        case choice(ChoiceConfiguration)
    }

    struct ShowConfig {
        var id: ByteViewDialogIdentifier?
        var manualDismiss: Bool = false
        var level: CGFloat = 1
        var needAutoDismiss: Bool = false
        var inVcScene: Bool = true
    }

    var colorTheme: ColorTheme = .followSystem
    var titlePosition: TitlePosition = .center
    var buttonsAxis: ButtonsAxis = .normal
    var contentHeight: CGFloat?
    var adaptsLandscapeLayout = false

    var showConfig: ShowConfig = ShowConfig()
    var checkboxConfig: CheckboxConfiguration?
    var choiceConfig: ChoiceConfiguration?

    var udConfig: UDDialogUIConfig {
        let colors = colorTheme.colors
        return .init(
            cornerRadius: 8,
            titleColor: colors.title,
            titleAlignment: titlePosition.alignment,
            titleNumberOfLines: 0,
            style: buttonsAxis.udStyle,
            contentMargin: .zero,
            splitLineColor: colors.line,
            backgroundColor: colors.background
        )
    }
}

extension ByteViewDialogConfig.ColorTheme {
    typealias AlertColors = ByteViewDialogConfig.AlertColors
    var colors: ByteViewDialogConfig.AlertColors {
        switch self {
        case .followSystem:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.textTitle,
                               buttonSpecialTitle: UIColor.ud.primaryContentDefault,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        case .tendencyConfirm:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.functionDangerContentDefault,
                               buttonSpecialTitle: UIColor.ud.primaryContentDefault,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        case .handsUpConfirm:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.textTitle,
                               buttonSpecialTitle: UIColor.ud.textTitle,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        case .redLight:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.textTitle,
                               buttonSpecialTitle: UIColor.ud.functionDangerContentDefault,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        case .firstButtonBlue:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.primaryContentDefault,
                               buttonSpecialTitle: UIColor.ud.textTitle,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        case .rightGreen:
            return AlertColors(background: UIColor.ud.bgFloat,
                               title: UIColor.ud.textTitle,
                               content: UIColor.ud.textTitle,
                               buttonTitle: UIColor.ud.textTitle,
                               buttonSpecialTitle: UIColor.ud.G600,
                               buttonBackground: UIColor.ud.bgFloat,
                               line: UIColor.ud.lineDividerDefault)
        }
    }
}

extension ByteViewDialogConfig.TitlePosition {
    var alignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

extension ByteViewDialogConfig.ButtonsAxis {
    var udStyle: UDDialogButtonLayoutStyle {
        switch self {
        case .normal: return .normal
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }
}

extension ByteViewDialogConfig.Content {
    var view: UIView {
        switch self {
        case .none:
            return UIView()
        case let .message(message):
            let label = UILabel()
            label.font = .systemFont(ofSize: 16)
            label.backgroundColor = .clear
            label.textColor = .clear
            label.text = message
            if let message = message {
                label.attributedText = NSAttributedString(string: message, config: .body, alignment: .center)
            }
            label.numberOfLines = 0
            label.textAlignment = .center
            return label
        case let .view(view):
            return view
        case let .linkText(linkText, alignment, linkHandler):
            let label = LKLabel()
            label.numberOfLines = 0
            label.backgroundColor = .clear
            let linkFont = VCFontConfig.hAssist.font
            for (index, component) in linkText.components.enumerated() {
                var link = LKTextLink(range: component.range,
                                      type: .link,
                                      attributes: [.foregroundColor: UIColor.ud.primaryContentDefault,
                                                   .font: linkFont],
                                      activeAttributes: [:])
                link.linkTapBlock = { (_, _) in
                    linkHandler(index, component)
                }
                label.addLKTextLink(link: link)
            }
            label.attributedText = NSAttributedString(string: linkText.result, config: .body,
                                                      alignment: alignment, lineBreakMode: .byWordWrapping)
            return label
        }
    }
}
