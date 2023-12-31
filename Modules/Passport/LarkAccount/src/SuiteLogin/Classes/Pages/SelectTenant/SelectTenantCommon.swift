//
//  SelectTenantCommon.swift
//  AnimatedTabBar
//
//  Created by Miaoqi Wang on 2020/1/5.
//

import Foundation
import UniverseDesignColor

enum SelectTenantLayoutConst {
    // title should align table cell but cell has shadow about 4 dp
    static let titleHorizonalAdjust: CGFloat = 4
    static let designedCellHeight: CGFloat = 84
    static let designedTableFooterHeight: CGFloat = 40

    static let estimateTableHeaderHeight: CGFloat = 40
    static let enableLabelInitWidth = 56
}

protocol V3SelectTenantCellProtocol {
    func updateSelection(_ selected: Bool)
}

class InsetLabel: UILabel {

    enum Style {
        case blue
        case white
        case gray
        case red
    }

    func setStyle(_ style: Style) {
        switch style {
        case .blue:
            backgroundColor = UIColor.ud.primaryContentDefault
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = .white
            layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        case .white:
            backgroundColor = .white
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = UIColor.ud.primaryContentDefault
            layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        case .gray:
            backgroundColor = UIColor.ud.textPlaceholder
            font = UIFont.systemFont(ofSize: Layout.disableTagFontSize, weight: .medium)
            textColor = .white
            layer.ud.setBorderColor(UIColor.ud.textPlaceholder)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 4, left: Layout.tagPadding / 2, bottom: Layout.tagPadding / 4, right: Layout.tagPadding / 2)
        case .red:
            backgroundColor = UIColor.ud.functionDangerFillSolid02
            font = UIFont.systemFont(ofSize: Layout.disableTagFontSize, weight: .medium)
            textColor = UIColor.ud.functionDangerContentDefault
            layer.ud.setBorderColor(UIColor.ud.functionDangerFillSolid02)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 4, left: Layout.tagPadding / 2, bottom: Layout.tagPadding / 4, right: Layout.tagPadding / 2)
        }
    }

    var style: Style

    override var isEnabled: Bool {
        didSet {
            assertionFailure("do not use this, will have unexpected result")
        }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        clipsToBounds = true
        layer.cornerRadius = Common.Layer.commonTagRadius
        layer.borderWidth = 1
        textAlignment = .center
        setStyle(style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var contentInset: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += contentInset.top + contentInset.bottom
        contentSize.width += contentInset.left + contentInset.right
        return contentSize
    }

    enum Layout {
        static let tagFontSize: CGFloat = 14
        static let disableTagFontSize: CGFloat = 10
        static let tagPadding: CGFloat = 8
    }

    static func estimateWidth(forText text: String, inSize: CGSize) -> CGSize {
        let label = InsetLabel(style: .blue)
        label.text = text
        let size = label.sizeThatFits(inSize)
        return CGSize(width: size.width + label.contentInset.left + label.contentInset.right,
                      height: size.height + label.contentInset.top + label.contentInset.bottom)
    }
}

class TagInsetLabel: UILabel {

    enum Style {
        case blue
        case purple
        case gray
        case red
    }

    func setStyle(_ style: Style) {
        switch style {
        case .blue:
            backgroundColor = UIColor.ud.B100
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = UIColor.ud.B600
            layer.ud.setBorderColor(UIColor.ud.B100)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        case .purple:
            backgroundColor = UIColor.ud.I100
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = UIColor.ud.I600
            layer.ud.setBorderColor(UIColor.ud.I100)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        case .gray:
            backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = UIColor.ud.N600
            layer.ud.setBorderColor(UIColor.clear)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        case .red:
            backgroundColor = UIColor.ud.R100
            font = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            textColor = UIColor.ud.R600
            layer.ud.setBorderColor(UIColor.ud.R100)
            contentInset = UIEdgeInsets(top: Layout.tagPadding / 2, left: Layout.tagPadding, bottom: Layout.tagPadding / 2, right: Layout.tagPadding)
        }
    }

    var style: Style

    override var isEnabled: Bool {
        didSet {
            assertionFailure("do not use this, will have unexpected result")
        }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        clipsToBounds = true
        layer.cornerRadius = Common.Layer.commonTagRadius
        layer.borderWidth = 1
        textAlignment = .center
        setStyle(style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var contentInset: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += contentInset.top + contentInset.bottom
        contentSize.width += contentInset.left + contentInset.right
        return contentSize
    }

    enum Layout {
        static let tagFontSize: CGFloat = 12
        static let tagPadding: CGFloat = 4
    }

}
