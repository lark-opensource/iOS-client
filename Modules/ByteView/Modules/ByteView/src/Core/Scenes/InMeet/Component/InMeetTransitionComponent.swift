//
//  InMeetTransitionComponent.swift
//  ByteView
//
//  Created by wulv on 2021/4/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 分组讨论 转场
final class InMeetTransitionComponent: InMeetViewComponent {
    private var transitionVC: TransitionViewController?
    private weak var container: InMeetViewContainer?
    private let meeting: InMeetMeeting
    private let resolver: InMeetViewModelResolver
    private let breakoutRoom: BreakoutRoomManager
    private let context: InMeetViewContext
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.meeting = viewModel.meeting
        self.resolver = viewModel.resolver
        self.context = viewModel.viewContext
        self.breakoutRoom = viewModel.resolver.resolve(BreakoutRoomManager.self)!
        self.container = container
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .transition
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        breakoutRoom.transition.addObserver(self)
        updateTransitioning(breakoutRoom.transition.isTransitioning, info: breakoutRoom.transition.transitionInfo)
    }

    private func updateTransitioning(_ isTransitioning: Bool, info: BreakoutRoomInfo?) {
        guard let container = container else { return }
        if isTransitioning, transitionVC == nil {
            BreakoutRoomTracksV2.beginTransition(meeting)
            let vm = TransitionViewModel(meeting: meeting, firstInfo: info, roomManager: resolver.resolve())
            self.transitionVC = TransitionViewController(viewModel: vm)
            Util.runInMainThread {
                if container.presentedViewController != nil {
                    container.presentedViewController?.view.isHidden = true
                    container.dismiss(animated: true, completion: nil)
                }
                if let vc = self.transitionVC {
                    container.addContent(vc, level: .transition)
                    vc.view.snp.makeConstraints { (maker) in
                        maker.edges.equalToSuperview()
                    }
                }
            }
        } else if !isTransitioning, let vc = transitionVC {
            resolver.resolve(ChatMessageViewModel.self)?.reset()
            transitionVC = nil
            Util.runInMainThread {
                vc.vc.removeFromParent()
            }
        }
    }
}

extension InMeetTransitionComponent: TransitionManagerObserver {

    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        context.fullScreenDetector?.postInterruptEvent()
        updateTransitioning(isTransition, info: info)
    }
}
