//
//  InMeetPresentationViewController.swift
//  ByteView
//
//  Created by kiri on 2020/8/9.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI
import ByteViewTracker

final class InMeetPresentationViewController: PresentationViewController {
    let viewModel: InMeetViewModel
    private var isFirstAppear = true
    let keyboardRegistry = InMeetKeyboardEventRegistry()

    private lazy var floatingLogic = InnerFloatingVCLogic(viewModel: self.viewModel, rootVC: ObjectIdentifier(self)) { [viewModel = self.viewModel] in
        return FloatingInMeetingViewController(viewModel: InMeetFloatingViewModel(resolver: viewModel.resolver))
    }

    init(viewModel: InMeetViewModel) {
        self.viewModel = viewModel
        let resolver = viewModel.resolver
        let isBoxSharing = viewModel.meeting.setting.isBoxSharing
        super.init(router: viewModel.meeting.router, fullScreenFactory: { () -> UIViewController in
            viewModel.updateScope(.fullScreen)
            if isBoxSharing {
                return InMeetSelfShareScreenViewController(viewModel: resolver.resolve(InMeetSelfShareScreenViewModel.self)!)
            } else {
                return InMeetContainerViewController(viewModel: viewModel, scope: .fullScreen)
            }
        }, floatingFactory: {
            viewModel.updateScope(.floating)
            return FloatingContainerViewController(viewModel: viewModel)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterPIP()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate { [weak self] (_) in
            self?.viewModel.viewContext.updateOrientation()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.adjustClipsWhenbeginTransition()
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.adjustClipsWhenEndTransition()
            if Display.pad {
                self?.floatingLogic.resetFloatingSize(isLandscape: VCScene.isLandscape)
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerPIP()
        registerKeyboardPresses()
        if viewModel.meeting.type == .call {
            MeetingTracksV2.endTrack1v1ConnectionDuration()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        movePiPActiveViewBack()
        self.floatingLogic.isViewAppeared = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppear {
            isFirstAppear = false
            OnthecallReciableTracker.endEnterOnthecall()
            OnthecallReciableTracker.endEnterOnthecallForPure()
            viewModel.meeting.slaTracker.endEnterOnthecall(success: true)
            Toast.unblockToastOnVCScene(showBlockedToast: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.floatingLogic.isViewAppeared = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        movePiPActiveViewToWindow()
    }

    override func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        if isFloating {
            viewModel.viewContext.floatingWindowSize = frame.size
            let isSharingScreen = viewModel.meeting.shareData.isSharingScreen
            VCTracker.post(name: viewModel.meeting.type.trackName,
                           params: [.action_name: "screen",
                                    .extend_value: ["is_sharing": isSharingScreen ? 1 : 0,
                                                    "action_enabled": 1]])
        }
        adjustClipsWhenbeginTransition()
        super.floatingWindowWillTransition(to: frame, isFloating: isFloating)
    }

    override func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) {
        adjustClipsWhenEndTransition()
        super.floatingWindowDidTransition(to: frame, isFloating: isFloating)
    }

    // 用于小窗场景下对黑边的处理
    private func adjustClipsWhenbeginTransition() {
        guard router.isFloating else {
            return
        }
        view.window?.clipsToBounds = true
    }

    private func adjustClipsWhenEndTransition() {
        self.view.window?.clipsToBounds = false
    }
}
