//
//  InMeetReconnectComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 断线重连
final class InMeetReconnectComponent: InMeetViewComponent, InMeetRtcNetworkListener {
    private var isConnectingVisible = false
    private weak var container: UIViewController?
    private let meeting: InMeetMeeting

    convenience init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.init(container: container, meeting: viewModel.meeting)
    }

    init(container: UIViewController, meeting: InMeetMeeting) {
        self.meeting = meeting
        self.container = container
        meeting.rtc.network.addListener(self)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showConnectingIfNeeded(self.meeting.rtc.network.reachableState)
        }
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .reconnect
    }

    func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {
        DispatchQueue.main.async { [weak self] in
            self?.showConnectingIfNeeded(state)
        }
    }

    private let connectingStates: Set<InMeetRtcReachableState> = [.interrupted, .timeout, .lost]
    private func showConnectingIfNeeded(_ state: InMeetRtcReachableState) {
        let isConnecting = connectingStates.contains(state)
        guard let container = container, isConnecting != isConnectingVisible else {
            return
        }
        isConnectingVisible = isConnecting
        if isConnecting {
            let vc = InMeetReconnectingViewController(meeting: meeting)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            container.present(vc, animated: true, completion: nil)
        } else {
            if container.presentedViewController is InMeetReconnectingViewController {
                container.dismiss(animated: true, completion: nil)
            }
        }
    }
}
