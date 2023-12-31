//
//  BoxFeedsTitleNaviBar.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import UIKit
import Foundation
final class BoxFeedsTitleNaviBar: BaseFeedNaviBar {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(titleView: titleLabel)
        titleLabel.text = BundleI18n.LarkFeed.Lark_Core_CollapsedChats_FeedName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
