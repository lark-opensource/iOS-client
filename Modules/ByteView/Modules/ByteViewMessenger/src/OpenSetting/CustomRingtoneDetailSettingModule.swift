//
//  CustomRingtoneDetailSettingModule.swift
//  ByteViewMessenger
//
//  Created by kiri on 2023/6/3.
//

import Foundation
import ByteViewCommon
import ByteViewSetting
import ByteViewTracker
import ByteViewInterface
import LarkContainer
import LarkOpenSetting
import LarkSettingUI
import UniverseDesignLoading
import UniverseDesignToast

final class CustomRingtoneDetailSettingModule: BaseModule, UserSettingListener {
    @RwAtomic
    private var customizeRingtoneItem: String?
    private var type: CustomRingtoneType {
        if customizeRingtoneItem == CustomRingtoneType.spring.ringtoneName {
            return .spring
        } else {
            return .default
        }
    }
    @RwAtomic
    private var isLoading: Bool = false
    private static let logger = Logger.getLogger("CustomRingtone")

    private var setting: UserSettingManager? { try? userResolver.resolve(assert: UserSettingManager.self) }
    private let player: CustomRingtoneService?

    override init(userResolver: UserResolver) {
        self.player = try? userResolver.resolve(assert: CustomRingtoneService.self)
        super.init(userResolver: userResolver)
        setting?.addListener(self, for: .viewUserSetting)
        self.customizeRingtoneItem = setting?.customRingtone
        self.context?.reload()
        VCTracker.post(name: .setting_detail_click, params: [.click: "meeting_ring"])
    }

    deinit {
        player?.stopPlayRingtone()
    }

    /// 内容
    private lazy var loadingView: UDSpin = UDLoading.presetSpin(
        color: .primary,
        loadingText: nil,
        textDistribution: .vertial
    )

    override func createSectionProp(_ key: String) -> SectionProp? {
        let currentType = self.type
        let defaultSelected = currentType == .`default`
        let springSelected = currentType == .spring
        let defaultCellAccessory: LarkSettingUI.NormalCellAccessory
        let springCellAccessory: LarkSettingUI.NormalCellAccessory
        switch (defaultSelected, isLoading) {
        case (true, true):
            defaultCellAccessory = .custom({ [weak self] in
                self?.loadingView.reset()
                return self?.loadingView ?? UDLoading.presetSpin(
                    color: .primary,
                    loadingText: nil,
                    textDistribution: .vertial
                )
            })
        default:
            defaultCellAccessory = .checkMark(isShown: defaultSelected)
        }
        switch (springSelected, isLoading) {
        case (true, true):
            springCellAccessory = .custom({ [weak self] in
                self?.loadingView.reset()
                return self?.loadingView ?? UDLoading.presetSpin(
                    color: .primary,
                    loadingText: nil,
                    textDistribution: .vertial
                )
            })
        default:
            springCellAccessory = .checkMark(isShown: springSelected)
        }

        let defaultRingtone = NormalCellProp(title: I18n.View_G_DefaultRingtone,
                                             accessories: [defaultCellAccessory],
                                             onClick: { [weak self] _ in
            self?.update(type: .`default`)
        })
        let springRingtone = NormalCellProp(title: I18n.View_G_UpbeatRingtone,
                                            accessories: [springCellAccessory],
                                            onClick: { [weak self] _ in
            self?.update(type: .spring)
        })
        return SectionProp(items: [defaultRingtone, springRingtone])
    }

    private func update(type: CustomRingtoneType) {
        let needStop = type == self.type
        if needStop && (player?.isPlayingRingtone() ?? false) {
            player?.stopPlayRingtone()
            return
        }
        if needStop && !(player?.isPlayingRingtone() ?? false) {
            player?.stopPlayRingtone()
        }
        updateUseCustomizeRingtone(type)
    }

    // 设置铃声
    private func updateUseCustomizeRingtone(_ type: CustomRingtoneType) {
        player?.playRingtone(url: type.ringtoneURL)
        let customizeRingtoneRecent = type.ringtoneName
        if self.customizeRingtoneItem == customizeRingtoneRecent { return }
        let tempOldValue = self.customizeRingtoneItem
        self.customizeRingtoneItem = customizeRingtoneRecent
        Self.logger.info("setCustomizeRingtone start, old:\(tempOldValue ?? "<nil>"), new:\(customizeRingtoneRecent)")
        isLoading = true
        self.context?.reload()
        self.setting?.updateCustomRingtone(customizeRingtoneRecent, completion: { [weak self] result in
            Util.runInMainThread {
                guard let self = self else { return }
                self.isLoading = false
                self.customizeRingtoneItem = self.setting?.customRingtone
                self.context?.reload()
                Self.logger.info("setCustomizeRingtone completed, n:\(self.customizeRingtoneItem)")
                if case .failure = result {
                    if let view = self.context?.vc?.view {
                        UDToast.showTips(with: I18n.Lark_Legacy_UpdateCheckNet, on: view)
                    }
                    self.player?.stopPlayRingtone()
                }
            }
        })
    }

    func didChangeUserSetting(_ settings: UserSettingManager, _ change: UserSettingChange) {
        if case let .viewUserSetting(obj) = change {
            let val = obj.value.meetingGeneral.ringtone
            if self.customizeRingtoneItem != val {
                self.customizeRingtoneItem = val
                self.context?.reload()
            }
        }
    }
}
