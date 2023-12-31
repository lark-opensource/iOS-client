//
//  FeedTeamSectionFooter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/24.
//

import Foundation
import UIKit
import LarkSwipeCellKit
import RxSwift
import SnapKit
import LarkBizAvatar
import LarkZoomable
import LarkSceneManager
import ByteWebImage
import RustPB
import LarkModel
import LarkBadge
import UniverseDesignDialog
import EENavigator

final class FeedTeamSectionFooter: UITableViewHeaderFooterView {
    static var identifier: String = "FeedTeamSectionFooter"
    let separatorView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor
        self.contentView.backgroundColor = bgColor
        separatorView.backgroundColor = UIColor.ud.lineDividerDefault
    }

    func layout() {
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func set(_ viewModel: FeedTeamItemViewModel, _ subTeamId: String?) {
        // 二级团队列表不展示底线
        if let teamId = subTeamId, !teamId.isEmpty {
            self.separatorView.isHidden = true
        } else {
            self.separatorView.isHidden = !viewModel.isExpanded
        }
    }
}
