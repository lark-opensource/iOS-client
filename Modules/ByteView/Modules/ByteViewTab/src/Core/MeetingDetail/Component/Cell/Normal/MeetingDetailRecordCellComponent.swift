//
//  MeetingDetailRecordCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import ByteViewCommon

class MeetingDetailRecordCellComponent: MeetingDetailCellComponent {

    override var title: String {
        I18n.View_G_RecordingFile
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.recordInfo.addObserver(self)
        viewModel.commonInfo.addObserver(self)
    }

    override var shouldShow: Bool {
        viewModel?.commonInfo.value?.meetingStatus == .meetingEnd && viewModel?.recordInfo.value != nil
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel,
              let meetingID = viewModel.meetingID,
              let recordInfo = viewModel.recordInfo.value,
              let model = viewModel.commonInfo.value else { return }

        titleLabel.justReplaceText(to: recordInfo.type == .larkMinutes ? I18n.View_SA_RecordingFileFeishuMinutes_Text : title)
        var itemData: [MeetingDetailFile] = []
        if !recordInfo.minutesInfoV2.isEmpty {
            let isLocked = recordInfo.minutesBreakoutInfo.contains { !$0.hasViewPermission }
            let isPending = recordInfo.minutesBreakoutInfo.contains { $0.status == .pending }
            for info in recordInfo.minutesInfoV2 {
                var minutesCount = 0
                if info.breakoutRoomID == 1 {
                    minutesCount = recordInfo.minutesBreakoutInfo.count + 1
                    if info.status == .pending || isPending {
                        let topic = info.topic.isEmpty ? model.meetingTopic : info.topic
                        itemData.insert(MeetingDetailFile(placeholderType: recordInfo.type, topic: topic, breakoutMinutesCount: minutesCount), at: 0)
                    } else {
                        let dataFile = MeetingDetailFile(info: info, icon: recordInfo.type.icon, viewModel: viewModel, breakoutMinutesCount: minutesCount)
                        if minutesCount > 0 {
                            dataFile.isLocked = isLocked || !info.hasViewPermission
                            dataFile.canForward = !dataFile.isLocked
                        }
                        itemData.insert(dataFile, at: 0)
                    }
                } else {
                    if info.status == .pending {
                        let topic = info.topic.isEmpty ? model.meetingTopic : info.topic
                        itemData.append(MeetingDetailFile(placeholderType: recordInfo.type, topic: topic, breakoutMinutesCount: 0))
                    } else {
                        itemData.append(MeetingDetailFile(info: info, icon: recordInfo.type.icon, viewModel: viewModel, breakoutMinutesCount: 0))
                    }
                }
            }
        }
        if !recordInfo.recordInfo.isEmpty {
            for info in recordInfo.recordInfo {
                if info.status == .pending {
                    itemData.append(MeetingDetailFile(placeholderType: recordInfo.type, topic: info.topic, isMinutes: false, breakoutMinutesCount: 0))
                } else {
                    itemData.append(MeetingDetailFile(info: info, icon: recordInfo.type.icon, viewModel: viewModel, breakoutMinutesCount: 0))
                }
            }
        }
        if itemData.isEmpty {
            if recordInfo.url.isEmpty {
                itemData.append(MeetingDetailFile(placeholderType: recordInfo.type, topic: model.meetingTopic, isMinutes: recordInfo.type == .larkMinutes))
            } else {
                let icon = recordInfo.type.icon
                if recordInfo.type == .record {
                    itemData = recordInfo.url.map { MeetingDetailFile(url: $0, topic: model.meetingTopic, icon: icon, meetingID: meetingID) }
                } else {
                    itemData = recordInfo.minutesInfo.map { MeetingDetailFile(info: $0, icon: icon, viewModel: viewModel) }
                }
            }
        }
        itemData.first(where: { $0.canForward && $0.isActive && $0.isMinutes })?.shouldShowOnboarding = true
        items = itemData
        tableView.reloadData()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_mm", "in_meeting": !self.isMeetingEnd])
        MeetTabTracks.trackClickMM()
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }

    override func forwardMinutes(_ urlString: String) {
        if let from = viewModel?.hostViewController {
            viewModel?.router?.forwardMessage(urlString, from: from)
        }
        MeetTabTracks.trackClickForwardMM()
    }

    override func openMinutesCollection(with data: MeetingDetailFile) {
        guard let hostViewController = viewModel?.hostViewController,
              let detail = viewModel else { return }
        let vm = MinutesCollcetionViewModel(detail: detail)
        let vc = MinutesCollectionViewController(viewModel: vm)
        if Display.pad {
            if let from = hostViewController.presentingViewController as? UINavigationController {
                hostViewController.dismiss(animated: true)
                from.pushViewController(vc, animated: true)
            } else {
                hostViewController.presentDynamicModal(vc,
                                                       regularConfig: .init(presentationStyle: .formSheet),
                                                       compactConfig: .init(presentationStyle: .pageSheet))
            }
        } else {
            hostViewController.navigationController?.pushViewController(vc, animated: true)
        }
        MeetTabTracks.trackClickMinutesCollection(with: viewModel?.meetingID ?? "")
    }

    override func openMinutes(with data: MeetingDetailFile) {
        if data.isLocked {
            let meetingID = viewModel?.meetingID ?? ""
            data.userName? { name in
                ByteViewDialog.Builder()
                    .id(.permissionOfMinutes)
                    .title(I18n.View_G_RequestViewFromOwner(name))
                    .message(I18n.View_G_ConfirmThenOwnerReceive)
                    .leftTitle(I18n.View_G_CancelButton)
                    .rightTitle(I18n.View_G_ConfirmButton)
                    .rightHandler { [weak self] _ in
                        self?.viewModel?.applyMinutesCollectionPermission()
                        VCTracker.post(name: .vc_minutes_popup_click, params: ["click": "confirm", "conference_id": meetingID, "popup_name": "apply_all_minutes"])
                    }
                    .show()
                VCTracker.post(name: .vc_minutes_popup_view, params: ["popup_name": "apply_all_minutes", "conference_id": meetingID])
            }
        } else {
            if let url = data.url {
                openURL(url)
            }
        }
    }
}

extension MeetingDetailRecordCellComponent: MeetingDetailRecordInfoObserver, MeetingDetailCommonInfoObserver {
    func didReceive(data: TabHistoryCommonInfo) {
        updateViews()
    }

    func didReceive(data: TabDetailRecordInfo) {
        updateViews()
    }
}
