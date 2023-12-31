//
//  CalendarEditViewController+Members.swift
//  Calendar
//
//  Created by Hongbin Liang on 6/6/23.
//

import Foundation
import LarkUIKit
import LarkModel
import LarkAlertController
import UniverseDesignToast
import UniverseDesignActionPanel

extension CalendarEditViewController: UIPopoverPresentationControllerDelegate { }

extension CalendarEditViewController: CalendarEditMemberCellDelegate {
    func cellDetail(from cell: CalendarEditMemberCell) {
        guard let cellData = cell.cellData else { return }
        let editVC = MembersEditViewController(memberData: cellData)
        editVC.roleChanged = { [weak self] role in
            self?.viewModel.updateMemberAccess(with: cellData.avatar.identifier, role: role)
        }
        editVC.deleteHandler = { [weak self] in
            self?.viewModel.deleteMember(with: cellData.avatar.identifier)
        }
        if Display.pad {
            editVC.preferredContentSize = .init(width: 375, height: editVC.contentHeight)
            editVC.modalPresentationStyle = .popover
            editVC.popoverPresentationController?.sourceView = cell
            editVC.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            editVC.popoverPresentationController?.delegate = self
            self.present(editVC, animated: true)
        } else {
            let actionPanel = UDActionPanel(customViewController: editVC,
                                            config: .init(originY: UIScreen.main.bounds.height - editVC.contentHeight))
            self.navigationController?.present(actionPanel, animated: true)
        }
    }

    func profileTapped(from cell: CalendarEditMemberCell) {
        guard let chatterID = cell.cellData?.avatar.identifier else { return }
        viewModel.calendarDependency?.presentToProfile(
            chatterId: chatterID,
            eventTitle: "",
            from: self
        )
    }
}

extension CalendarEditViewController: SearchPickerDelegate {

    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) -> Bool {
        guard viewModel.predicateMemberShareable(member: item) else {
            UDToast.showTips(with: I18n.Calendar_Setting_NoShareExternal, on: pickerVc.view)
            return false
        }
        return true
    }

    func pickerForceSelectedItem(_ item: PickerItem) -> Bool {
        viewModel.forcedSelectMemebers.contains { $0.id == item.id }
    }

    func pickerDisableItem(_ item: PickerItem) -> Bool {
        !viewModel.predicateMemberShareable(member: item)
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        let result = items.compactMap { item -> CalendarMemberSeed? in
            switch item.meta {
            case .chat(let chatInfo):
                return .group(chatId: chatInfo.id, avatarKey: chatInfo.avatarKey ?? "")
            case .chatter(let chatterInfo):
                return .user(chatterId: chatterInfo.id, avatarKey: chatterInfo.avatarKey ?? "")
            default: return nil
            }
        }

        guard !result.isEmpty else {
            viewModel.addMember(with: [], message: nil)
            return true
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: I18n.Calendar_Share_SeparateWith, alignment: .left)

        let content = MessageLeavingContentView()

        let message = self.viewModel.rxMessageToLeave.value

        let avatarInfos: [AvatarInfoTuple] = result.map {
            switch $0 {
            case .group(let chatId, let avatarKey):
                return (chatId, avatarKey)
            case .user(let chatterId, let avatarKey):
                return (chatterId, avatarKey)
            }
        }

        content.setupContent(
            with: message, avatars: avatarInfos,
            tip: I18n.Calendar_Setting_MessageSentViaAssistant
        )
        alertController.setContent(view: content)
        alertController.addCancelButton()
        alertController.addPrimaryButton(
            text: BundleI18n.Calendar.Calendar_Common_Confirm,
            dismissCompletion: { [weak self, weak pickerVc] in
                let text = content.inputTextView.text
                self?.viewModel.addMember(with: result, message: text)
                pickerVc?.dismiss(animated: true)
            }
        )
        pickerVc.present(alertController, animated: true)
        return false
    }
}
