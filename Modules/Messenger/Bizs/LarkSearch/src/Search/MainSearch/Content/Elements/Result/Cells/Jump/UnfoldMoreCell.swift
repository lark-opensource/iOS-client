//
//  UnfoldMoreCell.swift
//  LarkSearch
//
//  Created by bytedance on 2022/3/18.
//
import Foundation
import LarkAccountInterface
import LarkCore
import UIKit
import LarkSearchCore
import UniverseDesignColor
import UniverseDesignIcon

final class UnfoldMoreCell: UITableViewCell, SearchTableViewCellProtocol {
    var viewModel: SearchCellViewModel?
    let loadMore = UILabel()
    let arrowImageView = UIImageView(image: UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.primaryContentDefault))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = SearchCellSelectedView()
        backgroundColor = UIColor.ud.bgBody
        let containerGuide = UILayoutGuide()
        contentView.addLayoutGuide(containerGuide)
        let cellHeight: CGFloat = SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 44 : 67
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(cellHeight).priority(.high)
        }
        contentView.addSubview(loadMore)
        contentView.addSubview(arrowImageView)
        if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            loadMore.snp.remakeConstraints {(make) in
                make.centerX.equalToSuperview().offset(-(16 + 8) / 2)
                make.centerY.equalToSuperview().offset(6)
                make.leading.greaterThanOrEqualToSuperview()
            }
            arrowImageView.snp.remakeConstraints { make in
                make.centerY.equalTo(loadMore)
                make.width.height.equalTo(16)
                make.leading.equalTo(loadMore.snp.trailing).offset(8)
                make.trailing.lessThanOrEqualToSuperview()
            }
            arrowImageView.isHidden = false
        } else {
            loadMore.snp.remakeConstraints {(make) in
                make.center.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }
            arrowImageView.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchCellViewModel, currentAccount: LarkAccountInterface.User?, searchText: String?) {
        guard let hideItemNum = (viewModel as? UnfoldMoreViewModel)?.hideItemNum else { return }
        var loadMoreStr: String
        if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            loadMoreStr = BundleI18n.LarkSearch.Lark_Search_ComprehensiveSearch_ResultsInCategories_ShowMoreInCategoryButton
        } else {
            loadMoreStr = BundleI18n.LarkSearch.Lark_ASL_SearchResultViewMore_Button
        }
        loadMoreStr += "(\(hideItemNum))"
        loadMore.text = loadMoreStr
        loadMore.textColor = SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? UDColor.primaryContentDefault : UDColor.textLinkNormal
        loadMore.textAlignment = NSTextAlignment.center
        loadMore.font = loadMore.font.withSize(SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 16.0 : 14.0)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard !SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled else { return }
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard !SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled else { return }
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }
}
