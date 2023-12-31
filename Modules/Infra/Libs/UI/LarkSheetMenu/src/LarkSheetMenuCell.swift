//
//  LarkSheetMenuCell.swift
//  LarkSheetMenu
//
//  Created by liluobin on 2023/6/1.
//

import UIKit
import LarkBadge
import UniverseDesignIcon

class LarkSheetMenuFoldCell: LarkSheetMenuBaseCell {
    static var reuseIdentifier = "LarkSheetMenuFoldCell"

    private var foldItemAction: ((LarkSheetMenuActionItem?) -> Void)?

    private var style: LarkSheetMenuActionItemLayout.Style? {
        didSet {
            updateUIFor(style: self.style)
        }
    }

    private lazy var arrowIcon: UIImageView = {
        let imageV = UIImageView()
        let image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imageV.image = image
        return imageV
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override func setupView() {
        containerView.addSubview(label)
        containerView.addSubview(icon)
        containerView.addSubview(arrowIcon)
        containerView.addSubview(subTitleLabel)

        label.numberOfLines = 1
        subTitleLabel.numberOfLines = 1
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        arrowIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(14)
            make.centerY.equalToSuperview()
        }
    }

    func setFoldCell(_ item: LarkSheetMenuActionItem,
                     foldItemAction: ((LarkSheetMenuActionItem?) -> Void)?) {
        self.foldItemAction = foldItemAction
        let style = LarkSheetMenuActionItemLayout.layoutForItem(item, maxWidth: self.contentView.frame.width - 48)
        self.style = style
        super.setCell(item)
        self.subTitleLabel.text = item.subText
    }

    func updateUIFor(style: LarkSheetMenuActionItemLayout.Style?) {
        let targetStyle = style ?? .single(LarkSheetMenuActionItemLayout.defaultHeight)
        var targetHeight = LarkSheetMenuActionItemLayout.defaultHeight
        switch targetStyle {
        case .single(let height):
            self.label.snp.remakeConstraints { make in
                make.left.equalTo(self.icon.snp.right).offset(12)
                make.centerY.equalToSuperview()
            }
            self.subTitleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.label.snp.right).offset(LarkSheetMenuActionItemLayout.textLeftMargin)
                make.right.lessThanOrEqualTo(self.arrowIcon.snp.left).offset(-LarkSheetMenuActionItemLayout.textRightMargin)
                make.centerY.equalToSuperview()
            }
            targetHeight = height
        case .double(let height):
            self.label.snp.remakeConstraints { make in
                make.left.equalTo(self.icon.snp.right).offset(12)
                make.top.equalToSuperview().offset(12)
                make.right.equalTo(self.arrowIcon.snp.left).offset(-2)
            }

            self.subTitleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.icon.snp.right).offset(12)
                make.bottom.equalToSuperview().offset(-12)
                make.right.equalTo(self.arrowIcon.snp.left).offset(-2)
            }
            targetHeight = height
        }
        self.containerView.snp.updateConstraints { (make) in
            make.height.equalTo(targetHeight)
        }
    }

    override func didTap() {
        self.foldItemAction?(self.item)
        super.didTap()
    }

}

class LarkSheetMenuCell: LarkSheetMenuBaseCell {
    static var reuseIdentifier = "LarkSheetMenuCell"

    override func setupView() {
        label.numberOfLines = 2
        containerView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }
        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalTo(icon.snp.centerY)
            make.left.equalTo(icon.snp.right).offset(12)
            make.top.lessThanOrEqualToSuperview().offset(13)
            make.bottom.lessThanOrEqualToSuperview().offset(-13)
            make.right.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(22)
        }
        label.font = .systemFont(ofSize: 16)
        containerView.addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.bottom.equalTo(icon.snp.top).offset(-1.25)
            make.left.equalTo(icon.snp.right).offset(-1.25)
            make.width.height.equalTo(8)
        }
        badgeView.isHidden = true
    }

    override func setCell(_ item: LarkSheetMenuActionItem) {
        super.setCell(item)
        let attributedString = NSMutableAttributedString(string: item.text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        self.label.attributedText = attributedString
    }

}

class LarkSheetMenuBaseCell: UITableViewCell {

    lazy var label = UILabel()
    lazy var icon = UIImageView()
    var action: (() -> Void)?

    /// 容器 用来撑开cell的高度
    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(48)
        }
        return containerView
    }()

    lazy var badgeView: BadgeView = {
        let badgeView = BadgeView(with: .dot(.web))
        return badgeView
    }()

    var item: LarkSheetMenuActionItem?

    @objc
    func didTap() {
        action?()
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.dynamic(light: .ud.bgFloat, dark: .ud.bgFloatOverlay)
        setupView()
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    func setupView() {}

    func setCell(_ item: LarkSheetMenuActionItem) {
        self.icon.image = item.icon
        self.icon.alpha = item.isGrey ? 0.3 : 1
        self.label.textColor = item.isGrey ? .ud.iconDisabled : .ud.textTitle
        self.badgeView.isHidden = !item.isShowDot
        self.action = item.tapAction
        self.item = item
        self.label.attributedText = NSAttributedString(string: item.text)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
