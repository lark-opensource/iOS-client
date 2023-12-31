//
//  MeetTabPadSectionHeaderView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor

class MeetTabPadSectionHeaderView: MeetTabSectionHeaderView {

    lazy var roundedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.masksToBounds = false

        let shadowColor = UDColor.getValueByKey(.s2DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
        view.layer.ud.setShadowColor(shadowColor, bindTo: paddingView)
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 3
        view.layer.cornerRadius = 10.0
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        clipsToBounds = true
        backgroundColor = .ud.bgContentBase
        contentView.backgroundColor = .ud.bgContentBase
        paddingView.backgroundColor = .ud.bgContentBase

        paddingView.addSubview(roundedView)

        titleStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(24.0)
            $0.left.equalToSuperview().inset(4.0)
            $0.right.lessThanOrEqualTo(moreButton)
            $0.bottom.equalTo(roundedView.snp.top).offset(-8.0)
        }
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(20.0)
        }
        moreButton.snp.updateConstraints {
            $0.right.equalToSuperview()
        }
        roundedView.snp.remakeConstraints {
            $0.centerX.width.equalToSuperview()
            $0.height.equalTo(16.0)
            $0.centerY.equalTo(paddingView.snp.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = MeetTabHistoryDataSource.Layout.calculatePadding(bounds: bounds)
        let cellWidth = bounds.width - 2 * padding
        roundedView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: cellWidth, height: 9), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5, height: 5)).cgPath

        paddingView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(padding)
        }
    }

    override func bindTo(viewModel: MeetTabSectionViewModel) {
        super.bindTo(viewModel: viewModel)
        let textColor: UIColor? = UIColor.ud.textTitle
        titleLabel.attributedText = .init(string: viewModel.title, config: .boldBodyAssist, textColor: textColor)
        titleIcon.isHidden = true
        animationView?.isHidden = true
    }
}
