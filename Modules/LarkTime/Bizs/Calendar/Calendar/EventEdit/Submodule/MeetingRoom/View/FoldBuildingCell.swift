//
//  FoldingBuildingCell.swift
//  Calendar
//
//  Created by 朱衡 on 2021/1/19.
//

import UIKit
import UniverseDesignIcon
import Foundation
import UniverseDesignCheckBox

protocol FoldingBuildingCellDataType {
    var title: String { get }
    var isUnFold: Bool { get } // 是否展开
    var isSelected: SelectType? { get } // 是否处于选择态
}

final class FoldingBuildingCell: UIView, ViewDataConvertible {

    var viewData: FoldingBuildingCellDataType? {
        didSet {
            let view = ContentView(title: .init(text: viewData?.title ?? ""))
            view.isUserInteractionEnabled = false
            innerView.content = .customView(view)

            if viewData?.isUnFold ?? false {
                self.innerView.accessory = .type(.unfold)
            } else {
                self.innerView.accessory = .type(.fold)
            }

            let (oldSelect, newSelect) = (isSelected, viewData?.isSelected)
            switch (oldSelect, newSelect) {
            case (nil, nil): ()
            case let (nil, newSelect?):
                /// 变成多选态
                innerView.snp.updateConstraints {
                    $0.leading.equalTo(38)
                }
                selectIcon.isHidden = false
                selectIcon.isEnabled = newSelect != .disabled
                selectIcon.isSelected = newSelect == .selected || newSelect == .halfSelected
                selectIcon.updateUIConfig(boxType: newSelect.boxType, config: UDCheckBoxUIConfig())
            case (_, nil):
                /// 还原成单选态
                innerView.snp.updateConstraints {
                    $0.leading.equalTo(0)
                }
                selectIcon.isHidden = true
            case let (_, newSelect?):
                /// 更改选择态
                selectIcon.isEnabled = newSelect != .disabled
                selectIcon.isSelected = newSelect == .selected || newSelect == .halfSelected
                selectIcon.updateUIConfig(boxType: newSelect.boxType, config: UDCheckBoxUIConfig())
            }

            // 多选/非多选  点击热区逻辑不一样
            // 非多选：点击整个区域切换展开/收起
            // 多选：点击整个区域是选择/取消选择，点击accessoryView才是展开/收起
            let toggleFoldActionLogic = { [weak self] in
                guard let self = self else { return }
                if self.viewData?.isUnFold ?? false {
                    self.onUnfoldClick?()
                } else {
                    self.onFoldClick?()
                }
            }
            let toggleSelectActionLogic = { [weak self] in
                guard let self = self else { return }
                self.onSelectClick?()
            }
            if newSelect != nil {
                innerView.onClick = toggleSelectActionLogic
                innerView.onAccessoryClick = toggleFoldActionLogic
            } else {
                innerView.onClick = toggleFoldActionLogic
                innerView.onAccessoryClick = nil
            }

            self.isSelected = newSelect
        }
    }

    final class ContentView: UIView {
        private let titleLabel = UILabel()
        init(title: EventBasicCellLikeView.ContentTitle) {
            super.init(frame: .zero)
            titleLabel.font = title.font
            titleLabel.textColor = title.color
            titleLabel.text = title.text

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    /// 收起时点击回调
    var onFoldClick: (() -> Void)?
    /// 展开时点击回调
    var onUnfoldClick: (() -> Void)?
    /// 点击多选回调
    var onSelectClick: (() -> Void)?

    private let innerView = EventEditCellLikeView()
    private var isSelected: SelectType?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(selectIcon)
        addSubview(innerView)
        innerView.onHighLightedChanged = onHighLightedChanged

        innerView.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(0)
        }

        selectIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(18)
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }

        innerView.accessory = .type(.fold)
        let icon = UDIcon.getIconByKeyNoLimitSize(.buildingOutlined).renderColor(with: .n2)
        innerView.icon = .customImage(icon)
        innerView.accessory = .type(.fold)

        backgroundColor = innerView.backgroundColors.normal

        selectIcon.tapCallBack = { [weak self] _ in
            self?.onSelectClick?()
        }
    }

    @objc
    private func onSelectedTapped() {
        onSelectClick?()
    }

    private func onHighLightedChanged(_ highLighted: Bool) {
        backgroundColor = highLighted ? innerView.backgroundColors.highlight : innerView.backgroundColors.normal
    }

    private lazy var selectIcon = UDCheckBox()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
