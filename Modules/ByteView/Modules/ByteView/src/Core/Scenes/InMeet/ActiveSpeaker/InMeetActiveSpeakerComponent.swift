//
//  InMeetActiveSpeakerComponent.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/9/28.
//

import Foundation
import RxSwift
import ByteViewUI

class InMeetActiveSpeakerComponent: InMeetViewComponent {

    weak var container: InMeetViewContainer?
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let gridViewModel: InMeetGridViewModel
    let bag = DisposeBag()

    @RwAtomic
    private var activeSpeakerUid: RtcUID?
    private var currentSortResult: [InMeetGridCellViewModel] = []

    private lazy var activeSpeakerTagView = {
        let view = ActiveSpeakerTagView()
        view.isHidden = true
        return view
    }()

    private let asFloatGuideToken: MeetingLayoutGuideToken
    var currentLayoutType: LayoutType

    required init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        self.meeting = viewModel.meeting
        self.context = container.context
        self.gridViewModel = viewModel.resolver.resolve()!
        self.currentLayoutType = layoutContext.layoutType
        self.asFloatGuideToken = container.layoutContainer.requestOrderedLayoutGuide(topAnchor: .topShareBar,
                                                                                     bottomAnchor: .bottomShareBar,
                                                                                     insets: 8.0)

        container.addContent(activeSpeakerTagView, level: .activeSpeakerTag)

        viewModel.resolver.resolve(InMeetActiveSpeakerViewModel.self)?.addListener(self)
        container.context.addListener(self, for: [.hideNonVideoParticipants, .contentScene, .flowShrunken, .sketchMenu, .currentGridVisibleRange, .whiteboardMenu, .showSpeakerOnMainScreen])
        self.gridViewModel.sortedVMsRelay.asObservable()
            .observeOn(self.serialScheduler)
            .subscribe(onNext: { [weak self] vms in
                self?.currentSortResult = vms
                self?.updateActiveSpeakerIfNeeded()
            }).disposed(by: bag)
        self.gridViewModel.isUsingCustomOrderRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.updateActiveSpeakerIfNeeded()
            }).disposed(by: bag)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .activeSpeakerTag
    }

    func setupConstraints(container: InMeetViewContainer) {
        remakeConstraints()
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        currentLayoutType = newContext.layoutType
        // nolint-next-line: magic number
        let maxWidth: CGFloat = newContext.layoutType.isRegular ? 300 : 240
        activeSpeakerTagView.snp.updateConstraints { make in
            make.width.lessThanOrEqualTo(maxWidth)
        }
    }

    private func remakeConstraints() {
        Util.runInMainThread {
            guard let container = self.container else { return }
            // nolint-next-line: magic number
            let maxWidth: CGFloat = VCScene.isRegular ? 300 : 240
            self.activeSpeakerTagView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(maxWidth)
                make.height.equalTo(20)
                make.top.equalTo(self.asFloatGuideToken.layoutGuide)
            }
        }
    }

    private func updateTagView(with name: String?) {
        Util.runInMainThread {
            if let name = name {
                self.activeSpeakerTagView.isHidden = false
                self.activeSpeakerTagView.setName(name)
            } else {
                self.activeSpeakerTagView.isHidden = true
            }
        }
    }

    // 处于自定义视频顺序时，以下场景可能展示ASTag:
    //    1. 宫格视图
    //       - 当前在首屏 && AS在非首屏
    //    2. 缩略图视图
    //       - 共享中 && 宫格流展开 && 当前在首屏 && AS在非首屏 && 没有开启主画面显示发言人
    private func needShowTipsForCustomOrdering(_ asID: RtcUID) -> Bool {
        guard let asIndex = currentSortResult.firstIndex(where: { $0.rtcUid == asID }) else { return false }

        // 判断是否在观看首屏，且 AS 在非首屏
        let inFirstPage: Bool
        let pageSize: Int
        switch context.currentGridVisibleRange {
        case .page(let i):
            inFirstPage = i == 0
            pageSize = 6
        case .range(let start, _, let size):
            inFirstPage = start == 0
            pageSize = size
        }
        guard inFirstPage && asIndex >= pageSize else { return false }

        // 判断 sceneMode 是否符合条件
        let showTipOnCurrentSenceMode: Bool
        let sceneMode = self.context.meetingScene
        let contentMode = self.context.meetingContent
        if sceneMode == .gallery {
            showTipOnCurrentSenceMode = true
        } else if sceneMode == .thumbnailRow {
            showTipOnCurrentSenceMode = contentMode.isShareContent && !context.isFlowShrunken && !context.isShowSpeakerOnMainScreen
        } else {
            showTipOnCurrentSenceMode = false
        }

        return showTipOnCurrentSenceMode
    }

    // non-video开关打开时，当且仅当是「自定义顺序状态」的非兜底AS状态，且处于以下两种场景可能展示ASTag:
    //    1. 宫格视图
    //       - 若横屏模式&共享中，则仅当观看非共享屏（首屏）时展示tag
    //       - 其余情况均展示tag
    //    2. 缩略图视图
    //       - 横屏模式，不展示tag（shrinkView可展示AS）
    //       - 共享中 && (宫格流展开 || 宫格流隐藏)，展示tag
    //       - 其余情况均不展示tag
    private func needShowTipsForNonVideo(_ asID: RtcUID) -> Bool {
        guard context.isHideNonVideoParticipants &&
                currentSortResult.contains(where: { $0.type == .participant }) else { return false }

        var result = false
        let sceneMode = self.context.meetingScene
        let contentMode = self.context.meetingContent
        if sceneMode == .gallery {
            if currentLayoutType.isPhoneLandscape && self.meeting.shareData.isSharingContent {
                result = context.currentGridVisibleRange.pageIndex > 0
            } else {
                result = true
            }
        } else if sceneMode == .thumbnailRow {
            if currentLayoutType.isPhoneLandscape {
                result = false
            } else if contentMode.isShareContent && (!self.context.isFlowShrunken || self.context.isThumbnailFLowHidden) {
                result = true
            }
        }

        if result {
            // 判断AS是否被隐藏；当且仅当AS被隐藏时才展示标签
            if meeting.participant.find(rtcUid: asID, in: .activePanels) != nil, gridViewModel.sortedGridViewModels.first(where: { $0.rtcUid == asID }) == nil {
                return true
            }
        }
        return false
    }

    private let queue = DispatchQueue(label: "lark.byteview.as.tag")
    private lazy var serialScheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: "lark.byteview.as.tag.scheduler")
    private func updateActiveSpeakerIfNeeded() {
        queue.async {
            // 展示AS标签的前提：当前有AS && AS不是自己
            // 只有自定义视频顺序场景才显示 tips
            guard let asID = self.activeSpeakerUid,
                  asID != self.meeting.myself.rtcUid,
                  self.gridViewModel.isUsingCustomOrder else {
                self.updateTagView(with: nil)
                return
            }

            let showAS = self.needShowTipsForCustomOrdering(asID) || self.needShowTipsForNonVideo(asID)
            if showAS {
                if let p = self.meeting.participant.find(rtcUid: asID, in: .activePanels) {
                    let participantService = self.meeting.httpClient.participantService
                    participantService.participantInfo(pid: p, meetingId: self.meeting.meetingId) { [weak self] info in
                        self?.updateTagView(with: info.name)
                    }
                    return
                }
            } else {
                self.updateTagView(with: nil)
            }
        }
    }
}

extension InMeetActiveSpeakerComponent: InMeetActiveSpeakerListener, InMeetViewChangeListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {
        self.activeSpeakerUid = rtcUid
        self.updateActiveSpeakerIfNeeded()
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if [.contentScene, .sketchMenu, .whiteboardMenu].contains(change) {
            remakeConstraints()
        }
        let changes: [InMeetViewChange] = [.contentScene, .flowShrunken, .hideSelf, .hideNonVideoParticipants,
                                           .thumbnailFlowHidden, .currentGridVisibleRange, .showSpeakerOnMainScreen]
        if changes.contains(change) {
            self.updateActiveSpeakerIfNeeded()
        }
    }
}
