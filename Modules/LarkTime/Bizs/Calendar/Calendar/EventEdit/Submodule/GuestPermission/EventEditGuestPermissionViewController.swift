//
//  EventEditGuestPermissionViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2023/2/28.
//

import Foundation
import LarkUIKit
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import CalendarFoundation

protocol EventEditGuestPermissionViewControllerDelegate: AnyObject {
    func didFinishEdit(from viewController: EventEditGuestPermissionViewController)
    func didCancelEdit(from viewController: EventEditGuestPermissionViewController)
}

// 参与者权限模型
enum GuestPermission: Int, Comparable {
    /// 无
    case none
    /// 查看参与者列表
    case guestCanSeeOtherGuests
    /// 邀请参与者
    case guestCanInvite
    /// 修改日程
    case guestCanModify

    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.rawValue == rhs.rawValue)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return (lhs.rawValue < rhs.rawValue)
    }
}

class EventEditGuestPermissionViewController: BaseUIViewController {

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    enum Source {
        case eventEdit
        case calendarSetting
    }

    weak var delegate: EventEditGuestPermissionViewControllerDelegate?

    struct ViewData {
        /// 参会人编辑日程权限
        var guestPermission: GuestPermission = .guestCanInvite
        /// 参会人创建纪要权限
        var createNotesPermission: Rust.CreateNotesPermission = .defaultValue()
    }

    private(set) var viewData: ViewData

    private let minPermission: GuestPermission
    private var originalGuestPermission: GuestPermission

    // view cell
    private let titleInfoCell = UILabel.cd.subTitleLabel()
    private lazy var guestCanModify: SettingView = {
        let view = SettingView(switchSelector: #selector(switchModify(sender:)),
                               target: self,
                               title: I18n.Calendar_Detail_ModifyEvent)
        return view
    }()
    private lazy var guestCanInvite: SettingView = {
        let view = SettingView(switchSelector: #selector(switchInvite(sender:)),
                               target: self,
                               title: I18n.Calendar_Detail_InviteOthers)
        return view
    }()
    private lazy var guestCanSeeOtherGuests: SettingView = {
        let view = SettingView(switchSelector: #selector(switchSeeOther(sender:)),
                               target: self,
                               title: I18n.Calendar_Detail_CheckGuestList,
                               subTitle: inMeetingNotesFG ? I18n.Calendar_Event_UnCheckedUnableNew : I18n.Calendar_Event_UnCheckedUnable,
                               enableNoLimitMultiLine: true)
        return view
    }()
    private lazy var guestCanCreateNotes: SettingView = {
        let view = SettingView(switchSelector: #selector(switchCanCreateNotes(sender:)),
                               target: self,
                               title: I18n.Calendar_G_CreateNotes_Options)
        return view
    }()

    private let source: Source

    private let disposeBag = DisposeBag()

    var inMeetingNotesFG: Bool = false

    init(viewData: ViewData,
         minPermission: GuestPermission = .none,
         source: Source = .eventEdit) {
        self.viewData = viewData
        self.minPermission = minPermission
        self.originalGuestPermission = viewData.guestPermission
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavibar()
        setupView()
        updateViewData(permission: self.viewData.guestPermission)
        updateViewData(createNotesPermission: self.viewData.createNotesPermission)
    }

    private func setupNavibar() {

        let backButton = UIBarButtonItem(title: I18n.Calendar_Common_Cancel, style: .plain, target: self, action: #selector(cancelHandler))
        self.navigationItem.leftBarButtonItem = backButton

        let saveButton = UIBarButtonItem(title: I18n.Calendar_Common_Save, style: .plain, target: self, action: #selector(saveHandler))
        saveButton.tintColor = UIColor.ud.primaryContentDefault
        self.navigationItem.rightBarButtonItem = saveButton
    }

    private func setupView() {
        title = I18n.Calendar_G_GuestPermission_Title
        self.view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        titleInfoCell.text = I18n.Calendar_Detail_GuestsRightMobile

        let guestCellStackBG = UIStackView()
        guestCellStackBG.axis = .vertical

        addTitleCell(stackView: guestCellStackBG)
        guestCellStackBG.addArrangedSubview(guestCanModify)
        guestCellStackBG.addArrangedSubview(guestCanInvite)
        guestCellStackBG.addArrangedSubview(guestCanSeeOtherGuests)
        if inMeetingNotesFG && source == .eventEdit {
            guestCellStackBG.addArrangedSubview(guestCanCreateNotes)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        addTitleCell(stackView: stackView)
        stackView.addArrangedSubview(guestCellStackBG)

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
//            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    @objc
    private func switchModify(sender: UISwitch) {
        self.updateViewData(permission: sender.isOn ? .guestCanModify : .guestCanInvite)
        self.traceCalendarSetting(view: .guestCanModify, isChecked: sender.isOn)
    }

    @objc
    private func switchInvite(sender: UISwitch) {
        self.updateViewData(permission: sender.isOn ? .guestCanInvite : .guestCanSeeOtherGuests)
        self.traceCalendarSetting(view: .guestCanInvite, isChecked: sender.isOn)
    }

    @objc
    private func switchSeeOther(sender: UISwitch) {
        self.updateViewData(permission: sender.isOn ? .guestCanSeeOtherGuests : .none)
        self.traceCalendarSetting(view: .guestCanSeeOtherGuests, isChecked: sender.isOn)
    }

    @objc
    private func switchCanCreateNotes(sender: UISwitch) {
        self.updateViewData(createNotesPermission: sender.isOn ? .all : .organizer)
    }

    private func addTitleCell(stackView: UIStackView) {
        let wrapper = UIView()
        wrapper.addSubview(titleInfoCell)
        titleInfoCell.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().offset(NewEventViewUIStyle.Margin.leftMargin)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-4)
        }
        stackView.addArrangedSubview(wrapper)
    }

    private func updateViewData(permission: GuestPermission) {
        let fixPermission: GuestPermission = permission < minPermission ? minPermission : permission

        self.viewData.guestPermission = fixPermission

        guestCanModify.update(switchIsOn: fixPermission >= .guestCanModify)
        guestCanInvite.update(switchIsOn: fixPermission >= .guestCanInvite)
        guestCanSeeOtherGuests.update(switchIsOn: fixPermission >= .guestCanSeeOtherGuests)

        guestCanModify.update(switchIsEditable: minPermission < .guestCanModify)
        guestCanInvite.update(switchIsEditable: permission <= .guestCanInvite && minPermission < .guestCanInvite)
        guestCanSeeOtherGuests.update(switchIsEditable: fixPermission <= .guestCanSeeOtherGuests && minPermission < .guestCanSeeOtherGuests)

    }

    private func updateViewData(createNotesPermission: Rust.CreateNotesPermission) {
        self.viewData.createNotesPermission = createNotesPermission
        self.guestCanCreateNotes.update(switchIsOn: createNotesPermission == .all)
    }

    @objc
    private func cancelHandler() {
        delegate?.didCancelEdit(from: self)
    }

    @objc
    private func saveHandler() {
        let hasChanged = { [weak self] (permission: GuestPermission) -> Bool in
            guard let self = self else { return false }
            let permissions = [self.viewData.guestPermission, self.originalGuestPermission]
            return permissions.filter({ $0 >= permission }).count == 1
        }
        if source == .eventEdit {
            CalendarTracerV2.EventAttendeeAuthSetting.traceClick {
                $0.click("save")
                $0.edit_event_alias = hasChanged(.guestCanModify).description
                $0.invite_attendee_alias = hasChanged(.guestCanInvite).description
                $0.show_attendee_list_alias = hasChanged(.guestCanSeeOtherGuests).description
            }
        }
        delegate?.didFinishEdit(from: self)
    }

    private func traceCalendarSetting(view: GuestPermission, isChecked: Bool) {
        guard source == .calendarSetting else { return }
        let clickMap: [GuestPermission: String] = [
            .guestCanInvite: "allow_attendee_invite",
            .guestCanModify: "allow_attendee_edit",
            .guestCanSeeOtherGuests: "allow_attendee_view_list"
        ]
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click(clickMap[view] ?? "")
            $0.is_checked = isChecked.description
        }
    }
}
