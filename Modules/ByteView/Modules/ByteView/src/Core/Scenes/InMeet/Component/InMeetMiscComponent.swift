//
//  InMeetMiscComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewTracker
import ByteViewUI

/// 杂项
final class InMeetMiscComponent: InMeetViewComponent {
    private weak var container: InMeetViewContainer?
    let disposeBag = DisposeBag()
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.resolver = viewModel.resolver
        self.container = container
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .misc
    }

    func containerWillAppear(container: InMeetViewContainer) {
        resolver.viewContext.post(.containerWillAppear)
    }

    func containerDidAppear(container: InMeetViewContainer) {
        IdleTimerMonitor.start()
        DispatchQueue.main.async {
            container.setNeedsStatusBarAppearanceUpdate()
        }
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        ProximityMonitor.start(isPortrait: container.view.orientation?.isPortrait ?? (Display.pad ? false : true))
        VCTracker.post(name: .vc_meeting_page_onthecall, params: ["is_aux_window": VCScene.isAuxSceneOpen])
    }

    func containerWillDisappear(container: InMeetViewContainer) {
        IdleTimerMonitor.stop()
    }

    func containerDidDisappear(container: InMeetViewContainer) {
        resolver.viewContext.post(.containerDidDisappear)
    }

    deinit {
        Toast.update(customInsets: .zero)
        ProximityMonitor.stop()
    }
}
