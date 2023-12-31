//
//  MineMainPoweredByView.swift
//  LarkMine
//
//  Created by kongkaikai on 2020/12/8.
//

import Foundation
import UIKit
import SnapKit
import LarkReleaseConfig

final class MineMainPoweredByView: UIStackView {
    private var iconView = UIImageView()
    private var nameLabel = UILabel()
    private var poweredByLabel = UILabel()

    init() {
        super.init(frame: .zero)
        self.axis = .horizontal
        self.alignment = .center
        self.distribution = .fill

        iconView.image = Resources.powered_by
        iconView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.width.height.equalTo(18)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.text = ReleaseConfig.isLark ?
            BundleI18n.LarkMine.Lark_Core_Lark :
            BundleI18n.LarkMine.Lark_Core_Feishu

        poweredByLabel.font = UIFont.systemFont(ofSize: 12)
        poweredByLabel.textColor = UIColor.ud.textPlaceholder
        poweredByLabel.text = BundleI18n.LarkMine.Lark_Core_PoweredByFeishu

        var sortedViews: [UIView] = [iconView, nameLabel, poweredByLabel]
        if BundleI18n.currentLanguage != .zh_CN {
            sortedViews.insert(sortedViews.removeLast(), at: 0) // 非中文需要将poweredByLabel放置到最前面
        }

        for view in sortedViews {
            self.addArrangedSubview(view)
        }

        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.addArrangedSubview(spacerView)

        self.setCustomSpacing(4, after: nameLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
