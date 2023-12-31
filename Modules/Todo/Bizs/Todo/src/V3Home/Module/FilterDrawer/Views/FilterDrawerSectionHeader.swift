//
//  FilterDrawerSectionHeader.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

struct FilterDrawerSectionHeaderData {
    var title: String
    var isExpanded: Bool = false
    var hasAddBtn: Bool = false
}

final class FilterDrawerSectionHeader: UITableViewHeaderFooterView {

    var viewData: FilterDrawerSectionHeaderData? {
        didSet {
            guard let data = viewData else { return }
            titleLabel.text = data.title
            arrowView.isSelected = data.isExpanded

            if data.hasAddBtn != oldValue?.hasAddBtn {
                relayout(hasAddBtn: data.hasAddBtn)
            }
        }
    }

    var clickHandler: (() -> Void)?
    var addBtnHandler: (() -> Void)?

    private lazy var dividingLineView = initDividingLineView()
    private lazy var arrowView = initArrowBtn()
    private lazy var titleLabel = initTitleLabel()
    private lazy var addBtn = initAddBtn()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }

        containerView.addSubview(dividingLineView)
        dividingLineView.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.top.equalToSuperview().offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        containerView.addSubview(arrowView)
        arrowView.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-18)
            $0.left.equalToSuperview().offset(20)
            $0.width.height.equalTo(12)
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(addBtn)
        relayout(hasAddBtn: false)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func relayout(hasAddBtn: Bool) {
        addBtn.isHidden = !hasAddBtn
        if hasAddBtn {
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalTo(arrowView)
                $0.left.equalTo(arrowView.snp.right).offset(16)
            }
            addBtn.snp.remakeConstraints {
                $0.centerY.equalTo(arrowView)
                $0.width.height.equalTo(20)
                $0.right.equalToSuperview().offset(-16)
                $0.left.equalTo(titleLabel.snp.right).offset(16)
            }
        } else {
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalTo(arrowView)
                $0.left.equalTo(arrowView.snp.right).offset(16)
                $0.right.equalToSuperview().offset(-16)
            }
        }
    }

    private func initDividingLineView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }

    private func initArrowBtn() -> UIButton {
        let button = UIButton()
        button.setImage(UDIcon.expandDownFilled, for: .selected)
        button.setImage(UDIcon.expandRightFilled, for: .normal)
        button.isUserInteractionEnabled = false
        return button
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        return label
    }

    private func initAddBtn() -> UIButton {
        let button = UIButton(type: .custom)
        let image = UDIcon.addOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.addTarget(self, action: #selector(onAddBtnClick), for: .touchUpInside)
        return button
    }

    @objc
    private func onClick() {
        clickHandler?()
    }

    @objc
    private func onAddBtnClick() {
        addBtnHandler?()
    }
}
