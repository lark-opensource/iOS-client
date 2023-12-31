//
//  HiddenChatListHeader.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/27.
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
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkNavigator
import LarkFeatureGating
import UniverseDesignColor

final class HiddenChatListHeader: UIView {
    private let nameLabel: UILabel

    init() {
        self.nameLabel = UILabel()
        super.init(frame: .zero)
        setupView()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor
        nameLabel.textColor = UIColor.ud.textPlaceholder
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.text = BundleI18n.LarkFeed.Project_MV_SlideToLeft
    }

    func layout() {
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-4)
            make.trailing.equalToSuperview().offset(-8)
        }
    }
}
