//
//  RecordLayoutSettingViewModel.swift
//  ByteView
//
//  Created by helijian on 2022/11/10.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

final class RecordLayoutSettingViewModel: UserSettingListener {

    let service: UserSettingManager
    var items: [RecordLayoutItem] = []
    private var updateAction: (() -> Void)?

    init(service: UserSettingManager) {
        self.service = service
        service.addListener(self, for: .viewUserSetting)
        self.items = generateItems(service.viewUserSetting.meetingAdvanced.recording.recordLayoutType)
    }

    func bindAction(_ action: (() -> Void)?) {
        updateAction = action
    }

    // 接收变更
    func didChangeUserSetting(_ manager: UserSettingManager, _ data: UserSettingChange) {
        if case let .viewUserSetting(change) = data {
            let type = change.value.meetingAdvanced.recording.recordLayoutType
            let items = generateItems(type)
            Util.runInMainThread {
                self.items = items
                self.updateAction?()
            }
        }
    }

    private func generateItems(_ recordLayout: ViewUserSetting.RecordLayoutType) -> [RecordLayoutItem] {
        var items = [RecordLayoutItem]()
        let updator = self.service
        let sideBySizeItem = RecordLayoutItem(isSelected: recordLayout == .sideLayout, layoutType: .sideLayout, action: {
            updator.updateViewUserSetting { $0.recordLayoutType = .sideLayout }
        })
        items.append(sideBySizeItem)
        let galleryItem = RecordLayoutItem(isSelected: recordLayout == .galleryLayout, layoutType: .galleryLayout, action: {
            updator.updateViewUserSetting { $0.recordLayoutType = .galleryLayout }
        })
        items.append(galleryItem)
        let fullScreenItem = RecordLayoutItem(isSelected: recordLayout == .fullScreenLayout, layoutType: .fullScreenLayout, action: {
            updator.updateViewUserSetting { $0.recordLayoutType = .fullScreenLayout }
        })
        items.append(fullScreenItem)
        let speakerItem = RecordLayoutItem(isSelected: recordLayout == .speakerLayout, layoutType: .speakerLayout, action: {
            updator.updateViewUserSetting { $0.recordLayoutType = .speakerLayout }
        })
        items.append(speakerItem)
        return items
    }
}
