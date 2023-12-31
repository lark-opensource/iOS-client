//
//  CalendarShareAuthSettingViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 8/18/23.
//

import Foundation
import LarkUIKit
import RxSwift
import RxRelay
import UniverseDesignActionPanel

protocol CalendarShareAuthSettingDelegate: AnyObject {
    func didFinishEdit(from: CalendarShareAuthSettingViewController, with members: [Rust.CalendarMember])

    func authSettingChanged(from: CalendarShareAuthSettingViewController, with members: [Rust.CalendarMember])
}

struct AuthRelatedContext {
    let calendarOwnerID: String
    let currentUID: String
    let isManager: Bool
    let shareOptions: Rust.CalendarShareOptions
}

class CalendarShareAuthSettingViewController: BaseUIViewController {

    typealias CellData = CalendarEditViewModel.CalendarMemberCellData

    weak var delegate: CalendarShareAuthSettingDelegate?

    private let rxCalendarMembers: BehaviorRelay<[Rust.CalendarMember]>
    private let authContext: AuthRelatedContext
    private let bag = DisposeBag()

    private let scrollView = UIScrollView()
    private let container = UIStackView()

    init(members: [Rust.CalendarMember], authContext: AuthRelatedContext) {
        rxCalendarMembers = .init(value: members)
        self.authContext = authContext
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Detail_PermissionSettingsTitle
        view.backgroundColor = .ud.bgBody
        setUpNavi()

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.axis = .vertical
        scrollView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.centerX.equalToSuperview()
        }

        bindData()
    }

    private func setUpNavi() {
        let confirmItem = LKBarButtonItem(title: I18n.Calendar_Common_Confirm, fontStyle: .medium)
        confirmItem.setBtnColor(color: .ud.primaryContentDefault)
        confirmItem.addTarget(self, action: #selector(confimBtnTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = confirmItem
    }

    private func bindData() {
        rxCalendarMembers
            .map { [weak self] members -> [CalendarMemberCellDataType] in
                guard let self = self else { return [] }
                return members.compactMap { member -> CalendarMemberCellDataType? in
                    guard member.status != .removed else { return nil }
                    let avatar = AvatarImpl(avatarKey: member.avatarKey, userName: member.name, identifier: member.memberID)

                    let calendarOwnerID = self.authContext.calendarOwnerID
                    let banned = [calendarOwnerID, self.authContext.currentUID]

                    let highestRole = self.authContext.shareOptions.topOption(
                        of: member.memberType,
                        isExternal: member.relationType == .external
                    ).cd.mappedAccessRole

                    let data = CellData(
                        avatar: avatar,
                        title: member.displayName,
                        isGroup: member.memberType == .group,
                        ownerTagStr: calendarOwnerID == member.memberID ? I18n.Calendar_Share_Owner : nil,
                        relationTagStr: member.relationTagStr,
                        role: member.accessRole,
                        highestRole: highestRole,
                        canJumpProfile: false,
                        isEditable: !banned.contains(where: { $0 == member.memberID }) && self.authContext.isManager
                    )
                    return data
                }
            }
            .subscribeForUI { [weak self] membersData in
                guard let self = self else { return }
                self.container.clearSubviews()
                membersData.forEach { content in
                    let memberCell = CalendarShareMemberCell()
                    memberCell.setUp(with: content)
                    memberCell.delegate = self
                    self.container.addArrangedSubview(memberCell)
                    memberCell.snp.makeConstraints { make in
                        make.height.equalTo(68)
                    }

                    let separator = UIView()
                    separator.backgroundColor = .ud.lineDividerDefault
                    let wrapper = UIView()
                    wrapper.addSubview(separator)
                    separator.snp.makeConstraints { make in
                        make.leading.equalToSuperview().inset(68)
                        make.height.equalTo(CalendarEditRoleSelectionView.UI.seperatorHeight)
                        make.trailing.top.bottom.equalToSuperview()
                    }
                    self.container.addArrangedSubview(wrapper)
                }
            }.disposed(by: bag)
    }

    private func updateMemberAccess(with id: String, role: Rust.CalendarAccessRole) {
        var members = rxCalendarMembers.value
        guard let memberIndex = rxCalendarMembers.value.firstIndex(where: { $0.memberID == id }),
              var member = members[safeIndex: memberIndex] else { return }
        member.accessRole = role
        members[memberIndex] = member
        rxCalendarMembers.accept(members)
        delegate?.authSettingChanged(from: self, with: members)
    }

    @objc
    private func confimBtnTapped() {
        self.delegate?.didFinishEdit(from: self, with: self.rxCalendarMembers.value)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarShareAuthSettingViewController: CalendarShareMemberCellDelegate {
    func cellDetail(from cell: CalendarShareMemberCell) {
        guard let cellData = cell.cellData else { return }
        guard cellData.isEditable else {
            change(toastStatus: .tips(I18n.Calendar_Detail_NoPermitEditHover, fromWindow: Display.pad))
            return
        }
        let editVC = CalendarShareMemberAuthViewController(memberData: cellData)
        editVC.roleChanged = { [weak self] role in
            self?.updateMemberAccess(with: cellData.avatar.identifier, role: role)
        }
        if Display.pad {
            editVC.preferredContentSize = .init(width: 375, height: editVC.panelHeight)
            editVC.modalPresentationStyle = .popover
            editVC.popoverPresentationController?.sourceView = cell.roleLabel
            editVC.popoverPresentationController?.permittedArrowDirections = [.right]
            editVC.popoverPresentationController?.delegate = self
            self.present(editVC, animated: true)
        } else {
            let actionPanel = UDActionPanel(customViewController: editVC,
                                            config: .init(originY: UIScreen.main.bounds.height - editVC.contentHeight))
            self.navigationController?.present(actionPanel, animated: true)
        }
    }

    func profileTapped(from cell: CalendarEditMemberCell) { }
}

extension CalendarShareAuthSettingViewController: UIPopoverPresentationControllerDelegate { }
