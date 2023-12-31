//
//  HashTagDetailHeaderView.swift
//  Moment
//
//  Created by liluobin on 2021/6/28.
//

import Foundation
import UIKit
import LarkBizAvatar
import SnapKit

final class HashTagDetailHeaderView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.backgroundColor = .clear
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var detailDescriptionView: HashTagDetailDescriptionView = {
        return HashTagDetailDescriptionView()
    }()

    private let maxWidth = UIScreen.main.bounds.width - 32.0

    private var contentHeight: CGFloat = 34 + 20

    var suggestHeight: CGFloat {
        return contentHeight + 26 + 12 + 16
    }
    var titleLabelMaxY: CGFloat {
        return titleLabel.frame.maxY
    }
    var onRefreshHeaderInfo: ((RawData.HashTag) -> Void)?
    let viewModel: HashTagDetailHeaderViewModel
    let onHeightChange: ((CGFloat) -> Void)?

    var firstLoadTrackerItem: MomentsPolymerizationItem?
    var tracker: MomentsCommonTracker?

    init(viewModel: HashTagDetailHeaderViewModel,
         onHeightChange: ((CGFloat) -> Void)?) {
        self.viewModel = viewModel
        self.onHeightChange = onHeightChange
        super.init(frame: .zero)
        setupView()
        refreshData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(26)
            make.height.equalTo(34)
        }
        addSubview(detailDescriptionView)
        detailDescriptionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.height.equalTo(20)
        }
    }

    func refreshData() {
        let item = self.getTrackerItem()
        item?.startheaderDataCost()
        viewModel.getHashTagDetail { [weak self] in
            item?.endheaderDataCost()
            item?.startHeaderRender()
            self?.updateUI()
            item?.endHeaderRender()
            self?.tracker?.endTrackFeedUpdateItemForExtra(item)
        }
    }

    func updateUI() {
        guard let info = self.viewModel.detailInfo else {
            return
        }
        self.titleLabel.text = info.hashTag.content
        let postCountText = info.stats.postCount > 9999 ? BundleI18n.Moment.Lark_Community_Topic_9999PlusMoments : BundleI18n.Moment.Lark_Community_TopicsNumberMoments(info.stats.postCount)
        let participateCountStr = BundleI18n.Moment.Lark_Community_TopicsNumberEngagement(info.stats.participateCount)
        let participateCountText = info.stats.participateCount > 9999 ? BundleI18n.Moment.Lark_Community_Topic_9999PlusReactions : participateCountStr
        let items = [
            HashTagDescriptionItem(title: postCountText),
            HashTagDescriptionItem(title: participateCountText),
            HashTagDescriptionItem(title: "")
        ]
        detailDescriptionView.updateDataWithUsers(info.stats.visibleUsers, items: items)
        let titleHeight = getTitleLabelHeight()
        titleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(titleHeight)
        }
        let height = detailDescriptionView.suggestHeight
        detailDescriptionView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        let totalHeight = titleHeight + height
        if totalHeight != contentHeight {
            contentHeight = totalHeight
            self.onHeightChange?(self.suggestHeight)
        }
        self.onRefreshHeaderInfo?(info.hashTag)
    }

    func getTitleLabelHeight() -> CGFloat {
        return MomentsDataConverter.heightForString(titleLabel.text ?? "",
                                                        onWidth: maxWidth,
                                                        font: titleLabel.font)
    }

    func getTrackerItem() -> MomentsFeedUpdateItem? {
        if firstLoadTrackerItem == nil {
            firstLoadTrackerItem = MomentsPolymerizationItem(detail: .hashtag_recommend)
            return firstLoadTrackerItem
        } else {
            return self.tracker?.getItemWithEvent(.refreshFeed) as? MomentsFeedUpdateItem
        }
    }
}
