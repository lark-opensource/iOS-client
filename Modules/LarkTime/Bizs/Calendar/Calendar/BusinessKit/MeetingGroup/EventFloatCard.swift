//  EventFloatCard.swift
//  Calendar
//
//  Created by zhu chao on 2018/9/21.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

final class EventFloatCard: BaseMeetingFloatCardView {

    private lazy var titleLabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UDFont.body2(.fixed)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var subTitleLabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UDFont.body2(.fixed)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var thirdTitleLabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UDFont.body2(.fixed)
        label.textColor = UDColor.textTitle
        return label
    }()

    init(target: Any?,
         title: String,
         subTitle: String,
         thirdTitle: String,
         detailSelector: Selector,
         closeSelector: Selector) {
        // 外部使用 autolayout 布局 无需此处提供宽度
        super.init(icon: UDIcon.calendarColorful, backgroundColor: UIColor.ud.functionWarningFillSolid01)
        self.addClickAction(target: target, action: detailSelector)
        self.addCloseAction(target: target, action: closeSelector)

        setupContentView()
        update(title: title, subTitle: subTitle, thirdTitle: thirdTitle)
    }

    private func setupContentView() {
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(subTitleLabel)
        self.contentView.addSubview(thirdTitleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(20)
        }
        subTitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(20)
        }
        thirdTitleLabel.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom)
            $0.left.bottom.right.equalToSuperview()
            $0.height.equalTo(20)
        }
    }

    func update(title: String, subTitle: String, thirdTitle: String) {
        updateLabel(text: title, label: titleLabel)
        updateLabel(text: subTitle, label: subTitleLabel)
        updateLabel(text: thirdTitle, label: thirdTitleLabel)
    }

    private func updateLabel(text: String, label: UILabel) {
        label.text = text
        if text.isEmpty {
            label.isHidden = true
            label.snp.updateConstraints { $0.height.equalTo(0) }
        } else {
            label.isHidden = false
            label.snp.updateConstraints { $0.height.equalTo(20) }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
