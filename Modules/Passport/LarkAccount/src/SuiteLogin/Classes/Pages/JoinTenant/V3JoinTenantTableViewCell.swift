//
//  V3JoinTenantTableViewCell.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import LKCommonsLogging
import SnapKit
import LarkUIKit

class V3JoinTenantTableViewCell: UITableViewCell, SelectionStyleProtocol {

    static let logger = Logger.log(V3JoinTenantTableViewCell.self, category: "JoinTenantView")

    let cardContainer: V3CardContainerView = V3CardContainerView()

    let iconView: UIImageView = {
        let iconView = UIImageView(frame: .zero)
        iconView.layer.cornerRadius = Layout.iconImageDiameter / 2.0
        iconView.clipsToBounds = true
        return iconView
    }()

    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17, weight: .semibold)
        lbl.textColor = UIColor.ud.textTitle
        return lbl
    }()

    let topLine: UIView = {
        let topLine = UIView()
        topLine.backgroundColor = UIColor.ud.lineDividerDefault
        topLine.isHidden = true
        return topLine
    }()

    let arrowImgView: UIImageView = {
        let imgView = UIImageView()
        let img = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imgView.image = img
        imgView.frame.size = img.size
        return imgView
    }()

    func updateSelection(_ selected: Bool) {
        cardContainer.updateSelection(selected)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(cardContainer)
        cardContainer.addSubview(iconView)
        cardContainer.addSubview(titleLabel)
        cardContainer.addSubview(arrowImgView)
        cardContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.top.bottom.equalToSuperview().inset(CL.cardVerticalSpace)
        }
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(CL.itemSpace)
            make.width.height.equalTo(Layout.iconImageDiameter)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(CL.itemSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.titleLabelHeight)
            make.right.lessThanOrEqualTo(arrowImgView.snp.left).offset(-Layout.subtitleRightSpace)
        }
        titleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.width.equalTo(arrowImgView.frame.width)
            make.centerY.equalToSuperview()
            make.size.equalTo(arrowImgView.frame.size)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCell(_ item: V3JoinTenantTypeItem) {
        titleLabel.text = item.title
        self.iconView.image = item.icon
    }
}

extension V3JoinTenantTableViewCell {
    struct Layout {
        static let verticalSpace: CGFloat = 4.0
        static let subtitleRightSpace: CGFloat = 12.0
        static let titleLabelHeight: CGFloat = 24.0
        static let minSubtitleHeight: CGFloat = (Layout.subtitleFontSize + 3) * 2
        static let subtitleFontSize: CGFloat = 14.0
        static let iconImageDiameter: CGFloat = 48.0
        static let cellHeight: CGFloat = iconImageDiameter + CL.itemSpace * 2
    }
}
