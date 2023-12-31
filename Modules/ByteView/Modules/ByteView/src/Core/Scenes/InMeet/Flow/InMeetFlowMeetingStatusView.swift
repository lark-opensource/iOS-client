//
//  InMeetFlowMeetingStatusView.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/16.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignIcon
import ByteViewCommon
import UIKit
import ByteViewNetwork
import ByteViewTracker

final class InMeetFlowMeetingStatusViewModel {

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let countDownManager: CountDownManager
    let resolver: InMeetViewModelResolver
    var fullScreenDetector: InMeetFullScreenDetector? {
        context.fullScreenDetector
    }

    init(meeting: InMeetMeeting, context: InMeetViewContext, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.context = context
        self.resolver = resolver
        self.countDownManager = resolver.resolve()!
    }
}

class InMeetFlowStatusView: UIView {

    var isFullScreen = false

    var leftWidth = 0
    let lockedView = LockedView()

    var showStatusDetail: (() -> Void)?

    var recordView: MeetingRecordView = {
        let recordView = MeetingRecordView()
        recordView.isHiddenInStackView = true
        return recordView
    }()

    let transcribeView: MeetingStatusView = MeetingStatusView()
    let interpretationView: MeetingStatusView = MeetingStatusView()

    let liveView: MeetingLiveView = MeetingLiveView()

    lazy var countDownTag: CountDownTagView = {
        let tag = CountDownTagView(scene: .inGrid)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapCountDown(_:)))
        tag.addGestureRecognizer(tap)
        return tag
    }()

    let peopleMinutesView: PeopleMinutesView = PeopleMinutesView()

    private let contentStackView: UIStackView = {
        var stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 8
        return stack
    }()

    var currentStatus = Set<InMeetStatusType>()
    var currentPadStatus = Set<InMeetStatusType>()
    var visibleStatus = Set<InMeetStatusType>()
    let allStatus: Set<InMeetStatusType> = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord, .countDown]
    let needShow: Set<InMeetStatusType> = [.record, .transcribe, .countDown]

    private var viewModel: InMeetFlowMeetingStatusViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(lockedView)
        contentStackView.addArrangedSubview(recordView)
        contentStackView.addArrangedSubview(transcribeView)
        contentStackView.addArrangedSubview(interpretationView)
        contentStackView.addArrangedSubview(liveView)
        contentStackView.addArrangedSubview(peopleMinutesView)
        contentStackView.addArrangedSubview(countDownTag)

        contentStackView.arrangedSubviews.forEach { $0.isHiddenInStackView = true }
        updateData()
        updateLayout()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapCountDown(_ g: UITapGestureRecognizer) {
        if Display.pad && isRegular {
            viewModel?.countDownManager.foldBoard(false)
        } else {
            showStatusDetail?()
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "mobile_status_bar", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": isLandscape ? "true" : "false"])
        }
    }
}

extension InMeetFlowStatusView {
    func bindViewModel(_ viewModel: InMeetFlowMeetingStatusViewModel) {
        self.viewModel = viewModel
    }

    func viewForState(_ state: InMeetStatusType) -> UIView {
        switch state {
        case .lock:
            return lockedView
        case .record:
            return recordView
        case .transcribe:
            return transcribeView
        case .interpreter:
            return interpretationView
        case .live:
            return liveView
        case .countDown:
            return countDownTag
        case .interviewRecord:
            return peopleMinutesView
        }
    }

    func setNormalState(_ states: [InMeetStatusType], isOmit: Bool) {
        for state in InMeetStatusType.needOmitStates {
            guard let view = viewForState(state) as? BaseInMeetStatusView else { continue }
            if states.contains(state) {
                view.shouldHiddenForOmit = isOmit
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    func updateData() {
        currentPadStatus.removeAll()
        for i in currentStatus {
            if i == .countDown || i == .record || i == .transcribe {
                currentPadStatus.insert(i)
            }
        }
    }

    func updateLayout() {
        let status = Display.pad && isRegular ? currentPadStatus : currentStatus
        let rightWidth = status.isEmpty ? 0 : (status.contains(.countDown) ? -3 : -6)
        let leftWidth = (status.isEmpty || (!status.contains(.countDown) && !status.contains(.record) && !status.contains(.transcribe) && isFullScreen)) ? 0 : 6
        contentStackView.snp.remakeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.right.equalToSuperview().offset(rightWidth)
            maker.left.equalToSuperview().offset(leftWidth)
        }
    }
}

extension InMeetFlowStatusView {

    //func对外层暴露一个接口让大家应用
    func updateFlowStatusView(_ items: [InMeetStatusThumbnailItem]) {
        currentStatus.removeAll()
        for s in items {
            currentStatus.insert(s.type)
            switch s.type {
            case .live:
                liveView.setLabel(s.title)
            case .transcribe:
                transcribeView.setLabel(s.title)
                transcribeView.setIcon(s.icon)
            case .interpreter:
                interpretationView.setLabel(s.title)
                interpretationView.setIcon(s.icon)
            case .countDown:
                if let data = s.data as? InMeetStatusCountDownData {
                    countDownTag.setColorStage(data.stage)
                    countDownTag.setLabel(s.title)
                    if data.isBoardOpened {
                        currentStatus.remove(.countDown)
                        currentPadStatus.remove(.countDown)
                    }
                }
            case .record:
                recordView.setLabel(s.title)
                if let isLaunching = s.data as? Bool {
                    recordView.isRecordLaunching = isLaunching
                }
            default:
                break
            }
        }
        updateData()
        updateLayout()
        hideStatusIfNeeded(self.isFullScreen)
    }

    func hideStatusIfNeeded(_ isFullScreen: Bool) {
        let key = "\(currentStatus)"
        var needOmitStates: [InMeetStatusType] = []
        if Display.pad, isRegular {
            for s in currentPadStatus {
                needOmitStates.append(s)
            }
            for i in currentPadStatus.intersection(needShow) {
                viewForState(i).isHiddenInStackView = false
            }
            for i in allStatus.subtracting(currentPadStatus.intersection(needShow)) {
                viewForState(i).isHiddenInStackView = true
            }
            setNormalState(needOmitStates, isOmit: isFullScreen)
            if currentPadStatus.contains(.countDown) && !currentPadStatus.contains(.record) && !currentPadStatus.contains(.transcribe) {
                self.superview?.backgroundColor = .clear
                self.superview?.layer.borderWidth = 0
            } else if !currentPadStatus.contains(.countDown) && !currentPadStatus.contains(.record) && !currentPadStatus.contains(.transcribe) {
                self.superview?.backgroundColor = .clear
                self.superview?.layer.borderWidth = 0
            } else {
                self.superview?.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
                self.superview?.layer.borderWidth = 0.5
                self.superview?.layer.vc.borderColor = UIColor.ud.lineDividerDefault
            }
        } else {
            for s in currentStatus {
                needOmitStates.append(s)
            }
            if isFullScreen {
                let showStatus = currentStatus.intersection(needShow)
                let notShowStatus = allStatus.subtracting(showStatus)
                for i in showStatus {
                    if i == .interpreter {
                        interpretationView.hidden(isHidden: false)
                    }
                    viewForState(i).isHiddenInStackView = false
                }
                for i in notShowStatus {
                    if i == .interpreter {
                        interpretationView.hidden(isHidden: true)
                    }
                    viewForState(i).isHiddenInStackView = true
                }
                setNormalState(needOmitStates, isOmit: isFullScreen)
                if currentStatus.contains(.countDown) && !currentStatus.contains(.record) && !currentStatus.contains(.transcribe) {
                    self.superview?.backgroundColor = .clear
                    self.superview?.layer.borderWidth = 0
                } else if !currentStatus.contains(.countDown) && !currentStatus.contains(.record) && !currentStatus.contains(.transcribe) {
                    self.superview?.backgroundColor = .clear
                    self.superview?.layer.borderWidth = 0
                } else {
                    self.superview?.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
                    self.superview?.layer.borderWidth = 0.5
                    self.superview?.layer.vc.borderColor = UIColor.ud.lineDividerDefault
                }
            } else {
                for i in currentStatus {
                    if i == .interpreter {
                        interpretationView.hidden(isHidden: false)
                    }
                    viewForState(i).isHiddenInStackView = false
                }
                for i in allStatus.subtracting(currentStatus) {
                    if i == .interpreter {
                        interpretationView.hidden(isHidden: true)
                    }
                    viewForState(i).isHiddenInStackView = true
                }
                omitState(currentStatus.count)
            }
        }
        Logger.ui.info("start calc hideStatusIfNeeded: key = \(key)")
    }

    //判断当前是否需要省略文字
    private func omitState(_ statesCount: Int) {
        var needOmitStates: [InMeetStatusType] = []
        for s in currentStatus {
            needOmitStates.append(s)
        }
        if statesCount == 1, currentStatus.contains(.countDown) {
            self.superview?.backgroundColor = .clear
            self.superview?.layer.borderWidth = 0
        } else {
            self.superview?.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
            self.superview?.layer.borderWidth = 0.5
            self.superview?.layer.vc.borderColor = UIColor.ud.lineDividerDefault
            let isOmit = isPhoneLandscape ? true : statesCount > 2
            setNormalState(needOmitStates, isOmit: isOmit)
        }
    }
}

extension InMeetFlowStatusView {
    var isEmpty: Bool {
        if Display.pad, isRegular {
            return currentPadStatus.isEmpty
        } else {
            return currentStatus.isEmpty
        }
    }
}
