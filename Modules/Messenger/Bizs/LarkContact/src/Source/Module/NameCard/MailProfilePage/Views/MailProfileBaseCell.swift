//
//  MailProfileBaseCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/29.
//

import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UIKit

class MailProfileBaseCell: BaseTableViewCell {

    weak var targetViewController: UIViewController?

    var item: MailProfileCellItem? {
        didSet {
            self.updateData()
        }
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = Cons.titleFont
        titleLabel.textColor = Cons.titleColor
        return titleLabel
    }()

    lazy var subTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = Cons.contentFont
        titleLabel.textColor = Cons.contentColor
        titleLabel.textAlignment = .left
        return titleLabel
    }()

    private lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    var longPress: UILongPressGestureRecognizer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        contentView.addSubview(separatorLine)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.height.equalTo(Cons.titleLineHeight)
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-Cons.vMargin)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.lessThanOrEqualToSuperview().offset(Cons.vMargin)
            make.centerY.equalToSuperview()
            make.right.equalTo(-Cons.hMargin)
            make.height.greaterThanOrEqualTo(Cons.contentLineHeight)
            make.left.greaterThanOrEqualTo(self.contentView.snp.left).offset(130)
            make.bottom.lessThanOrEqualToSuperview().offset(-Cons.vMargin)
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
        titleLabel.text = item?.title
    }

    func addDividingLine() {
        separatorLine.isHidden = false
    }

    func removeDividingLine() {
        separatorLine.isHidden = true
    }

    @objc
    public func longPressHandle() {
        item?.handleLongPress(fromVC: targetViewController)
    }
}

extension MailProfileBaseCell {

    // swiftlint:disable all
    var Cons: CommonCons.Type {
        return Cons4H.self
    }
    // swiftlint:enable all

    /// Common layout constants.
    class CommonCons {
        class var hMargin: CGFloat { 16 }
        class var vMargin: CGFloat { 16 }
        class var titleLineHeight: CGFloat { 22 }
        class var titleFont: UIFont { .systemFont(ofSize: 16) }
        class var titleColor: UIColor { UIColor.ud.textTitle }
        class var contentLineHeight: CGFloat { 20 }
        class var contentFont: UIFont { .systemFont(ofSize: 14) }
        class var contentColor: UIColor { UIColor.ud.textPlaceholder }
        class var titleContentSpacing: CGFloat { 12 }
        class var titleWidth: CGFloat { 0 }
        class var arrowSize: CGFloat { 16 }
        class var arrowSpacing: CGFloat { 5 }
        class var linkColor: UIColor { UIColor.ud.textLinkNormal }
    }

    /// Horizontal layout constants.
    final class Cons4H: CommonCons {
        override class var titleWidth: CGFloat { 100 }
        override class var titleLineHeight: CGFloat { 22 }
        override class var contentLineHeight: CGFloat { 22 }
    }
}
