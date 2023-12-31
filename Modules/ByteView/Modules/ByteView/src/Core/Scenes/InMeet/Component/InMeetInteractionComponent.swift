//
//  InMeetInteractionComponent.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/19.
//

import Foundation

/// 可拖动的 reaction + chat 按钮，可展开 reaction 面板和聊天输入框
final class InMeetInteractionComponent: InMeetViewComponent {
    let componentIdentifier: InMeetViewComponentIdentifier = .interaction

    let interactionVC: FloatingInteractionViewController

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        let interactionVM: FloatingInteractionViewModel = viewModel.resolver.resolve()!
        interactionVC = FloatingInteractionViewController(viewModel: interactionVM)
        container.addContent(interactionVC, level: .floatingInteraction)
        container.addMeetLayoutStyleListener(interactionVC)
        viewModel.viewContext.addListener(interactionVC, for: [.singleVideo, .contentScene, .flowPageControl, .whiteboardMenu, .subtitle])

        let interpreterVM = viewModel.resolver.resolve(InMeetInterpreterViewModel.self)!
        interpreterVM.addObserver(interactionVC, fireImmediately: true)
    }

    private var floatingGuideToken: MeetingLayoutGuideToken?

    func setupConstraints(container: InMeetViewContainer) {
        let floatingGuideToken = container.layoutContainer.requestLayoutGuideFactory { ctx in
            return InMeetOrderedLayoutGuideQuery(topAnchor: .topShareBar,
                                                 bottomAnchor: .bottomSketchBar,
                                                 specificInsets: Display.phone && ctx.isLandscapeOrientation ? [.bottomShareBar: -4.0] : nil)
        }
        self.floatingGuideToken = floatingGuideToken
        floatingGuideToken.layoutGuide.identifier = "floating-interaction"

        // 确保在 setupConstraints 之后 interactionVC 才能用 container 上的约束进行布局
        interactionVC.container = container
        interactionVC.contentGuide = container.contentGuide
        interactionVC.interpreterGuide = container.interpreterGuide
        interactionVC.subtitleInitialGuide = container.subtitleInitialGuide
        interactionVC.chatInputKeyboardGuide = container.chatInputKeyboardGuide

        interactionVC.attachInteractionVerticalLayoutGuide(floatingGuideToken.layoutGuide)
        interactionVC.resetFloatingViewPosition()
        interactionVC.view.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.interactionVC.containerDidTransition()
    }
}
