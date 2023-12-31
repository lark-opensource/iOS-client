//
//  InMeetBroadcastComponent.swift
//  ByteView
//
//  Created by wulv on 2021/4/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI

private class ClickThroughWindow: FollowVcWindow {
    weak var broadcastView: BroadcastView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let broadcastView = broadcastView else { return nil }
        let convertedPoint = broadcastView.convert(point, from: self)
        return broadcastView.hitTest(convertedPoint, with: event)
    }
}

/// 广播，依据tips的LayoutGuide对齐

final class InMeetBroadcastComponent: InMeetViewComponent {
    weak var containerView: UIView?
    // top offset 和 tipView 一致
    weak var broadcastView: BroadcastView?
    let breakoutRoom: BreakoutRoomManager?
    weak var container: InMeetViewContainer?
    private var customWindow: ClickThroughWindow?
    private let meeting: InMeetMeeting
    var currentLayoutType: LayoutType
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.breakoutRoom = viewModel.resolver.resolve(BreakoutRoomManager.self)
        self.meeting = viewModel.meeting
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        self.customWindow = VCScene.createWindow(ClickThroughWindow.self, tag: .broadcast)
        self.customWindow?.backgroundColor = .clear
        self.customWindow?.windowLevel = .alert - 1
        self.customWindow?.rootViewController = PuppetWindowRootViewController(allowsToInteraction: true)
        breakoutRoom?.broadcast.addObserver(self)
    }

    deinit {
        customWindow = nil
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .broadcast
    }

    private func setupBroadcastView() {
        guard broadcastView == nil,
              let window = customWindow else {
            return
        }

        let container = UIView()
        container.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowOpacity = 1
        window.addSubview(container)
        self.containerView = container

        let view = BroadcastView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        container.addSubview(view)

        updateBroadcastConstraints()
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.closeAction = { [weak self] in
            self?.dismissBroadcast()
            if let text = self?.broadcastView?.contentText {
                self?.breakoutRoom?.broadcast.didClose(text)
            }
        }
        broadcastView = view
        customWindow?.broadcastView = view
    }

    private func showBroadcast(with content: String) {
        BreakoutRoomTracks.broadcastShow(self.meeting)
        BreakoutRoomTracksV2.broadcastShow(self.meeting)
        Util.runInMainThread {
            self.setupBroadcastView()
            self.broadcastView?.setText(content)
            self.customWindow?.isHidden = false
        }
    }

    private func dismissBroadcast() {
        Util.runInMainThread {
            self.containerView?.removeFromSuperview()
            self.customWindow?.isHidden = true
        }
    }

    private func updateBroadcastConstraints() {
        guard let window = self.customWindow else {
                  return
              }

        self.containerView?.snp.remakeConstraints { make in
            if self.currentLayoutType.isPhoneLandscape {
                make.top.equalTo(window.snp.top).offset(24)
            } else {
                if meeting.router.isPageSheetPresenting {
                    make.top.equalTo(window.safeAreaLayoutGuide)
                } else {
                    make.top.equalTo(window.safeAreaLayoutGuide).offset(8)
                }
            }

            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(600)
            make.left.right.equalToSuperview().inset(16).priority(999)
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
    }
}

extension InMeetBroadcastComponent: BroadcastManagerObserver {

    func broadcastChange(_ message: String?) {
        if let m = message {
            showBroadcast(with: m)
        } else {
            dismissBroadcast()
        }
    }
}
