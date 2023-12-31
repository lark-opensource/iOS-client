//
//  V3ListCell.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import LarkSwipeCellKit

// MARK: - List

protocol V3ListCellActionDelegate: AnyObject {
    func disabledAction(for checkbox: Checkbox, from sender: V3ListCell) -> CheckboxDisabledAction
    func enabledAction(for checkbox: Checkbox, from sender: V3ListCell) -> CheckboxEnabledAction
}

final class V3ListCell: SwipeCollectionViewCell {

    var viewData: V3ListCellData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            switch viewData.contentType {
            case .content(let data):
                subView.viewData = data
                skeletonView.isHidden = true
            case .skeleton:
                subView.viewData = nil
                skeletonView.isHidden = false
            case .availableToDrop:
                subView.viewData = nil
                skeletonView.isHidden = true
            case .none:
                subView.viewData = nil
                skeletonView.isHidden = true
            }
            if viewData.isFocused {
                focusedView.backgroundColor = UIColor.ud.udtokenTagBgYellow
                /// 需要额外更新头遍边框
                subView.ownerView.borderColor = UIColor.ud.udtokenTagBgYellow
            } else {
                focusedView.backgroundColor = .clear
                subView.ownerView.borderColor = viewData.contentType?.ownerBorderColor ?? .clear
            }
        }
    }

    /// 分割线
    var showSeparateLine: Bool = true {
        didSet {
            separateLine.isHidden = !showSeparateLine
        }
    }

    weak var actionDelegate: V3ListCellActionDelegate?

    private lazy var subView = V3ListContentView()
    private(set) lazy var skeletonView = V3ListSkeletonView()
    private lazy var focusedView = UIView()
    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()
    private let bgColor = (
        highlighted: UIColor.ud.fillPressed,
        normal: UIColor.ud.bgBody,
        selected: UIColor.ud.fillActive
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = bgColor.normal
        swipeView.backgroundColor = bgColor.normal
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            swipeView.backgroundColor = isSelected ? bgColor.selected : bgColor.normal
        }
    }

    override var isHighlighted: Bool {
        didSet {
            swipeView.backgroundColor = isHighlighted ? bgColor.highlighted : bgColor.normal
        }
    }

    private func setupSubViews() {
        focusedView.backgroundColor = .clear
        swipeView.addSubview(focusedView)
        swipeView.addSubview(skeletonView)
        swipeView.addSubview(subView)
        swipeView.addSubview(separateLine)
        subView.checkbox.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subView.frame = bounds
        skeletonView.frame = bounds
        focusedView.frame = bounds
        let lintHeight = CGFloat(1.0 / UIScreen.main.scale)
        separateLine.frame = CGRect(
            x: 0,
            y: frame.height - lintHeight,
            width: frame.width,
            height: lintHeight
        )
    }

    func showSkeletonIfNeeded() {
        skeletonView.hideUDSkeleton()
        if !skeletonView.isHidden {
            skeletonView.showUDSkeleton()
        }
    }

}

extension V3ListCell: CheckboxDelegate {

    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        return actionDelegate?.disabledAction(for: checkbox, from: self) ?? { }
    }

    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction {
        return actionDelegate?.enabledAction(for: checkbox, from: self) ?? .immediate { }
    }
}
