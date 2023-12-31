//
//  SIPInviteViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/10/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import LarkSegmentedView

final class SIPInviteViewController: VMViewController<SIPInviteViewModel>, UITableViewDataSource, UITableViewDelegate {
    private static func processH323Text(_ text: String) -> String {
        // https://bytedance.feishu.cn/docs/doccniyQtgdHakN4WMl9D5AnTYF#
        // 仅支持输入「数字、字母、标点符号」，1～64 字符限制；
        let newText = text.filter({ $0.isASCII })
        if newText.count > 64 {
            return newText[0..<64]
        } else {
            return newText
        }
    }
    private var currentMeetingRoomType: MeetingRoomType = .sip
    fileprivate let meetingRoomTypes: [MeetingRoomType] = [.sip, .h323]
    fileprivate lazy var selectionViews: [SingleSelectionView] = {
        meetingRoomTypes.map {
            let view = SingleSelectionView()
            view.title = $0.title
            view.isOn = currentMeetingRoomType == $0
            return view
        }
    }()
    fileprivate var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = I18n.View_G_InviteRoomSystemPlaceholder
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.textColor = UIColor.ud.textTitle
        textField.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
//        textField.clearButtonMode = .whileEditing
        return textField
    }()

    lazy var tableView: UITableView = {
        let tableView = BaseGroupedTableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        return tableView
    }()

    lazy var commitButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_VM_CallButton, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.backgroundColor = UIColor.ud.fillDisabled
        button.isEnabled = false
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleButtonClick), for: .touchUpInside)
        return button
    }()

    lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 48 + 8)) // 横屏需要top边距8
        view.addSubview(commitButton)
        commitButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.top.equalToSuperview().offset(8)
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        //title = I18n.View_G_InviteBySIP
        setNavigationBarBgColor(.ud.bgFloatBase)
        view.backgroundColor = UIColor.ud.bgFloatBase

        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview()
        }
        view.addSubview(footerView)
        footerView.snp.makeConstraints { (make) in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(48)
            make.top.equalTo(tableView.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Display.iPhoneXSeries ? -8 : -16)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        doPageTrack()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private func createRightView(_ textField: UITextField?) {
        let clearButton = UIButton()
        clearButton.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: .ud.iconN3, size: CGSize(width: 20, height: 20)), for: .normal)
        clearButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        let container = UIView()
        container.addSubview(clearButton)
        clearButton.snp.makeConstraints { (maker) in
            maker.top.bottom.right.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(6)
        }
        textField?.rightViewMode = .always
        textField?.rightView = container

        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    }

    @objc
    private func handleTextChanged() {
        if currentMeetingRoomType == .h323,
           let text = textField.text {
            let newText = Self.processH323Text(text)
            if newText != text {
                textField.text = newText
            }
        }
        let isEnabled = !(textField.text?.isEmpty ?? true)
        if isEnabled {
            self.createRightView(textField)
        } else {
            textField.rightView = nil
        }
        commitButton.isEnabled = isEnabled
    }

    @objc
    private func clearText() {
        textField.text = ""
        textField.rightView = nil
    }

    @objc
    private func handleTap() {
        textField.resignFirstResponder()
    }

    @objc
    private func handleButtonClick() {
        MeetingTracks.trackTabSIPCallClick(roomType: currentMeetingRoomType.trackName)
        MeetingTracksV2.trackSIPInviteButtonClick(roomType: currentMeetingRoomType,
                                                  isMeetingLocked: viewModel.meeting.setting.isMeetingLocked)
        viewModel.inviteUser(type: currentMeetingRoomType.participantType, address: textField.text ?? "")
        doBack()
    }

    private func doPageTrack() {
        VCTracker.post(name: .vc_meeting_room_system_invite_view)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? meetingRoomTypes.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.contentView.backgroundColor = .ud.bgFloat
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            let selectionView = selectionViews[indexPath.row]
            cell.contentView.addSubview(selectionView)
            selectionView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }

            if indexPath.row == 0 {
                cell.addBorder(edges: [.bottom], color: UIColor.ud.lineDividerDefault, thickness: 0.5)
            }
        } else if indexPath.section == 1 {
            cell.contentView.addSubview(textField)
            textField.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        label.text = section == 0 ? I18n.View_MV_CallingProtocol : I18n.View_MV_RoomCallAddress_GreySubtitle
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(2)
            make.height.equalTo(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        38
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 1 ? 28 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            currentMeetingRoomType = meetingRoomTypes[indexPath.row]
            for (i, view) in selectionViews.enumerated() {
                view.isOn = i == indexPath.row
            }
            if indexPath.row == 0 {
                textField.placeholder = I18n.View_G_InviteRoomSystemPlaceholder
                textField.keyboardType = .default
            } else if indexPath.row == 1 {
                textField.placeholder = I18n.View_MV_AddressNumber_PleaseEnterMeetingRoomSystem
                textField.keyboardType = .asciiCapable
                if let text = textField.text {
                    textField.text = Self.processH323Text(text)
                }
            }
        }
    }
}

enum MeetingRoomType {
    case sip
    case h323

    var title: String {
        switch self {
        case .sip: return I18n.View_MV_InviteMeetingSystem_SipTick
        case .h323: return I18n.View_MV_MeetingRoomSystem_ThreeTwoThreeTick
        }
    }

    var trackName: String {
        switch self {
        case .sip: return "sip"
        case .h323: return "h323"
        }
    }

    var participantType: ParticipantType {
        switch self {
        case .sip: return .sipUser
        case .h323: return .h323User
        }
    }
}

// MARK: - JXSegmentedListContainerViewListDelegate
extension SIPInviteViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
