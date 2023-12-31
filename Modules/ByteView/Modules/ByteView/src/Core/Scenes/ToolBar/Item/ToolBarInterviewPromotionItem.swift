//
//  ToolBarInterviewPromotionItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewNetwork

final class ToolBarInterviewPromotionItem: ToolBarItem {
    private var manager: InMeetWebSpaceManager?
    private var hasShownGuide = false
    /// 标记接收自动开启网页事件
    private var receiveAutoOpenEvent = false

    override var itemType: ToolBarItemType { .interviewPromotion }

    override var title: String {
        if Display.pad {
            return I18n.View_G_CompanyInfo_Button
        } else {
            return meeting.webSpaceData.isWebSpace ? I18n.View_G_CollapsePage : I18n.View_G_OrganizationBackground_Toolbar
        }
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .buildingFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .buildingOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        shouldShow ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        shouldShow ? .right : .none
    }

    private var shouldShow: Bool {
        let hasData = manager?.hasData == true
        let isSharer = meeting.shareData.isSelfSharingContent // 主共享人不展示入口
        return receiveAutoOpenEvent && hasData && !isSharer
    }

    private var shouldShowGuide: Bool = false {
        didSet {
            if shouldShowGuide != oldValue {
                if shouldShowGuide {
                    showGuide()
                } else {
                    hideGuide()
                }
            }
        }
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.manager = resolver.resolve()
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        guard manager?.isWebspaceEnabled == true else { return }
        meeting.webSpaceData.addListener(self, fireImmediately: false)
        meeting.shareData.addListener(self, fireImmediately: false)
        meeting.addMyselfListener(self, fireImmediately: false)
        resolver.viewContext.addListener(self, for: [.contentScene])
        manager?.addListener(self, fireImmediately: false)
    }

    override func clickAction() {
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            MeetingTracksV2.trackClickEnterprisePromotion(isToolBar: true)
            let toggleWebSpace = !self.meeting.webSpaceData.isWebSpace
            self.meeting.webSpaceData.setWebSpaceShow(toggleWebSpace)
        }
    }

    private func updateGuide() {
        shouldShowGuide = receiveAutoOpenEvent && !hasShownGuide && shouldShow && !meeting.webSpaceData.isWebSpace
    }

    private func showGuide() {
        let desc = I18n.View_G_CompanyInfoOnboard
        let guide = GuideDescriptor(type: .interviewPromotion, title: nil, desc: desc)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in self?.hasShownGuide = true }
        guide.duration = 3
        GuideManager.shared.request(guide: guide)
    }

    private func hideGuide() {
        GuideManager.shared.dismissGuide(with: .interviewPromotion)
    }
}

extension ToolBarInterviewPromotionItem: InMeetWebSpaceDataObserver {

    func didAutoOpenWebSpace(_ isAutoOpen: Bool) {
        self.receiveAutoOpenEvent = true
        notifyListeners()
        // 自动开启网页时不显示 Guide
        guard !isAutoOpen else { return }
        Util.runInMainThread {
            self.updateGuide()
        }
    }
}

extension ToolBarInterviewPromotionItem: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .contentScene {
            notifyListeners()
        }
    }
}

extension ToolBarInterviewPromotionItem: InMeetWebSpaceDataListener {

    func didChangeWebSpace(_ isShow: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.updateGuide()
            self.notifyListeners()
        }
    }
}

extension ToolBarInterviewPromotionItem: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        notifyListeners()
    }
}

extension ToolBarInterviewPromotionItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        Util.runInMainThread {
            self.updateGuide()
            self.notifyListeners()
        }
    }
}
