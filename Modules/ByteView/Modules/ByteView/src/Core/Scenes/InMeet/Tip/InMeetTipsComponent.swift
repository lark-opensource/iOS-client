//
//  InMeetTipsComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import ByteViewUI
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

/// Tips
/// - 提供LayoutGuide：tips
final class InMeetTipsComponent: InMeetViewComponent {
    let maxTipCount = 2
    var tipViewList = [TipView]()
    var tipInfos = [TipInfo]()

    let tips: InMeetTipViewModel
    let meeting: InMeetMeeting
    weak var container: InMeetViewContainer?
    private let resolver: InMeetViewModelResolver
    private lazy var noticeGuideToken: MeetingLayoutGuideToken? = {
        return container?.layoutContainer.requestLayoutGuideFactory({ ctx in
            let query = InMeetOrderedLayoutGuideQuery(topAnchor: ctx.isSingleVideoVisible ? .topSingleVideoNaviBar : .topFloatingExtendBar,
                                                      bottomAnchor: .bottom)
            return query
        })
    }()
    private var currentLayoutType: LayoutType
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.tips = viewModel.resolver.resolve()!
        self.resolver = viewModel.resolver
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        //self.noticeGuideToken = container.layoutContainer.requestOrderedLayoutGuide(topAnchor: .topFloatingStatusBar, bottomAnchor: .bottom)
        viewModel.viewContext.addListener(self, for: [.singleVideo])
        tips.addObserver(self)
        tips.initializeInfo()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .tips
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        // 初始化客服服务
        larkRouter.launchCustomerService()
        let infos = tips.tipInfos
            .filter { !$0.hasBeenClosedManually && !$0.isDismissInfo }
        self.tipInfos = Array(infos[0..<min(infos.count, maxTipCount)])
        Util.runInMainThread {
            self.updateTips()
        }
    }

    private func handleTipInfo(_ tipInfo: TipInfo) {
        for (index, info) in tipInfos.enumerated() where info == tipInfo {
            self.updateTipInfo(tipInfo, at: index)
            return
        }
        if !tipInfo.hasBeenClosedManually, !tipInfo.isDismissInfo {
            addTipInfo(tipInfo)
        }
    }

    private func updateTipInfo(_ tipInfo: TipInfo, at index: Int) {
        if index >= tipViewList.count {
            return
        }
        tipInfos[index] = tipInfo
        let tipView = tipViewList[index]
        if tipView.tipInfo?.isUpdateInfo(of: tipInfo) == false, // 判断重新展示还是对当前Tip进行更新
           let snapshot = tipView.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = tipView.frame
            tipView.superview?.addSubview(snapshot)
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.3, animations: {
                snapshot.alpha = 0.0
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        }

        if !tipInfo.isDismissInfo {
            tipView.presentTipInfo(tipInfo: tipInfo, animated: false)
            tipInfo.trackDisplayIfNeeded(isSuperAdministrator: meeting.setting.isSuperAdministrator, isFirstPresent: false)
        } else if tipInfo.isDismissInfo(of: tipView.tipInfo) {
            self.tryDismissTipInfo(tipInfo)
        }
    }

    func addTipInfo(_ info: TipInfo) {
        var infos = self.tipInfos
        if infos.count >= maxTipCount {
            if let index = infos.firstIndex(where: { $0.canCover }) {
                let info = infos.remove(at: index)
                info.hasBeenClosedManually = true
            }
        }

        if infos.count < maxTipCount {
            infos.append(info)
            self.tipInfos = infos
            updateTips()
        }
    }

    func removeInfo(_ info: TipInfo) {
        tipInfos.removeAll { $0 == info }
        updateTips()
    }

    private func updateTips() {
        let infos = tipInfos
        var views = tipViewList
        let infoCount = infos.count
        let viewCount = views.count
        if viewCount > infoCount {
            for index in infoCount ..< viewCount {
                views[index].removeFromSuperview()
            }
            views = Array(views[0..<infoCount])
            self.tipViewList = views
        } else if viewCount < infoCount {
            for _ in viewCount..<infoCount {
                let tipView = TipView(frame: .zero)
                tipView.layer.cornerRadius = 8
                tipView.layer.ud.setShadow(type: .s4Down)
                tipView.clipsToBounds = false
                tipView.delegate = self
                container?.addContent(tipView, level: .tips)
                views.append(tipView)
                self.tipViewList = views
                self.updateConstraints()
            }
        }

        for index in 0..<infoCount {
            let tipInfo = infos[index]
            views[index].presentTipInfo(tipInfo: tipInfo, animated: false)
            let isFirstPresent = index >= viewCount
            tipInfo.trackDisplayIfNeeded(isSuperAdministrator: meeting.setting.isSuperAdministrator, isFirstPresent: isFirstPresent)
        }
    }

    @objc
    private func didChangeOrientation() {
        Util.runInMainThread { [weak self] in
            self?.updateConstraints()
        }
    }

    private func updateConstraints() {
        guard let container = container, !tipViewList.isEmpty else {
            return
        }

        let views = tipViewList
        let isPhoneLandscape = currentLayoutType.isPhoneLandscape
        let isRegular = currentLayoutType.isRegular
        var topView = views[0]
        for index in 0 ..< views.count {
            let tipView = views[index]
            tipView.snp.remakeConstraints { make in
                if isRegular {
                    make.centerX.equalToSuperview()
                    make.width.greaterThanOrEqualTo(375).priority(.veryHigh)
                    make.width.lessThanOrEqualTo(600).priority(.veryHigh)
                    make.left.greaterThanOrEqualToSuperview().offset(8.0)
                    make.right.lessThanOrEqualToSuperview().offset(-8.0)
                } else {
                    if !isPhoneLandscape {
                        make.left.right.equalToSuperview().inset(8)
                    } else {
                        let inset = Display.iPhoneXSeries ? 0 : 8
                        make.left.right.equalTo(container.view.safeAreaLayoutGuide).inset(inset)
                    }
                }
                if index == 0 {
                    if let accessory = noticeGuideToken?.layoutGuide {
                        make.top.equalTo(accessory).inset(8)
                    } else {
                        make.top.equalTo(container.view.safeAreaLayoutGuide).inset(8)
                    }
                } else {
                    make.top.equalTo(topView.snp.bottom).offset(8.0)
                }
                topView = tipView
            }
        }
    }

    // 延时关闭
    private func tryDismissTipInfo(_ tipInfo: TipInfo) {
        let hasPresentedTime = Date().timeIntervalSince1970 - tipInfo.presentedTime
        if hasPresentedTime < tipInfo.timeout {
            let timeLeft = tipInfo.timeout - hasPresentedTime
            DispatchQueue.main.asyncAfter(deadline: .now() + timeLeft) { [weak self] in
                self?.tips.closeTip(tipInfo)
            }
        } else {
            tips.closeTip(tipInfo)
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        currentLayoutType = newContext.layoutType
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh || oldContext.layoutType != newContext.layoutType {
            updateConstraints()
        }
    }
}

extension InMeetTipsComponent: InMeetTipViewModelObserver {
    func didUpdateTipInfo(_ tipInfo: TipInfo) {
        Util.runInMainThread {
            self.handleTipInfo(tipInfo)
        }
    }

    func didCloseTipInfo(_ tipInfo: TipInfo) {
        Util.runInMainThread {
            self.removeInfo(tipInfo)
        }
    }
}

extension InMeetTipsComponent: TipViewDelegate {
    var larkRouter: LarkRouter { meeting.larkRouter }

    func tipViewDidClickLeadingButton(_ sender: UIButton, tipInfo: TipInfo) {
        switch tipInfo.type {
        case .autoRecordSettingJump:
            meeting.router.setWindowFloating(true)
            larkRouter.gotoGeneralSettings(source: "autoRecordSettingJump")
        case .interviewerTipsAddDisappear:
            meeting.httpClient.send(CloseInterviewerNoticeRequest(meetingID: meeting.meetingId))
            tipInfo.hasBeenClosedManually = true
            self.removeInfo(tipInfo)
            MeetingTracksV2.trackTipDontRemindAgain(clickTarget: "dont_remind_again")
        case .callmePhone:
            self.removeInfo(tipInfo)
            self.meeting.audioModeManager.cancelPstnCall()
            VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "call_me"])
        case .largeMeeting:
            tips.gotoHostControl()
            tipInfo.hasBeenClosedManually = true
            self.removeInfo(tipInfo)
        default:
            break
        }
        tipInfo.operationButtonAction?()
    }

    func tipViewDidClickClose(_ sender: UIButton, tipInfo: TipInfo) {
        Logger.meeting.info("close tips manually: \(tipInfo.content)")
        tipInfo.hasBeenClosedManually = true
        self.removeInfo(tipInfo)
        if tipInfo.type == .interviewerTipsAddDisappear {
            MeetingTracksV2.trackTipDontRemindAgain(clickTarget: "close")
        }
        tipInfo.closeButtonAction?()
    }

    func tipViewDidTapLeadingButton(tipInfo: TipInfo) {
        if tipInfo.type == .callmePhone {
            self.removeInfo(tipInfo)
        }
    }

    func tipViewDidTapLink(tipInfo: TipInfo) {
        /// 后端检测到实际口说语言与当前记录的口说语言不一致，弹出Tips提示用户修改
        if tipInfo.type == .subtitleSettingJump, !meeting.setting.subtitleDeleteSpokenLanguage {
            SubtitleTracks.trackSubtitleSettings(from: "mismatch_language_tip")
            let viewController = meeting.setting.ui.createSubtitleSettingViewController(context: SubtitleSettingContext(fromSource: .inMeetTip))
            let vc = NavigationController(rootViewController: viewController)
            vc.modalPresentationStyle = .fullScreen
            meeting.router.present(vc)
        } else if let type = tipInfo.noticeInfo?.msgI18NKey?.type {
            switch type {
            case .schemeJump:
                meeting.router.setWindowFloating(true)
                larkRouter.goto(scheme: tipInfo.scheme ?? "")
            case .upgradeJump:
                meeting.router.setWindowFloating(true)
                larkRouter.gotoUpgrade()
            case .customerJump:
                meeting.router.setWindowFloating(true)
                larkRouter.gotoCustomer()
            default:
                break
            }
        } else if let scheme = tipInfo.scheme, !scheme.isEmpty {
            meeting.router.setWindowFloating(true)
            larkRouter.goto(scheme: scheme)
        } else if let action = tipInfo.linkTapAction {
            action()
        }
        tipInfo.trackClickIfNeeded(isSuperAdministrator: meeting.setting.isSuperAdministrator)
    }
}

extension InMeetTipsComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        updateConstraints()
    }
}
