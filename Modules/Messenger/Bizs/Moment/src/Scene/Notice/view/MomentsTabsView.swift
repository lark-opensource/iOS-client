//
//  MomentsTabsView.swift
//  Moment
//
//  Created by bytedance on 2021/2/25.
//

import UIKit
import Foundation
import UniverseDesignTabs
import UniverseDesignBadge

final class MomentsNoticeTabsCell: UDTabsTitleCell {
    let badgeView = UDBadge(config: .number)
    override init(frame: CGRect) {
        super.init(frame: frame)
        badgeView.config.number = 0
        badgeView.config.maxNumber = MomentTab.maxBadgeCount
        badgeView.config.style = .characterBGRed
        badgeView.config.contentStyle = .custom(UIColor.ud.primaryOnPrimaryFill)
        self.contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.centerX)
            make.right.lessThanOrEqualToSuperview()
            make.top.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetBadgePosition(title: String) {
        let offsetX = MomentsDataConverter.widthForString(title, font: titleLabel.font) / 2 - 5
        badgeView.snp.updateConstraints { make in
            make.left.equalTo(titleLabel.snp.centerX).offset(offsetX)
        }
    }
}

final class MomentsTabsView: UDTabsTitleView {
    var badgeCountArr = [0, 0]

    override func registerCellClass(in tabsView: UDTabsView) {
        tabsView.collectionView.register(MomentsNoticeTabsCell.self, forCellWithReuseIdentifier: "MomentsNoticeTabsCell")
    }

    public override func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        let cell = self.dequeueReusableCell(withReuseIdentifier: "MomentsNoticeTabsCell", at: index)
        if let noticeCell = cell as?  MomentsNoticeTabsCell, index < self.badgeCountArr.count {
            noticeCell.resetBadgePosition(title: titles[index])
            noticeCell.badgeView.config.number = badgeCountArr[index]
            noticeCell.badgeView.isHidden = (badgeCountArr[index] <= 0)
        }
        return cell
    }
}
