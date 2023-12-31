//
//  ShowAllColdDataTipCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/2/14.
//

import UIKit
import Foundation
import SnapKit
class ShowAllColdDataTipCell: UITableViewCell {
    private lazy var showAllDataTip: UILabel = {
        var label = UILabel()
        label.backgroundColor = .ud.bgBody
        label.attributedText = NSAttributedString(
            string: BundleI18n.LarkSearch.Lark_ASLSearch_ComprehensiveSearch_MsgTab_AllSearchResultsAreShown,
            attributes: [
                .foregroundColor: UIColor.ud.textCaption,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )
        return label
    }()

    private let bgView = UIView()
    var viewModel: SearchCellViewModel?

    /// 测试文本很长的场景下怎么折行
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        let layoutGuide = UILayoutGuide()
        contentView.backgroundColor = .ud.bgBody
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

        bgView.addSubview(showAllDataTip)
        showAllDataTip.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().offset(40)
            $0.left.greaterThanOrEqualToSuperview().offset(40)
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
