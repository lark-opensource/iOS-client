//
//  RecentForwardView.swift
//  LarkSearchCore
//
//  Created by bytedance on 2022/6/22.
//

import Foundation
import UIKit
import LarkMessengerInterface
import UniverseDesignColor

final class RecentForwardView: UIView {
    final class Layout {
        static let stackViewLeading: CGFloat = 18
        static let cellWidth: CGFloat = 60
        static let cellHeight: CGFloat = 98
        static let maxCellCount: Int = 5
    }

    var recentForwardViewCells: [RecentForwardViewCell] = []
    var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkSearchCore.Lark_IM_Forward_RecentlyForwardedTo_Title
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 1
        return label
    }()

    var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        return stackView
    }()

    var bottomBorder: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(titleLabel)
        self.addSubview(stackView)
        self.addSubview(bottomBorder)
        bottomBorder.backgroundColor = UIColor.ud.bgBase
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(26)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(Layout.cellHeight)
            make.left.equalTo(Layout.stackViewLeading)
        }
        bottomBorder.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(7)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(cellDatas: [RecentForwardCellData]) {
        for i in 0 ..< min(Layout.maxCellCount, cellDatas.count) {
            if i >= self.recentForwardViewCells.count {
                let cell = RecentForwardViewCell()
                cell.snp.makeConstraints { make in
                    make.width.equalTo(Layout.cellWidth)
                    make.height.equalTo(Layout.cellHeight)
                }
                self.recentForwardViewCells.append(cell)
                self.stackView.addArrangedSubview(cell)
            }
            let model = cellDatas[i]
            self.recentForwardViewCells[i].updateCellContent(model: model.item, hideCheckBox: !model.isMutiple, isSelected: model.isSelected, tapEvent: model.tapEvent)
        }
        stackView.spacing = (frame.width - 2 * Layout.stackViewLeading - CGFloat(Layout.maxCellCount) * Layout.cellWidth) / CGFloat(Layout.maxCellCount - 1)
        layoutIfNeeded()
    }
}
