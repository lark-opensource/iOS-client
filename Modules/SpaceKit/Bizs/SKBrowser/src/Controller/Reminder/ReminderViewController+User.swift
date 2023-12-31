//
// Created by duanxiaochen.7 on 2020/10/30.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignToast

extension ReminderViewController: BTMemberPanelDelegate {
    public func quickAddViewClick() {}
    
    public func trackSearchStartEdit() {}
    
    public func trackSelectCell() {}
    
    public func trackCancel() {}
    

    public func setUserItem(isHidden: Bool) {
        userItemView.isHidden = isHidden
        userItemView.snp.updateConstraints { (make) in
            make.height.equalTo(isHidden ? 0 : 60)
        }
    }

    public func showUserPicker() {
        destroyKeyboardObservation()
        let maxSelectCount = 500
        let panel = BTChatterPanel(context.docsInfo, hostView: view, openSource: .sheetReminder, isSubmitMode: false, maxSelectCount: maxSelectCount)
        panel.delegate = self // delegate 必须在 BTUserPanel 初始化完成之后再设置，不然 bindUI 会调用到 delegate 方法，造成不可避免的影响
        userPicker = panel

        if let selection = reminder.notifyUsers?.map({ $0.asSTModel }) {
            panel.updateSelected(selection)
        }
        panel.isMultipleMembers = true
        panel.titleLabel.text = BundleI18n.SKResource.Doc_Reminder_Notify_Person

        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.layoutIfNeeded()
        panel.show()
    }
    
    public func doSelect(_ panel: BTChatterPanel, chatters: [BTChatterProtocol], currentChatter: BTChatterProtocol?, trackInfo: BTTrackInfo, noUpdateChatterData: Bool, completion: ((BTChatterProtocol?) -> Void)?) {
        // 什么都不做，仅在结束选择后一次性提交结果

    }

    public func exceedSelectionAmount() {
        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Reminder_Toast_RecipientMax, on: view.window ?? view)
        sheetStatisticsCallback?("show_reminder_limit_toast", "reminder_person_num")
    }

    public func saveNotifyStrategy(notifiesEnabled: Bool) {}
    public func obtainLastNotifyStrategy() -> Bool { return true }

    public func finishSelecting(_ panel: BTChatterPanel, type: BTChatterType, chatters: [BTChatterProtocol], notifiesEnabled: Bool, trackInfo: BTTrackInfo, justUpdateChatterData: Bool, noUpdateChatterData: Bool) {
        userPicker?.removeFromSuperview()
        userPicker = nil
        let models: [ReminderUserModel] = chatters.map { (stModel) -> ReminderUserModel in
            ReminderUserModel(id: stModel.chatterId, name: stModel.name, enName: stModel.enName, avatarURL: stModel.avatarUrl)
        }
        updateReminderUser(to: models)
        setupKeyboardObservation()
    }
    
    public func didClickItem(with model: BTCapsuleModel, fileName: String?) {
        guard let fromVC = self.navigationController else {
            spaceAssertionFailure("fromVC cannot be nil")
            return
        }
        HostAppBridge.shared.call(ShowUserProfileService(userId: model.userID, fileName: fileName, fromVC: fromVC))
    }

    public func removeUserPicker() {
        userPicker?.hide(immediately: false)
    }

    /// 更新提醒人员数据
    public func updateReminderUser(to newUsers: [ReminderUserModel]) {
        if newUsers.isEmpty && (reminder.notifyUsers?.isEmpty == false) && noticeSelectedRow.value != 0 {
            noticeSelectedRow.accept(0)
            setUserItem(isHidden: true)
            setTextItem(isHidden: true)
        }
        reminder.notifyUsers = newUsers
        userItemView.rightView.updateArray(with: newUsers)
    }

    ///Docx reminder提醒人详情
    public func setMentionDetail(text: [String]?) {
        guard var detailText = text, !detailText.isEmpty else { return }
        var omitString = ""
        if detailText.count > 7 {
            //@超过7个人，显示等{number}人
            omitString = BundleI18n.SKResource.CreationMobile_DocX_remider_SendTo_part2(detailText.count)
            detailText = detailText.dropLast(detailText.count - 7)
        }
        let detail = BundleI18n.SKResource.CreationMobile_DocX_remider_SendTo_part1 + detailText.joined(separator: BundleI18n.SKResource.CreationMobile_DocX_common_punctuation_comma) + omitString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        paragraphStyle.lineBreakMode = .byWordWrapping
        mentionDetailLabel.attributedText = NSMutableAttributedString(string: detail, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }
}
