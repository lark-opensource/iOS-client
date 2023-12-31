//
//  MeetTabPadSectionFooterView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor

class MeetTabPadSectionFooterView: MeetTabSectionFooterView {

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
        paddingView.backgroundColor = UIColor.ud.bgContentBase
        lineView.isHidden = true

        paddingView.addSubview(roundedView)

        roundedView.snp.makeConstraints {
            $0.centerX.width.equalToSuperview()
            $0.centerY.equalTo(paddingView.snp.top)
            $0.height.equalTo(16.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = MeetTabHistoryDataSource.Layout.calculatePadding(bounds: bounds)
        let cellWidth = bounds.width - 2 * padding
        roundedView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 3, width: cellWidth, height: 13), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath

        paddingView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(padding)
        }
    }

    override func bindTo(viewModel: MeetTabSectionViewModel) {
        super.bindTo(viewModel: viewModel)
    }
}
