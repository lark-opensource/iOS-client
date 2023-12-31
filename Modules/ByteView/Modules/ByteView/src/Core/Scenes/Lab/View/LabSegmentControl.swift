//
//  LabSegmentControl.swift
//  ByteView
//
//  Created by ZhangJi on 2022/4/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RichLabel

typealias LabSegmentControl = InterpreterChannelSegmentedControl

class LabMirrorSegment: InterpreterChannelSegment {
    static func updateSizeOf(segments: [LabMirrorSegment]) {
        var mirrorSegmentViews = [MirrorSegmentView]()
        for segment in segments {
            guard let normalView = segment.normalView as? MirrorSegmentView,
                  let selectedView = segment.selectedView as? MirrorSegmentView else { return }
            mirrorSegmentViews.append(normalView)
            mirrorSegmentViews.append(selectedView)
        }
        MirrorSegmentView.updateSizeOf(segmentViews: mirrorSegmentViews)
    }

    private struct DefaultValues {
        static let normalBackgroundColor: UIColor = .clear
        static let normalTextColor: UIColor = UIColor.ud.textCaption
        static let normalFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
        static let selectedBackgroundColor: UIColor = .clear
        static let selectedTextColor: UIColor = UIColor.ud.primaryContentDefault
        static let selectedFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
        static let normalIconColor: UIColor = UIColor.ud.iconN3
        static let selectIconColor: UIColor = UIColor.ud.primaryContentDefault
        /// 阴影用于加粗
        static let selectTextshadow: NSShadow = {
            let shadow = NSShadow()
            shadow.shadowColor = selectedTextColor
            shadow.shadowOffset = CGSize(width: 0.1, height: 0.1)
            shadow.shadowBlurRadius = 1
            return shadow
        }()
    }

    let text: String?

    let normalFont: UIFont
    let normalTextColor: UIColor
    let normalBackgroundColor: UIColor

    let selectedFont: UIFont
    let selectedTextColor: UIColor
    let selectedBackgroundColor: UIColor
    let selectedTextshadow: NSShadow?

    private let numberOfLines: Int
    private let accessibilityIdentifier: String?

    init(text: String?, numberOfLines: Int = 1) {
        self.text = text
        self.numberOfLines = numberOfLines
        self.normalBackgroundColor = DefaultValues.normalBackgroundColor
        self.normalFont = DefaultValues.normalFont
        self.normalTextColor = DefaultValues.normalTextColor
        self.selectedBackgroundColor = DefaultValues.selectedBackgroundColor
        self.selectedFont = DefaultValues.selectedFont
        self.selectedTextColor = DefaultValues.selectedTextColor
        self.selectedTextshadow = nil // DefaultValues.selectTextshadow
        self.accessibilityIdentifier = nil
    }

    var intrinsicContentSize: CGSize? {
        return selectedView.intrinsicContentSize
    }

    lazy var normalView: UIView = {
        MirrorSegmentView(withText: text,
                          numberOfLines: numberOfLines,
                          backgroundColor: normalBackgroundColor,
                          font: normalFont,
                          textColor: normalTextColor,
                          accessibilityIdentifier: accessibilityIdentifier)
    }()
    lazy var selectedView: UIView = {
        MirrorSegmentView(withText: text,
                          numberOfLines: numberOfLines,
                          backgroundColor: selectedBackgroundColor,
                          font: selectedFont,
                          textColor: selectedTextColor,
                          accessibilityIdentifier: accessibilityIdentifier,
                          shadow: selectedTextshadow)
    }()
}

class MirrorSegmentView: UIView {
    static func updateSizeOf(segmentViews: [MirrorSegmentView]) {
        var maxLabelWidth = 0.0
        for segment in segmentViews {
            maxLabelWidth = max(maxLabelWidth, segment.label.intrinsicContentSize.width)
        }
        for segment in segmentViews {
            segment.updateLabelWidth(maxLabelWidth)
        }
    }

    enum Layout {
        static let VGap: CGFloat = 4
        static let HGap: CGFloat = 8
        static let iconMarginLabel: CGFloat = 8
        static let iconSize: CGSize = CGSize(width: 20, height: 20)
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

    private let hasIcon: Bool
    private var lableWidth: CGFloat?

    override var intrinsicContentSize: CGSize {
        let labelWidth = self.lableWidth ?? label.intrinsicContentSize.width
        var width = Layout.HGap + labelWidth + Layout.HGap
        width += hasIcon ? Layout.iconSize.width + Layout.iconMarginLabel : 0
        let height = Layout.VGap + Layout.iconSize.height + Layout.VGap
        return CGSize(width: width, height: height)
    }

    init(withText text: String?,
         numberOfLines: Int,
         backgroundColor: UIColor,
         font: UIFont,
         textColor: UIColor,
         accessibilityIdentifier: String?,
         icon: UIImage? = nil,
         shadow: NSShadow? = nil) {

        self.hasIcon = icon != nil
        super.init(frame: .zero)
        self.icon.image = icon
        if self.hasIcon {
            self.addSubview(self.icon)
            self.icon.snp.makeConstraints { (maker) in
                maker.left.equalTo(Layout.HGap)
                maker.size.equalTo(Layout.iconSize)
                maker.centerY.equalToSuperview()
            }
        }

        self.label.text = text
        self.label.numberOfLines = numberOfLines
        self.label.backgroundColor = backgroundColor
        self.label.font = font
        self.label.textColor = textColor
        self.label.accessibilityIdentifier = accessibilityIdentifier
        if let text = text {
            if let shadow = shadow {
                self.label.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: textColor, .shadow: shadow])
            } else {
                self.label.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: textColor])
            }
        }

        self.addSubview(self.label)
        self.label.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            if hasIcon {
                maker.left.equalTo(self.icon.snp.right).offset(Layout.iconMarginLabel)
            } else {
                maker.left.equalTo(Layout.HGap)
            }
        }
    }

    func updateLabelWidth(_ width: CGFloat) {
        lableWidth = width
        self.label.snp.remakeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.width.equalTo(width)
            if hasIcon {
                maker.left.equalTo(self.icon.snp.right).offset(Layout.iconMarginLabel)
            } else {
                maker.left.equalTo(Layout.HGap)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
