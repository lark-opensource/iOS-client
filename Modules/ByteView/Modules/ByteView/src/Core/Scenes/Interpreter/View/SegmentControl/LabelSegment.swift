//
//  LabelSegment.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI

class LabelSegment: InterpreterChannelSegment {
    private struct DefaultValues {
        static let normalBackgroundColor: UIColor = .clear
        static let normalTextColor: UIColor = UIColor.ud.textTitle
        static let normalFont: UIFont = .systemFont(ofSize: 16)
        static let selectedBackgroundColor: UIColor = .clear
        static let selectedTextColor: UIColor = UIColor.ud.vcTokenVCBtnTextSelected
        static let selectedFont: UIFont = .systemFont(ofSize: 16)
        static let normalIconColor: UIColor = UIColor.ud.iconN3
        static let selectIconColor: UIColor = UIColor.ud.primaryContentDefault
        static let iconTextColor: UIColor = UIColor.ud.primaryOnPrimaryFill
    }

    let text: String?

    let normalFont: UIFont
    let normalTextColor: UIColor
    let normalBackgroundColor: UIColor

    let selectedFont: UIFont
    let selectedTextColor: UIColor
    let selectedBackgroundColor: UIColor

    let iconLanguage: LanguageType
    let iconTextColor: UIColor
    let normalIconColor: UIColor
    let selectIconColor: UIColor

    private let numberOfLines: Int
    private let accessibilityIdentifier: String?

    init(text: String?, numberOfLines: Int = 1, iconLanguage: LanguageType? = nil) {
        self.text = text
        self.numberOfLines = numberOfLines
        self.iconLanguage = iconLanguage ?? LanguageType.main
        self.normalBackgroundColor = DefaultValues.normalBackgroundColor
        self.normalFont = DefaultValues.normalFont
        self.normalTextColor = DefaultValues.normalTextColor
        self.selectedBackgroundColor = DefaultValues.selectedBackgroundColor
        self.selectedFont = DefaultValues.selectedFont
        self.selectedTextColor = DefaultValues.selectedTextColor
        self.iconTextColor = DefaultValues.iconTextColor
        self.normalIconColor = DefaultValues.normalIconColor
        self.selectIconColor = DefaultValues.selectIconColor
        self.accessibilityIdentifier = nil
    }

    var intrinsicContentSize: CGSize? {
        return selectedView.intrinsicContentSize
    }

    lazy var normalViewWithLabel: UIView = {
        SegmentView(withText: text,
                    numberOfLines: numberOfLines,
                    backgroundColor: normalBackgroundColor,
                    font: normalFont,
                    textColor: normalTextColor,
                    accessibilityIdentifier: accessibilityIdentifier,
                    iconLanguage: iconLanguage,
                    iconTextColor: iconTextColor,
                    iconBackgroundColor: normalIconColor)
    }()
    lazy var selectedViewWithLabel: UIView = {
        SegmentView(withText: text,
                    numberOfLines: numberOfLines,
                    backgroundColor: selectedBackgroundColor,
                    font: normalFont,
                    textColor: selectedTextColor,
                    accessibilityIdentifier: accessibilityIdentifier,
                    iconLanguage: iconLanguage,
                    iconTextColor: iconTextColor,
                    iconBackgroundColor: selectIconColor)
    }()

    lazy var normalViewWithoutLabel: UIView = {
        SegmentViewIconOnly(languageType: iconLanguage, textColor: iconTextColor, backgroundColor: normalIconColor)
    }()

    lazy var selectedViewWithoutLabel: UIView = {
        SegmentViewIconOnly(languageType: iconLanguage, textColor: iconTextColor, backgroundColor: selectIconColor)
    }()

    var normalView: UIView {
        VCScene.isPhoneLandscape ? normalViewWithoutLabel : normalViewWithLabel
    }

    var selectedView: UIView {
        VCScene.isPhoneLandscape ? selectedViewWithoutLabel : selectedViewWithLabel
    }
}

class SegmentViewIconOnly: UIView {
    static var padding: CGFloat {
        VCScene.isPhoneLandscape ? 6 : 12
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: SegmentView.Layout.iconSize.width + Self.padding * 2,
            height: SegmentView.Layout.iconSize.height + Self.padding * 2
        )
    }

    init(languageType: LanguageType, textColor: UIColor, backgroundColor: UIColor) {
        super.init(frame: .zero)
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.image = LanguageIconManager.get(
            by: languageType,
            foregroundColor: textColor,
            backgroundColor: backgroundColor)

        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Self.padding)
            $0.size.equalTo(SegmentView.Layout.iconSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SegmentView: UIView {

    enum Layout {
        static let VGap: CGFloat = 9
        static let HGap: CGFloat = 12
        static let iconMarginLabel: CGFloat = 4
        static var iconSize: CGSize {
            VCScene.isPhoneLandscape ? CGSize(width: 22, height: 22) : CGSize(width: 20, height: 20)
        }
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }()

    lazy var icon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    override var intrinsicContentSize: CGSize {
        let width = Layout.HGap + Layout.iconSize.width + Layout.iconMarginLabel + label.intrinsicContentSize.width + Layout.HGap
        let height = Layout.VGap + Layout.iconSize.height + Layout.VGap
        return CGSize(width: width, height: height)
    }

    init(withText text: String?,
         numberOfLines: Int,
         backgroundColor: UIColor,
         font: UIFont,
         textColor: UIColor,
         accessibilityIdentifier: String?,
         iconLanguage: LanguageType,
         iconTextColor: UIColor,
         iconBackgroundColor: UIColor) {
        super.init(frame: .zero)

        self.icon.image = LanguageIconManager.get(by: iconLanguage,
                                                  foregroundColor: iconTextColor,
                                                  backgroundColor: iconBackgroundColor)
        self.addSubview(self.icon)
        self.icon.snp.makeConstraints { (maker) in
            maker.left.equalTo(Layout.HGap)
            maker.size.equalTo(Layout.iconSize)
            maker.centerY.equalToSuperview()
        }

        self.label.text = text
        self.label.numberOfLines = numberOfLines
        self.label.backgroundColor = backgroundColor
        self.label.font = font
        self.label.textColor = textColor
        self.label.accessibilityIdentifier = accessibilityIdentifier

        self.addSubview(self.label)
        self.label.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.icon.snp.centerY)
            maker.left.equalTo(self.icon.snp.right).offset(Layout.iconMarginLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LabelSegment {
    static func segments(withTitles titles: [[String: LanguageType]]) -> [InterpreterChannelSegment] {
        titles.map {
            let titleDict: [String: LanguageType] = $0
            let title = titleDict.keys.first
            let iconLanguage = titleDict[title ?? ""]
            return LabelSegment(text: title, iconLanguage: iconLanguage)
        }
    }
}
