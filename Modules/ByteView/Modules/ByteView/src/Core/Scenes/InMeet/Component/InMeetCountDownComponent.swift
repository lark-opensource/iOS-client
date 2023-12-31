//
//  InMeetCountDownComponent.swift
//  ByteView
//
//  Created by wulv on 2022/5/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewTracker
import ByteViewUI

final class InMeetCountDownComponent: InMeetViewComponent {

    var componentIdentifier: InMeetViewComponentIdentifier = .countDown
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private weak var container: InMeetViewContainer?
    private let countDownManager: CountDownManager

    /// 倒计时悬浮窗（Pad R only)
    private weak var boardView: CountDownBoardView?
    private let boardContainerView: UIView
    // --- 未拖拽过 ---
    private let boardDefaultLeft: CGFloat = 16
    private let boardDefaultBottom: CGFloat = 43
    // --- 拖拽过 ---
    private let boardMinH: CGFloat = 16
    private let boardMinV: CGFloat = 16
    private weak var boardLeftConstraint: NSLayoutConstraint?
    private weak var boardTopConstraint: NSLayoutConstraint?
    private weak var boardMinTopConstraint: NSLayoutConstraint?
    private weak var boardMinBottomconstraint: NSLayoutConstraint?

    // alerts
    private weak var preEndAlert: ByteViewDialog?
    private weak var closeAlert: ByteViewDialog?

    private var service: MeetingBasicService { meeting.service }

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.meeting = viewModel.meeting
        self.container = container
        self.context = viewModel.viewContext
        self.countDownManager = viewModel.resolver.resolve()!
        self.boardContainerView = container.loadContentViewIfNeeded(for: .countDownBoard)
        self.countDownManager.addObserver(self, fireImmediately: false)
        context.addListener(self, for: [.contentScene, .containerDidLayout])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        preEndAlert?.dismiss()
        closeAlert?.dismiss()
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        updateBoardIfNeeded()
        showCountdownGuide()
    }

    func setupConstraints(container: InMeetViewContainer) {
        remakeBoardLayout()
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        updateBoardOperate()
    }
}

extension InMeetCountDownComponent {

    private var canShowBoard: Bool {
        let featureEnabled: Bool = countDownManager.enabled
        let active = countDownManager.state != .close
        let UIEnabled = countDownManager.style == .board
        return featureEnabled && active && UIEnabled
    }

    private func updateBoardIfNeeded() {
        if canShowBoard, boardView == nil {
            createBoard()
            DispatchQueue.main.async {
                self.remakeBoardLayout()
                self.boardView?.updateBottomButtonWidthIfNeeded()
            }
        } else if !canShowBoard, boardView != nil {
            removeBoard()
        }
    }

    private func createBoard() {
        VCTracker.post(name: .vc_countdown_view, params: ["countdown_permission": countDownManager.canOperate.0,
                                                          "countdown_type": "panel"])
        let operateEntrance = container?.meetingLayoutStyle != .fullscreen
        let boardView = CountDownBoardView(style: operateEntrance ? .hasSet : .normal, hasHour: countDownManager.countDown.everHasHour,
                                           colorStage: countDownManager.countDown.timeStage, state: countDownManager.state)
        boardView.floatButton.addTarget(self, action: #selector(boardFloatAction(_:)), for: .touchUpInside)
        boardView.leftButton.addTarget(self, action: #selector(boardLeftButtonAction(_:)), for: .touchUpInside)
        boardView.rightButton.addTarget(self, action: #selector(boardRightButtonAction(_:)), for: .touchUpInside)
        boardContainerView.addSubview(boardView)
        self.boardView = boardView
        if let in24HR = countDownManager.countDown.in24HR {
            boardView.update(hour: countDownManager.countDown.everHasHour ? in24HR.0 : nil, minute: in24HR.1, seconds: in24HR.2, stage: countDownManager.countDown.timeStage)
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(boardPanAction(_:)))
        boardView.addGestureRecognizer(panGesture)
    }

    private func removeBoard() {
        boardContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        boardView?.removeFromSuperview()
        boardView = nil
    }

    private func remakeBoardLayout() {
        if boardView?.window != nil, let container = container {
            if let lastPoint = context.countDownBoardLeftTopPoint {
                // 本场会议拖拽过, 基于 container view 布局
                boardView?.translatesAutoresizingMaskIntoConstraints = false
                boardLeftConstraint = boardView?.leftAnchor.constraint(equalTo: container.view.leftAnchor, constant: lastPoint.x)
                boardLeftConstraint?.priority = .defaultHigh
                boardLeftConstraint?.isActive = true
                boardTopConstraint = boardView?.topAnchor.constraint(equalTo: container.view.topAnchor, constant: lastPoint.y)
                boardTopConstraint?.priority = .defaultHigh
                boardTopConstraint?.isActive = true

                boardMinTopConstraint = boardView?.topAnchor.constraint(greaterThanOrEqualTo: container.accessoryGuide.topAnchor, constant: boardMinV)
                boardMinTopConstraint?.priority = .required
                boardMinTopConstraint?.isActive = true
                boardMinBottomconstraint = boardView?.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomBarGuide.topAnchor, constant: -boardMinV)
                boardMinBottomconstraint?.priority = .required
                boardMinBottomconstraint?.isActive = true
            } else if let boardView = boardView {
                // 基于 accessoryGuide 布局
                boardView.snp.makeConstraints({
                    $0.left.equalTo(container.accessoryGuide).offset(boardDefaultLeft + VCScene.safeAreaInsets.left)
                    $0.bottom.equalTo(container.accessoryGuide).inset(boardDefaultBottom + VCScene.safeAreaInsets.bottom)
                })
            }
        }
    }

    private func showPickerViewController(style: CountDownPickerViewController.Style, source: CountDownPickerViewModel.PageSource) {
        let vm = CountDownPickerViewModel(meeting: meeting, manager: countDownManager)
        vm.pageSource = source
        vm.style = style
        let viewController = CountDownPickerViewController(viewModel: vm)
        meeting.router.presentDynamicModal(viewController,
                                           regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                           compactConfig: .init(presentationStyle: .pan, needNavigation: true))
    }

    private func showPreEndComfirmAlert() {
        ByteViewDialog.Builder()
            .id(.preEndCountDown)
            .needAutoDismiss(true)
            .title(I18n.View_G_ConfirmEndCountdown_Pop)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "cancel"])
            })
            .rightTitle(I18n.View_G_EndButton)
            .rightHandler({ [weak countDownManager] _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "confirm"])
                countDownManager?.requestPreEnd()
            })
            .show { [weak self] alert in
                if let self = self {
                    self.preEndAlert = alert
                } else {
                    alert.dismiss()
                }
            }
    }

    private func showCloseConfirmAlert() {
        ByteViewDialog.Builder()
            .id(.closeCountDown)
            .needAutoDismiss(true)
            .title(I18n.View_G_OffCountdownForAllPop)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": false])
            })
            .rightTitle(I18n.View_G_StopCountdown_Button)
            .rightHandler({ [weak countDownManager] _ in
                VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": true])
                countDownManager?.requestClose()
            })
            .show { [weak self] alert in
                if let self = self {
                    self.closeAlert = alert
                } else {
                    alert.dismiss()
                }
            }
    }

    private func mayShowStateToast(_ state: CountDown.State, by `operator`: ByteviewUser?) {
        guard countDownManager.enabled else { return }
        let participantService = meeting.httpClient.participantService
        switch state {
        case .close:
            Toast.show(I18n.View_G_CountdownOffToast)
        case .start:
            if let p = `operator` {
                participantService.participantInfo(pid: p, meetingId: meeting.meetingId) { ap in
                    Toast.showOnVCScene(I18n.View_G_CountdownSet_Toast(ap.name))
                }
            } else {
                Toast.showOnVCScene(I18n.View_G_CountdownSet_Toast(""))
            }
        case .end(let isPre):
            if isPre {
                if let p = `operator` {
                    participantService.participantInfo(pid: p, meetingId: meeting.meetingId) { ap in
                        Toast.showOnVCScene(I18n.View_G_CountdownEndEarly_Toast(ap.name))
                    }
                } else {
                    Toast.showOnVCScene(I18n.View_G_CountdownEndEarly_Toast(""))
                }
            } else {
                Toast.showOnVCScene(I18n.View_G_CountdownEnded_Toast)
            }
        }
    }

    private func showProlongToast(by `operator`: ByteviewUser) {
        guard countDownManager.enabled else { return }
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pid: `operator`, meetingId: meeting.meetingId) { ap in
            Toast.showOnVCScene(I18n.View_G_CountdownExtend_Toast(ap.name))
        }
    }

    private func fixBoardDragBoundary() {
        guard let size = boardView?.bounds.size, let container = container,
              let leftConstraint = boardLeftConstraint, let topConstraint = boardTopConstraint else { return }

        let minLeft = boardMinH + container.view.safeAreaInsets.left
        if leftConstraint.constant < minLeft {
            leftConstraint.constant = minLeft
        } else {
            let maxLeft = container.view.bounds.width - (boardMinH + container.view.safeAreaInsets.right) - size.width
            if leftConstraint.constant > maxLeft {
                leftConstraint.constant = maxLeft
            }
        }
        let minTop = boardMinV + container.view.safeAreaInsets.top
        if topConstraint.constant < minTop {
            topConstraint.constant = minTop
        } else {
            let maxTop = container.view.bounds.height - (boardMinV + container.view.safeAreaInsets.bottom) - size.height
            if topConstraint.constant > maxTop {
                topConstraint.constant = maxTop
            }
        }
    }

    private func showCountdownGuide() {
        guard service.shouldShowGuide(.countDown) else { return }
        let guide = GuideDescriptor(type: .countDown, title: nil, desc: I18n.View_G_CountdownGood)
        guide.sureAction = { [weak self] in self?.service.didShowGuide(.countDown) }
        guide.style = .plain
        GuideManager.shared.request(guide: guide)
    }

    private func updateBoardOperate() {
        let operateEntrance = container?.meetingLayoutStyle != .fullscreen
        boardView?.update(operateEntrance ? .hasSet : .normal)
    }
}

extension InMeetCountDownComponent {

    @objc private func boardFloatAction(_ b: Any) {
        countDownManager.foldBoard(true)
    }

    @objc private func boardLeftButtonAction(_ b: Any) {
        switch countDownManager.state {
        case .close: break
        case .start:
            // 延长
            guard countDownManager.canOperate.0 else {
                if let message = countDownManager.canOperate.1?.message { Toast.show(message) }
                return
            }
            showPickerViewController(style: .prolong, source: .prolong)
        case .end:
            // 重设
            guard countDownManager.canOperate.0 else {
                if let message = countDownManager.canOperate.1?.message { Toast.show(message) }
                return
            }
            VCTracker.post(name: .vc_countdown_click, params: [.click: "reset"])
            showPickerViewController(style: .start, source: .reset)
        }
    }

    @objc private func boardRightButtonAction(_ b: Any) {
        switch countDownManager.state {
        case .close: break
        case .start:
            // 结束
            guard countDownManager.canOperate.0 else {
                if let message = countDownManager.canOperate.1?.message { Toast.show(message) }
                return
            }
            showPreEndComfirmAlert()
        case .end:
            // 关闭
            guard countDownManager.canOperate.0 else {
                if let message = countDownManager.canOperate.1?.message { Toast.show(message) }
                return
            }
            VCTracker.post(name: .vc_countdown_click, params: [.click: "close"])
            showCloseConfirmAlert()
        }
    }

    @objc private func boardPanAction(_ p: UIPanGestureRecognizer) {
        switch p.state {
        case .began:
            if boardLeftConstraint == nil, boardTopConstraint == nil,
                let container = container, let boardView = boardView {
                let point = container.view.convert(boardView.frame.origin, from: container.view)
                boardView.snp.removeConstraints()
                boardView.translatesAutoresizingMaskIntoConstraints = false
                boardLeftConstraint = boardView.leftAnchor.constraint(equalTo: container.view.leftAnchor, constant: point.x)
                boardLeftConstraint?.priority = .defaultHigh
                boardLeftConstraint?.isActive = true
                boardTopConstraint = boardView.topAnchor.constraint(equalTo: container.view.topAnchor, constant: point.y)
                boardTopConstraint?.priority = .defaultHigh
                boardTopConstraint?.isActive = true

                boardMinTopConstraint = boardView.topAnchor.constraint(greaterThanOrEqualTo: container.accessoryGuide.topAnchor, constant: boardMinV)
                boardMinTopConstraint?.priority = .required
                boardMinTopConstraint?.isActive = true
                boardMinBottomconstraint = boardView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomBarGuide.topAnchor, constant: -boardMinV)
                boardMinBottomconstraint?.priority = .required
                boardMinBottomconstraint?.isActive = true
            }
        case .changed:
            if let leftConstraint = boardLeftConstraint, let topConstraint = boardTopConstraint {
                let translation = p.translation(in: nil)
                p.setTranslation(.zero, in: nil)
                leftConstraint.constant += translation.x
                topConstraint.constant += translation.y
            }
        case .ended, .failed:
            fixBoardDragBoundary()
            if let leftConstraint = boardLeftConstraint, let topConstraint = boardTopConstraint {
                context.countDownBoardLeftTopPoint = CGPoint(x: leftConstraint.constant, y: topConstraint.constant)
            }
        default: break
        }
    }
}

extension InMeetCountDownComponent: CountDownManagerObserver {

    func countDownStateChanged(_ state: CountDown.State, by user: ByteviewUser?, countDown: CountDown) {
        Util.runInMainThread {
            self.updateBoardIfNeeded()
            self.boardView?.update(state: state)
            self.mayShowStateToast(state, by: user)
        }
    }

    func countDownTimeChanged(_ time: Int, in24HR: (Int, Int, Int), stage: CountDown.Stage) {
        Util.runInMainThread {
            self.boardView?.update(hour: self.countDownManager.countDown.everHasHour ? in24HR.0 : nil, minute: in24HR.1, seconds: in24HR.2, stage: stage)
        }
    }

    func countDownStyleChanged(style: CountDownManager.Style) {
        updateBoardIfNeeded()
    }

    func countDownTimeProlonged(by user: ByteviewUser) {
        Util.runInMainThread {
            self.showProlongToast(by: user)
        }
    }

    func countDownEnableChanged(_ enabled: Bool) {
        Util.runInMainThread {
            self.updateBoardIfNeeded()
        }
    }
}

extension InMeetCountDownComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerDidLayout {
            fixBoardDragBoundary()
        }
    }
}
