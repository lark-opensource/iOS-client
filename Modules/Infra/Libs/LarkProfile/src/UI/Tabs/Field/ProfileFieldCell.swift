//
//  ProfileFieldCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/25.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignColor
import EENavigator

public class ProfileFieldCell: BaseTableViewCell {
    
    public var navigator: EENavigator.Navigatable?

    var isVerticalLayout: Bool

    public var item: ProfileFieldItem {
        didSet {
            self.updateData()
        }
    }

    /// 上下文
    public var context: ProfileFieldContext {
        didSet {
            self.updateData()
        }
    }

    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = isVerticalLayout ? .vertical : .horizontal
        stack.alignment = .leading
        stack.spacing = Cons.titleContentSpacing
        stack.distribution = .fill
        return stack
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = Cons.titleFont
        titleLabel.textColor = Cons.titleColor
        return titleLabel
    }()

    private lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    var longPress: UILongPressGestureRecognizer?

    /// 能否处理，用于判断选择使用哪种item
    public class func canHandle(item: ProfileFieldItem) -> Bool {
        return false
    }

    required public init(item: ProfileFieldItem,
                         context: ProfileFieldContext,
                         isVertical: Bool = false) {
        self.item = item
        self.context = context
        self.isVerticalLayout = isVertical
        super.init(style: .default, reuseIdentifier: nil)
        commonInit()
        updateData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        let normalColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        self.backgroundView?.backgroundColor = normalColor
        contentView.addSubview(stackView)
        contentView.addSubview(separatorLine)
        stackView.addArrangedSubview(titleLabel)

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.bottom.equalToSuperview().offset(-Cons.vMargin)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
        }
        titleLabel.snp.makeConstraints { make in
            if !isVerticalLayout {
                make.width.equalTo(Cons.titleWidth)
            }
        }
        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandle))
        self.addGestureRecognizer(longPress)
        self.longPress = longPress
    }

    func updateData() {
        titleLabel.text = item.title
        longPress?.isEnabled = item.enableLongPress
    }

    public func didTap() { }

    public func addDividingLine() {
        separatorLine.isHidden = false
    }

    public func removeDividingLine() {
        separatorLine.isHidden = true
    }

    @objc
    public func longPressHandle() {
    }
}

extension ProfileFieldCell {

    // swiftlint:disable all
    var Cons: CommonCons.Type {
        return isVerticalLayout ? Cons4V.self : Cons4H.self
    }
    // swiftlint:enable all

    /// Common layout constants.
    class CommonCons {
        class var hMargin: CGFloat { 16 }
        class var vMargin: CGFloat { 10 }
        class var titleLineHeight: CGFloat { 18 }
        class var titleFont: UIFont { .systemFont(ofSize: 14) }
        class var titleColor: UIColor { UIColor.ud.textCaption }
        class var contentLineHeight: CGFloat { 21 }
        class var contentFont: UIFont { .systemFont(ofSize: 16) }
        class var contentColor: UIColor { UIColor.ud.textTitle }
        class var titleContentSpacing: CGFloat { 6 }
        class var titleWidth: CGFloat { 0 }
        class var arrowSize: CGFloat { 16 }
        class var arrowSpacing: CGFloat { 5 }
        class var linkColor: UIColor { UIColor.ud.textLinkNormal }
    }

    /// Vertial layout constants.
    final class Cons4V: CommonCons {}

    /// Horizontal layout constants.
    final class Cons4H: CommonCons {
        override class var vMargin: CGFloat { 18 }
        override class var titleWidth: CGFloat { 102 }
        override class var titleContentSpacing: CGFloat { 8 }
        override class var titleLineHeight: CGFloat { 18 }
        override class var titleFont: UIFont { .systemFont(ofSize: 16) }
        override class var titleColor: UIColor { UIColor.ud.textTitle }
        override class var contentLineHeight: CGFloat { 18 }
        override class var contentFont: UIFont { .systemFont(ofSize: 14) }
        override class var contentColor: UIColor { UIColor.ud.textPlaceholder }
    }
}
