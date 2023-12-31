//
//  ToolBarShareItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewUI

final class ToolBarShareItem: ToolBarItem {
    override var itemType: ToolBarItemType { .share }

    override var title: String {
        if Display.pad {
            return I18n.View_G_Share_Button
        } else {
            // 仅在本设备发起共享时，显示“重新共享”，否则显示“共享”
            return meeting.shareData.isSelfSharingContent ? I18n.View_VM_ShareNew : I18n.View_VM_ShareButton
        }
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsShareContent ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsShareContent ? .center : .none
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .shareScreenFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .shareScreenOutlined)
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.shareData.addListener(self, fireImmediately: false)
        meeting.setting.addListener(self, for: .showsShareContent)
        addBadgeListener()
    }

    override func clickAction() {
        provider?.generateImpactFeedback()
        MeetingTracksV2.trackMeetingClickOperation(action: .clickShare,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: false)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        // 发起共享/抢占共享鉴权
        if !isShareContentControlLegal() {
            return
        }
        shrinkToolBar { [weak self] in
            guard let self = self else {
                return
            }
            let shareContentViewModel = ShareContentSettingsViewModel(meeting: self.meeting)
            let isShareScreenEnabled = shareContentViewModel.shareContentEnabledConfig.isShareScreenEnabled
            let isMagicShareEnabled = shareContentViewModel.shareContentEnabledConfig.isMagicShareEnabled
            let isWhiteboardEnabled = shareContentViewModel.shareContentEnabledConfig.isWhiteboardEnable
            Logger.ui.debug("tapped tool bar share item, ss enabled: \(isShareScreenEnabled), ms enabled: \(isMagicShareEnabled), wb enabled: \(isWhiteboardEnabled)")
            if isMagicShareEnabled || isWhiteboardEnabled { // 可以发起妙享，则打开共享选择页面
                self.openShareContent(shareContentViewModel)
            } else if isShareScreenEnabled { // 禁止妙享，但可以发起共享屏幕，则直接发起共享屏幕
                if self.meeting.shareData.isOthersSharingContent {
                    ShareContentViewController.showShareChangeAlert { result in
                        switch result {
                        case .success:
                            shareContentViewModel.showShareScreenAlert()
                        case .failure:
                            break
                        }
                    }
                } else {
                    shareContentViewModel.showShareScreenAlert()
                }
            } else { // 妙享和共享屏幕都不可以发起，则无动作，此时不应显示ToolBarShareItem
                Logger.ui.warn("tap tool bar share item failed, due to ss and ms both disabled")
            }
        }
    }

    /// 发起/抢占共享鉴权
    /// - Returns: 是否可以继续发起/抢占共享
    private func isShareContentControlLegal() -> Bool {
        if !meeting.setting.canShareContent {
            // 如果无法保证有共享内容权限，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("share content is denied due to lack of permission")
            Toast.show(I18n.View_M_NoPermissionToShare)
            return false
        } else if meeting.shareData.isSharingContent && !meeting.shareData.isSelfSharingContent && !meeting.setting.canReplaceShareContent {
            // 如果此时已经在共享中，并且违背抢共享原则，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("replace share content is denied due to meeting permission")
            Toast.show(I18n.View_M_ShareAfterCurrentSessionEnds)
            return false
        } else if meeting.shareData.isMySharingScreen && !meeting.setting.isShareCcmEnabled && !meeting.setting.isNewCcmEnabled {
            // 如果共享二级页只有共享屏幕选项，且已经在共享屏幕，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("is already share screen")
            Toast.show(I18n.View_M_NowSharingToast)
            return false
        }
        return true
    }

    private func openShareContent(_ vm: ShareContentSettingsViewModel) {
        MagicShareTracks.trackShareContent(action: .shareContentClicked)
        MagicShareTracksV2.trackEnterShareWindow()
        let viewController = ShareContentViewController(viewModel: vm)
        meeting.router.presentDynamicModal(viewController,
                                          regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                          compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }
}

extension ToolBarShareItem: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        notifyListeners()
    }
}

extension ToolBarShareItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
