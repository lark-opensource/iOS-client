//
//  MoreActionVerticalStatusItemCell.swift
//  MailSDK
//
//  Created by Ender on 2023/8/25.
//

import Foundation
import LarkInteraction
import UniverseDesignIcon

class MoreActionVerticalStatusItemCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let bottomLineView = UIView()
    private let arrowImageView = UIImageView()

    private static let leftOffset: CGFloat = 16
    private static let topOffset: CGFloat = 13
    private static let spacing: CGFloat = 4
    private static let minLabelHeight: CGFloat = 22
    private static let titleFont = UIFont.systemFont(ofSize: 16)
    private static let statusFont = UIFont.systemFont(ofSize: 14)
    private static let arrowSize = CGSize(width: 12, height: 12)

    static func cellHeightFor(title: String, status: String, cellWidth: CGFloat) -> CGFloat {
        let statusWidth = statusLabelWidthFor(status: status)
        let titleWidth = cellWidth - 2 * MoreActionVerticalStatusItemCell.leftOffset - statusWidth - MoreActionVerticalStatusItemCell.arrowSize.width - 2 * MoreActionVerticalStatusItemCell.spacing
        let titleHeight = (title as NSString).boundingRect(with: CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: [.font: MoreActionVerticalStatusItemCell.titleFont],
                                                           context: nil).height
        let titleLabelHeight = min(ceil(MoreActionVerticalStatusItemCell.titleFont.lineHeight * 2), ceil(titleHeight))
        return titleLabelHeight + 2 * MoreActionVerticalStatusItemCell.topOffset
    }

    static func statusLabelWidthFor(status: String) -> CGFloat {
        let statusWidth = (status as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                         height: MoreActionVerticalStatusItemCell.minLabelHeight),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: [.font: MoreActionVerticalStatusItemCell.statusFont],
                                                            context: nil).width
        return ceil(statusWidth)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    func updateBottomLine(isHidden: Bool) {
        bottomLineView.isHidden = isHidden
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgFloat

        titleLabel.font = MoreActionVerticalStatusItemCell.titleFont
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 2

        statusLabel.font = MoreActionVerticalStatusItemCell.statusFont
        statusLabel.backgroundColor = .clear
        statusLabel.textColor = UIColor.ud.textPlaceholder

        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault

        arrowImageView.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN3

        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(bottomLineView)
        contentView.addSubview(arrowImageView)

        arrowImageView.snp.makeConstraints { make in
            make.right.equalTo(-MoreActionVerticalStatusItemCell.leftOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(MoreActionVerticalStatusItemCell.arrowSize)
        }
        statusLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.right.equalTo(arrowImageView.snp.left).offset(-MoreActionVerticalStatusItemCell.spacing)
            make.width.equalTo(MoreActionVerticalStatusItemCell.statusLabelWidthFor(status: statusLabel.text ?? ""))
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(MoreActionVerticalStatusItemCell.leftOffset)
            make.right.lessThanOrEqualTo(statusLabel.snp.left).offset(-MoreActionVerticalStatusItemCell.spacing)
            make.top.equalToSuperview().offset(MoreActionVerticalStatusItemCell.topOffset)
            make.bottom.equalToSuperview().offset(-MoreActionVerticalStatusItemCell.topOffset)
        }
        bottomLineView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(effect: .hover())
            )
            self.addLKInteraction(pointer)
        }
    }

    func setup(title: String, status: String) {
        titleLabel.text = title
        statusLabel.text = status
        setupViews()
    }
}
