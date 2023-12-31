//
//  CalendarManagementView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/21.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
protocol CalendarManagerViewDelegate: AnyObject {
    func calSummaryChanged(newSummary: String)
    func calNoteChanged(newNote: String)
    func calColorPressed()
    func calAccessPressed()
    func calDescPressed()
    func addCalMemberPressed()
    func calMemberPressed(index: Int)
    func unsubscribeCalPressed()
    func deleteCalPressed()
}

protocol CalendarManagerViewProtocol {
    var calSummary: String { get }
    var calSummaryRemark: String? { get }
    var permission: CalendarAccess { get }
    var color: UIColor { get }
    var desc: String { get }
    var calMemberCellModels: [CalendarMemberCellModel] { get }
    var canAddNewMember: Bool { get }
}

extension CalendarManagerViewProtocol {
}

final class CalendarManagerView: UIView {
    
    enum UIShowCondition: String, CaseIterable {
        case summary
        case note
        case access
        case color
        case desc
        case delete
        case unSubscribe
        case member
    }
    
    weak var delegate: CalendarManagerViewDelegate?
    let condition: CalendarEditPermission
    let uiCondition: [UIShowCondition]
    var canAddNewMember = false

    lazy var calendarMemberView: CalendarMemberView = {
        let view = CalendarMemberView()
        view.didSelect = { [unowned self] index in
            self.delegate?.calMemberPressed(index: index)
        }
        return view
    }()

    lazy var summaryCell: CalendarManagerSummaryCell = {
        let cell = CalendarManagerSummaryCell(iconImage: UDIcon.getIconByKeyNoLimitSize(.calendarOutlined)
                                                .renderColor(with: .n3)
                                                .withRenderingMode(.alwaysOriginal),
                                              placeHolder: BundleI18n.Calendar.Calendar_Setting_AddCalendarTitle,
                                              isEditable: condition.isCalSummaryEditable,
                                              textChanged: { [unowned self] (newSummar) in
                                                self.delegate?.calSummaryChanged(newSummary: newSummar)
        })
        return cell
    }()

    lazy var noteCell: CalendarManagerSummaryCell = {
        let cell = CalendarManagerSummaryCell(iconImage: UDIcon.getIconByKeyNoLimitSize(.calendarEditOutlined)
                                                .renderColor(with: .n3)
                                                .withRenderingMode(.alwaysOriginal),
                                          placeHolder: BundleI18n.Calendar.Calendar_Setting_AddCalendarAlias,
                                          isEditable: condition.isCalSummaryRemarkVisible,
                                          textChanged: { [unowned self] (newSummary) in
                                            self.delegate?.calNoteChanged(newNote: newSummary)
        })
        return cell
    }()

    lazy var accessCell: CalendarManagerSettingCell = {
        let cell = CalendarManagerSettingCell(iconImage: UDIcon.getIconByKeyNoLimitSize(.lockOutlined)
                                                .renderColor(with: .n3)
                                                .withRenderingMode(.alwaysOriginal),
                                          title: "")
        cell.addTarget(self, action: #selector(accessCellPressed), for: .touchUpInside)
        return cell
    }()

    @objc
    func accessCellPressed() {
        guard condition.isPermissionEditable || condition.isAllStaff else { return }
        delegate?.calAccessPressed()
    }

    lazy var colorCell: CalendarManagerSettingCell = {
        let cell = CalendarManagerSettingCell(iconImage: nil, title: BundleI18n.Calendar.Calendar_Setting_CalendarColor)
        cell.addTarget(self, action: #selector(colorCellPressed), for: .touchUpInside)
        return cell
    }()

    @objc
    func colorCellPressed() {
        delegate?.calColorPressed()
    }

    lazy var descCell: CalendarManagerSettingCell = {
        let cell = CalendarManagerSettingCell(iconImage: UDIcon.getIconByKeyNoLimitSize(.describeOutlined)
                                                .renderColor(with: .n3)
                                                .withRenderingMode(.alwaysOriginal),
                                              title: "",
                                              placeHolder: BundleI18n.Calendar.Calendar_Setting_NoCalendarDescription)
        cell.addTarget(self, action: #selector(descCellPressed), for: .touchUpInside)
        cell.addBottomBorder()
        return cell
    }()

    @objc
    func descCellPressed() {
        delegate?.calDescPressed()
    }

    lazy var deleteCell: OperationButton = {
        let buttonModel = OperationButton.getData(with: .deleteCalendar)
        let button = OperationButton(model: buttonModel)
        button.addTarget(self, action: #selector(deleteCellPressed), for: .touchUpInside)
        return button
    }()

    @objc
    func deleteCellPressed() {
        delegate?.deleteCalPressed()
    }

    lazy var unSubscribeCell: OperationButton = {
        let buttonModel = OperationButton.getData(with: .unsubscribeCalendar)
        let button = OperationButton(model: buttonModel)
        button.addTarget(self, action: #selector(unsubscribeCellPressed), for: .touchUpInside)
        button.addTopBorder()
        return button
    }()

    @objc
    func unsubscribeCellPressed() {
        delegate?.unsubscribeCalPressed()
    }

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    init(condition: CalendarEditPermission, uiCondition: [UIShowCondition] = UIShowCondition.allCases) {
        self.condition = condition
        self.uiCondition = uiCondition
        super.init(frame: .zero)
        scrollView.layout(equalTo: self)
        layout(stackview: stackView, in: scrollView)
        layout(withCondition: condition, uiCondition)
    }

    private func layout(stackview: UIStackView, in scrollView: UIScrollView) {
        scrollView.addSubview(stackview)
        stackview.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(8)
            make.width.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func layout(withCondition condition: CalendarEditPermission, _ uiCondition: [UIShowCondition]) {
        var infoViews: [UIView] = []
        if uiCondition.contains(.summary) {
            infoViews.append(summaryCell)
        }
        
        if uiCondition.contains(.access) {
            infoViews.append(accessCell)
        }
        
        if uiCondition.contains(.color) {
            infoViews.append(colorCell)
            colorCell.isEnabled = condition.isColorEditable
        }

        if uiCondition.contains(.desc) {
            infoViews.append(descCell)
            descCell.isEnabled = true
        }
        
        infoViews.enumerated().forEach { (index, view) in
            if index == infoViews.count - 1 {
                stackView.addArrangedSubview(view)
            } else {
                layout(view: view, in: stackView)
            }
        }
        
        if uiCondition.contains(.member) {
            addBorder(in: stackView)

            if condition.isCalMemberEditable {
                let view = AddCalendarMemberView()
                view.addTarget(self, action: #selector(addCalendarMemberPressed), for: .touchUpInside)
                stackView.addArrangedSubview(view)
                view.lu.addTopBorder()
                view.lu.addBottomBorder()
            } else {
                let view = CalendarMemberTitleView()
                stackView.addArrangedSubview(view)
            }
            stackView.addArrangedSubview(calendarMemberView)
        }

        if uiCondition.contains(.unSubscribe) || uiCondition.contains(.delete) {
            if condition.isUnsubscriable || condition.isDeleteable {
                addBorder(in: stackView)
            }
            if condition.isUnsubscriable, uiCondition.contains(.unSubscribe) {
                stackView.addArrangedSubview(unSubscribeCell)
                if condition.isDeleteable {
                    unSubscribeCell.addBottomLine(0)
                }
            }
            if condition.isDeleteable, uiCondition.contains(.delete) {
                stackView.addArrangedSubview(deleteCell)
            }
        }
    }

    private func layout(view: UIView,
                        in stackView: UIStackView) {
        stackView.addArrangedSubview(view)
        view.addBottomBorder(inset: UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0))
    }

    private func addBorder(in stackView: UIStackView,
                           height: CGFloat = 8,
                           leftBorderWidht: CGFloat = 0) {
        let wrapper = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.ud.bgBase
        wrapper.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.height.equalTo(height)
            make.top.bottom.right.equalToSuperview()
            make.left.equalToSuperview().offset(leftBorderWidht)
        }
        stackView.addArrangedSubview(wrapper)
    }

    @objc
    func addCalendarMemberPressed() {
        if canAddNewMember {
            self.delegate?.addCalMemberPressed()
        }
    }

    func update(with model: CalendarManagerViewProtocol) {
        summaryCell.update(with: model.calSummary)
        noteCell.update(with: model.calSummaryRemark ?? "")
        descCell.updateTitle(with: model.desc)
        let accessCellDisabled = !condition.isPermissionEditable || condition.isAllStaff
        accessCell.updateTitle(with: model.permission.toLocalString(), showDisabledColor: accessCellDisabled)
        accessCell.updateTail(isHidden: accessCellDisabled)

        colorCell.updateIcon(with: model.color)
        calendarMemberView.update(with: model.calMemberCellModels)
        canAddNewMember = model.canAddNewMember
        layoutIfNeeded()
        if !condition.isDescEditable && !descCell.isTitleTruncated() {
            descCell.isEnabled = false
            descCell.update(isHidden: true)
        } else {
            descCell.isEnabled = true
            descCell.update(isHidden: false)
        }
        descCell.updateTitle(with: model.desc, showDisabledColor: !condition.isDescEditable)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 点击notecell以外的地方，键盘收起
        if condition.isCalSummaryRemarkVisible {
            let rect = noteCell.convert(noteCell.bounds, to: self)
            if !rect.contains(point) {
                endEditing(true)
            }
        } else { // 点击summaryCell以外的地方，键盘收起
            let rect = summaryCell.convert(summaryCell.bounds, to: self)
            if !rect.contains(point) {
                endEditing(true)
            }
        }
        return super.hitTest(point, with: event)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
