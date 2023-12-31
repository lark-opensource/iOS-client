//
//  InMeetBottomBarComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

/// 底部栏
/// - 提供LayoutGuide：bottomBar
final class InMeetBottomBarComponent: InMeetViewComponent {
    let vc: ToolBarViewController
    let vm: ToolBarViewModel
    weak var container: InMeetViewContainer?
    let fullScreenMicComponent: FullScreenMicophoneComponent
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    var currentLayoutType: LayoutType
    var service: MeetingBasicService { meeting.service }
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.meeting = viewModel.meeting
        self.context = viewModel.viewContext
        self.currentLayoutType = layoutContext.layoutType
        self.fullScreenMicComponent = FullScreenMicophoneComponent(container: container, viewModel: viewModel, layoutContext: layoutContext)
        self.vm = viewModel.resolver.resolve()!
        self.vc = Display.phone ? ToolBarPhoneViewController(viewModel: vm) : ToolBarPadViewController(viewModel: vm)
        self.container = container
        self.vc.bottomBarGuide = container.bottomBarGuide
        container.addContent(vc, level: .bottomBar)
        container.addMeetLayoutStyleListener(self.vc)

        context.fullScreenDetector?.registerInterruptWhiteListView(self.vc.view)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .bottomBar
    }

    deinit {
        context.fullScreenDetector?.unregisterInterruptWhiteListView(self.vc.view)
    }

    func setupConstraints(container: InMeetViewContainer) {
        vc.view.snp.makeConstraints { (maker) in
            maker.left.right.top.equalTo(container.bottomBarGuide)
            maker.bottom.equalToSuperview()
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        Logger.ui.debug("containerWillTransition to size: \(newContext.viewSize)")
        self.fullScreenMicComponent.viewLayoutContextIsChanging(from: oldContext, to: newContext)
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.fullScreenMicComponent.containerDidChangeLayoutStyle(container: container, prevStyle: prevStyle)
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        showHostControlGuide()
    }

    private func showHostControlGuide() {
        guard meeting.setting.showsHostControl, Display.pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular, service.shouldShowGuide(.hostSecurityGuideKey) else { return }
        let guide = GuideDescriptor(type: .hostControl,
                                    title: I18n.View_G_HostControlRename_OnboardingTitle,
                                    desc: I18n.View_G_ManageMeetingFeature_SecurityOnboarding)
        guide.style = .alert
        guide.sureAction = { [weak self] in self?.service.didShowGuide(.hostSecurityGuideKey) }
        GuideManager.shared.request(guide: guide)
    }
}

extension InMeetViewContainer {
    var fullscreenMicBar: FullScreenMicophoneComponent? {
        if let component = component(by: .bottomBar) as? InMeetBottomBarComponent {
            return component.fullScreenMicComponent
        }
        return nil
    }
}
