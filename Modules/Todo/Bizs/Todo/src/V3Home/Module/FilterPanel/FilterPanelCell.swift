//
//  FilterPanelCell.swift
//  Todo
//
//  Created by baiyantao on 2022/8/23.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignFont

struct FilterPanelCellData {
    enum State {
        case normal
        case seleted
        case seletedWithSorting(isAscending: Bool)
    }

    var title: String
    var state: State = .normal

    var field: FilterPanelViewModel.Field?
}

final class FilterPanelCell: UITableViewCell {

    var viewData: FilterPanelCellData? {
        didSet {
            guard let data = viewData else { return }
            titleLabel.text = data.title
            switch data.state {
            case .normal:
                titleLabel.textColor = UIColor.ud.textTitle
            case .seleted:
                titleLabel.textColor = UIColor.ud.primaryContentDefault
            case .seletedWithSorting(let isAscending):
                titleLabel.textColor = UIColor.ud.primaryContentDefault
                sortingView.isUpArrowActive = isAscending
            }
            relayout(state: data.state)
        }
    }

    var clickHandler: ((_ field: FilterPanelViewModel.Field?) -> Void)?

    private lazy var titleLabel = initTitleLabel()
    private lazy var checkIcon = initCheckIcon()
    private lazy var sortingView = initSortingView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(checkIcon)
        contentView.addSubview(sortingView)
        contentView.addSubview(titleLabel)
        relayout(state: .normal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func relayout(state: FilterPanelCellData.State) {
        switch state {
        case .normal:
            checkIcon.isHidden = true
            sortingView.isHidden = true
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(16)
                $0.right.equalToSuperview().offset(-16)
            }
        case .seleted:
            checkIcon.isHidden = false
            sortingView.isHidden = true
            checkIcon.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(-16)
                $0.width.height.equalTo(16)
            }
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(16)
                $0.right.lessThanOrEqualTo(checkIcon.snp.left).offset(-16)
            }
        case .seletedWithSorting:
            checkIcon.isHidden = true
            sortingView.isHidden = false
            sortingView.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(-16)
                $0.width.equalTo(104)
                $0.height.equalTo(36)
            }
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(16)
                $0.right.lessThanOrEqualTo(sortingView.snp.left).offset(-16)
            }
        }
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 16)
        return label
    }

    private func initCheckIcon() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
        return view
    }

    private func initSortingView() -> SortingView {
        let view = SortingView()
        view.upArrowClickHandler = { [weak self] in
            guard case .sorting(var collection) = self?.viewData?.field else {
                assertionFailure()
                return
            }
            collection.indicator = .sorting(isAscending: true)
            self?.clickHandler?(.sorting(collection))
        }
        view.downArrowClickHandler = { [weak self] in
            guard case .sorting(var collection) = self?.viewData?.field else {
                assertionFailure()
                return
            }
            collection.indicator = .sorting(isAscending: false)
            self?.clickHandler?(.sorting(collection))
        }
        return view
    }

    @objc
    private func onClick() {
        clickHandler?(viewData?.field)
    }
}

private final class SortingView: UIView {

    var isUpArrowActive: Bool = true {
        didSet {
            guard isUpArrowActive != oldValue else { return }
            upArrowBtn.isSelected = isUpArrowActive
            upArrowBtn.backgroundColor = isUpArrowActive ? UIColor.ud.udtokenBtnTextBgPriHover : .clear
            downArrowBtn.isSelected = !isUpArrowActive
            downArrowBtn.backgroundColor = !isUpArrowActive ? UIColor.ud.udtokenBtnTextBgPriHover : .clear
        }
    }

    var upArrowClickHandler: (() -> Void)?
    var downArrowClickHandler: (() -> Void)?

    private lazy var upArrowBtn = initUpArrowBtn()
    private lazy var downArrowBtn = initDownArrowBtn()

    init() {
        super.init(frame: .zero)

        layer.masksToBounds = true
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = UIColor.ud.lineBorderCard.cgColor

        addSubview(upArrowBtn)
        upArrowBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(4)
            $0.width.equalTo(46)
            $0.height.equalTo(28)
        }

        addSubview(downArrowBtn)
        downArrowBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(upArrowBtn.snp.right).offset(4)
            $0.right.equalToSuperview().offset(-4)
            $0.width.equalTo(46)
            $0.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initUpArrowBtn() -> UIButton {
        let button = UIButton()
        let normalIcon = UDIcon.spaceUpBoldOutlined
            .ud.resized(to: CGSize(width: 14, height: 14))
            .ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(normalIcon, for: .normal)
        button.setImage(normalIcon, for: [.normal, .highlighted])
        let selectedIcon = UDIcon.spaceUpBoldOutlined
            .ud.resized(to: CGSize(width: 14, height: 14))
            .ud.withTintColor(UIColor.ud.primaryContentDefault)
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: [.selected, .highlighted])
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.isSelected = true
        button.backgroundColor = UIColor.ud.udtokenBtnTextBgPriHover
        button.addTarget(self, action: #selector(onUpArrowClick), for: .touchUpInside)
        return button
    }

    private func initDownArrowBtn() -> UIButton {
        let button = UIButton()
        let normalIcon = UDIcon.spaceDownBoldOutlined
            .ud.resized(to: CGSize(width: 14, height: 14))
            .ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(normalIcon, for: .normal)
        button.setImage(normalIcon, for: [.normal, .highlighted])
        let selectedIcon = UDIcon.spaceDownBoldOutlined
            .ud.resized(to: CGSize(width: 14, height: 14))
            .ud.withTintColor(UIColor.ud.primaryContentDefault)
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: [.selected, .highlighted])
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(onDownArrowClick), for: .touchUpInside)
        return button
    }

    @objc
    private func onUpArrowClick() {
        upArrowClickHandler?()
    }

    @objc
    private func onDownArrowClick() {
        downArrowClickHandler?()
    }
}
