//
//  CalendarFilterItemCell.swift
//  Calendar
//
//  Created by linlin on 2018/1/16.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import SnapKit
import LarkUIKit
import CalendarFoundation
enum SideBarCellType {
    case larkMine
    case larkSubscribe
    case local
    case google
    case exchange
}

protocol SidebarCellContent {
    var id: String { get }
    var type: SideBarCellType { get }
    var isPrimary: Bool { get }
    var isChecked: Bool { get set }
    var isActive: Bool { get set }
    var isExternal: Bool { get set }
    var isLoading: Bool { get set }
    var color: UIColor { get }
    var text: String { get }
    /// 会议室是否禁用
    var isDisabled: Bool { get }
    /// 会议室是否需要审批
    var needApproval: Bool { get }
    /// 日历描述
    var description: String? { get }
    ///
    var sourceTitle: String { get }
    /// 打点专用
    var userInfo: [String: Any] { get }
    /// 三方日历账户是否有效
    var externalAccountValid: Bool { get }
    /// 是否是离职转让日历
    var isDismissed: Bool { get }
}

final class CalendarSidebarCell: UITableViewCell {

    typealias Style = CalendarSidebarStyle

    private let checkbox = Checkbox()
    private let resignedTagView = TagViewProvider.resignedTagView
    private let label = UILabel.cd.textLabel(fontSize: 16)
    private let inactivateTag = TagViewProvider.inactivate()
    private let needApprovalTag = TagViewProvider.needApproval
    private let externalTag = TagViewProvider.externalNormal
    private let stackView = UIStackView()
    private(set) var isChecked: Bool = false
    private let bottomLine = UIView()
    var checkBoxTapped: (() -> Void)?
    private let bgView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.textColor = Style.FilterItemCell.labelTextColor

        bgView.backgroundColor = UIColor.ud.Y100
        bgView.alpha = 0.0
        bgView.isHidden = true

        contentView.addSubview(bgView)
        contentView.backgroundColor = UIColor.ud.bgBody
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentView.addSubview(label)
        setupCheckBox(checkbox)
        addCustomHighlightedView()

        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(inactivateTag)
        stackView.addArrangedSubview(needApprovalTag)
        stackView.addArrangedSubview(resignedTagView)
        stackView.addArrangedSubview(externalTag)

        contentView.addSubview(guideDot)
        guideDot.layer.cornerRadius = 12
        guideDot.isHidden = true
        guideDot.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    private func blink(view: UIView, isShowy: Bool, blinkCount: Int) {
        guard blinkCount > 0 else {
            return
        }

        UIView.animate(withDuration: 0.6) {
            view.alpha = isShowy ? 1.0 : 0.0
        } completion: { _ in
            self.blink(view: view, isShowy: !isShowy, blinkCount: blinkCount - 1)
        }
    }

    func setupContent(model: SidebarCellContent) {
        label.text = model.text
        resignedTagView.isHidden = !model.isDismissed
        inactivateTag.isHidden = !model.isDisabled
        externalTag.isHidden = !model.isExternal
        needApprovalTag.isHidden = !(!model.isDisabled && model.needApproval)
        setCheckBoxColor(checkbox, color: model.color)
        setCheckBoxStatus(isChecked: model.isChecked, animated: false)

        stackView.snp.remakeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(Style.FilterItemCell.labelLeftOffset)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-37)
        }
        bottomLine.isHidden = true
    }

    private func setCheckBoxStatus(isChecked: Bool, animated: Bool) {
        checkbox.isHidden = false
        checkbox.setOn(on: isChecked, animated: animated)
    }

    private func setupCheckBox(_ checkbox: Checkbox) {

        let wrapperView = UIView()
        self.contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(Style.FilterItemCell.checkboxLeft + Style.FilterItemCell.checkboxSize)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(checkBoxAreaTapped))
        wrapperView.addGestureRecognizer(tap)

        wrapperView.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Style.FilterItemCell.checkboxLeft)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Style.FilterItemCell.checkboxSize)
        }

        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.lineWidth = 1.5
        checkbox.isUserInteractionEnabled = false
    }

    private func setCheckBoxColor(_ checkbox: Checkbox, color: UIColor) {
        checkbox.onFillColor = color
        checkbox.onTintColor = color
        checkbox.strokeColor = color
    }

    lazy var guideDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.B100
        return view
    }()

    @objc
    private func checkBoxAreaTapped() {
        checkBoxTapped?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
