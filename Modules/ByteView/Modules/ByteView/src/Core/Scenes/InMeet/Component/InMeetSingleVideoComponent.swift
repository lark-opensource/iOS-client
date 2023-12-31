//
//  InMeetSingleVideoComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RxSwift
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

/// 单流放大
final class InMeetSingleVideoComponent: InMeetViewComponent {
    let disposeBag = DisposeBag()
    var singleVideoViewController: SingleVideoViewController?
    let view: UIView
    let context: InMeetViewContext
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    private let actionService: ParticipantActionService
    weak var container: InMeetViewContainer?
    private var topBarLayoutToken: MeetingLayoutGuideToken?
    private var currentLayoutType: LayoutType
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.context = viewModel.viewContext
        self.resolver = viewModel.resolver
        self.currentLayoutType = layoutContext.layoutType
        self.view = container.loadContentViewIfNeeded(for: .singleVideo)
        self.container = container
        self.actionService = ParticipantActionService(meeting: meeting, context: context)
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: .isVoiceModeOn)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .singleVideo
    }

    var childViewControllerForStatusBarStyle: InMeetOrderedViewController? {
        if let vc = singleVideoViewController {
            return InMeetOrderedViewController(statusStyle: .singleVideo, vc)
        } else {
            return nil
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        currentLayoutType = newContext.layoutType
    }

    func showSingleVideo(pid: ByteviewUser, from view: UIView, avatarView: UIView) {
        MeetingTracks.trackSingleVideoZoomIn()
        if self.singleVideoViewController != nil {
            return
        }

        guard let vm = resolver.resolve(InMeetGridViewModel.self)?.newSingleVideoViewModel(pid: pid) else {
            return
        }
        Logger.ui.debug("show single video \(pid.deviceId)")
        let startFrame = self.view.convert(view.bounds, from: view)
        let avatarSize = avatarView.frame.size
        let viewController = SingleVideoViewController(viewModel: vm)
        self.singleVideoViewController = viewController
        viewController.delegate = self
        container?.addContent(viewController, level: .singleVideo)
        viewController.view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        topBarLayoutToken = container?.layoutContainer.registerAnchor(anchor: .topSingleVideoNaviBar)
        // nolint-next-line: magic number
        viewController.show(startFrame: startFrame, avatarSize: avatarSize, duration: 0.25, alongsideTransition: { [weak self] in
            self?.updateSingleVideoNaviBarLayoutToken()
            self?.context.isSingleVideoVisible = true
            self?.container?.setNeedsStatusBarAppearanceUpdate()
        })
    }

    private func updateSingleVideoNaviBarLayoutToken() {
        guard let token = topBarLayoutToken, let singleVideoVC = self.singleVideoViewController else { return }
        token.layoutGuide.snp.remakeConstraints({ make in
            make.edges.equalTo(singleVideoVC.topBar)
        })
    }

    func hideSingleVideo(animated: Bool = true) {
        MeetingTracks.trackSingleVideoZoomOut()
        guard let viewController = self.singleVideoViewController else {
            return
        }

        topBarLayoutToken?.invalidate()
        self.singleVideoViewController = nil
        viewController.willMove(toParent: nil)
        // nolint-next-line: magic number
        viewController.hide(duration: animated ? 0.25 : 0, alongsideTransition: { [weak self] in
            self?.context.isSingleVideoVisible = false
            self?.container?.setNeedsStatusBarAppearanceUpdate()
        }, completion: { _ in
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            Logger.ui.debug("hide single video animated:\(animated)")
        })
    }

    private func presentByPopover(_ vc: ParticipantActionViewController, sourceView: UIView) {
        let originBounds = sourceView.bounds
        let sourceRect = CGRect(x: originBounds.minX - 4,
                                y: originBounds.minY - 4,
                                width: originBounds.width + 8,
                                height: originBounds.height + 8)
        let margins = ParticipantActionViewController.Layout.popoverLayoutMargins
        let config = DynamicModalPopoverConfig(sourceView: sourceView,
                                               sourceRect: sourceRect,
                                               backgroundColor: UIColor.ud.bgBody,
                                               popoverSize: .zero,
                                               popoverLayoutMargins: .init(edges: margins))
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: config, backgroundColor: .clear)
        meeting.router.presentDynamicModal(vc, config: regularConfig)
    }

    private func presentByAlignPopover(_ vc: ParticipantActionViewController, sourceView: UIView) {
        let anchor: AlignPopoverAnchor
        let size = vc.totalPopoverSize
        if currentLayoutType.isPhoneLandscape {
            let defalutContentWidth: CGFloat = 132
            anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        alignmentType: .top,
                                        arrowDirection: .right,
                                        contentWidth: .fixed(max(size.width, defalutContentWidth)),
                                        contentHeight: size.height,
                                        positionOffset: CGPoint(x: -4, y: 0),
                                        minPadding: UIEdgeInsets(top: InMeetNavigationBar.contentHeight + 10,
                                                                 left: 0,
                                                                 bottom: max(VCScene.safeAreaInsets.bottom, 10),
                                                                 right: 0),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        shadowColor: nil,
                                        containerColor: UIColor.ud.bgBody,
                                        shadowType: .s3Down)
        } else {
            let defalutContentWidth: CGFloat = 132
            anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        alignmentType: .auto,
                                        contentWidth: .fixed(max(size.width, defalutContentWidth)),
                                        contentHeight: size.height,
                                        positionOffset: CGPoint(x: 0, y: 4),
                                        minPadding: UIEdgeInsets(edges: 16),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        shadowColor: nil,
                                        containerColor: UIColor.ud.bgBody,
                                        shadowType: .s3Down)
        }
        AlignPopoverManager.shared.present(viewController: vc, anchor: anchor)
    }
}

extension InMeetSingleVideoComponent: SingleVideoVCDelegate {
    func didTapMoreSelection(cellVM: InMeetGridCellViewModel, sourceView: UIView, isSingleVideoEnabled: Bool) {
        let participant = cellVM.participant.value
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pid: participant, meetingId: meeting.meetingId) { [weak self] ap in
            guard let self = self else { return }
            let vc = self.actionService.actionVC(participant: participant, userInfo: ap, source: .single,
                                                 heterization: { $0.hasSignleVideo = isSingleVideoEnabled }) { [weak self] in
                if $0 == .fullScreen {  self?.hideSingleVideo() }
            }
            if let vc = vc {
                if Display.phone {
                    self.presentByAlignPopover(vc, sourceView: sourceView)
                } else {
                    self.presentByPopover(vc, sourceView: sourceView)
                }
            }
        }
    }

    func didTapUserName(participant: Participant) {
        if let grid = resolver.resolve(InMeetGridViewModel.self), grid.browserUserProfileEnable, !participant.isLarkGuest {
            if let userId = participant.participantId.larkUserId {
                MeetingTracks.trackDidTapUserProfile()
                ParticipantTracks.trackParticipantAction(.userInformation,
                                                         isFromGridView: true,
                                                         isSharing: meeting.shareData.isSharingContent)
                InMeetUserProfileAction.show(userId: userId, meeting: meeting)
            }
        }
    }

    func didHideSingleVideo() {
        hideSingleVideo()
    }
}

extension InMeetSingleVideoComponent: InMeetParticipantListener {
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        // 有参会人被设为焦点模式时，需退出全屏
        if participant != nil {
            Util.runInMainThread {
                self.hideSingleVideo()
            }
        }
    }
}

extension InMeetSingleVideoComponent: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        if key == .isVoiceModeOn, isOn {
            Util.runInMainThread {
                self.hideSingleVideo()
            }
        }
    }
}

extension InMeetViewContainer {
    var singleVideoComponent: InMeetSingleVideoComponent? {
        component(by: .singleVideo) as? InMeetSingleVideoComponent
    }
}
