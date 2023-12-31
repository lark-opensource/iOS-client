//
//  ShowAllHotDataTipCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/2/14.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignIcon
class ShowAllHotDataTipCell: UITableViewCell {

    private let showHotDataTipView = UIView()
    private let showMoreIcon = UIImageView()
    private let showMoreText = {
        var showMore = UITextView()
        showMore.backgroundColor = UIColor.clear
        showMore.attributedText = NSAttributedString(
            string: BundleI18n.LarkSearch.Lark_ASLSearch_SearchInChat_MsgTab_ViewMoreMsgFromOverAYearAgo,
            attributes: [
                .foregroundColor: UIColor.ud.primaryContentDefault,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )
        showMore.isScrollEnabled = false
        showMore.isEditable = false
        showMore.isUserInteractionEnabled = false
        showMore.textAlignment = .center
        showMore.textContainerInset = .zero
        showMore.textContainer.lineFragmentPadding = 0.0
        return showMore
    }()

    private let bgView = UIView()
    var viewModel: SearchCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }

        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        showHotDataTipView.isUserInteractionEnabled = false
        bgView.addSubview(showHotDataTipView)
        showHotDataTipView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().offset(-40)
            $0.left.greaterThanOrEqualToSuperview().offset(40)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        showMoreIcon.image = UDIcon.getIconByKey(.downExpandOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(.ud.primaryContentDefault)
        showHotDataTipView.addSubview(showMoreIcon)
        showHotDataTipView.addSubview(showMoreText)
        showMoreIcon.setContentHuggingPriority(.required, for: .horizontal)
        showMoreIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        showMoreText.setContentHuggingPriority(.defaultLow, for: .horizontal)
        showMoreText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        showMoreIcon.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.centerY.equalTo(showMoreText.snp.centerY)
        }
        showMoreText.snp.makeConstraints {
            $0.top.greaterThanOrEqualToSuperview()
            $0.right.equalToSuperview()
            $0.left.equalTo(showMoreIcon.snp.right).offset(4)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateView(model: SearchTipViewModel) {
        self.viewModel = model
        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
    }
}
