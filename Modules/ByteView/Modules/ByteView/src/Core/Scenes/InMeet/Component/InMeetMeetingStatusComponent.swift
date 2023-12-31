//
//  InMeetMeetingStatusComponent.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/7.
//

import Foundation

final class InMeetMeetingStatusComponent: InMeetViewComponent {
    let componentIdentifier: InMeetViewComponentIdentifier = .meetingStatus

    let flowStatusVC: InMeetFlowStatusViewController

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        let flowStatusVM: InMeetFlowStatusViewModel = viewModel.resolver.resolve()!
        flowStatusVC = InMeetFlowStatusViewController(viewModel: flowStatusVM)
        container.addContent(flowStatusVC, level: .floatingMeetStatus)
        container.addMeetLayoutStyleListener(flowStatusVC)
        viewModel.viewContext.addListener(flowStatusVC, for: [.singleVideo, .contentScene, .flowPageControl, .sketchMenu, .showSpeakerOnMainScreen, .whiteboardMenu])
        flowStatusVC.contentGuide = container.contentGuide
        flowStatusVC.container = container
    }

    func setupConstraints(container: InMeetViewContainer) {
        flowStatusVC.updateMeetingStatusLayoutGuide()
        flowStatusVC.resetFloatingViewPosition()
        flowStatusVC.view.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.flowStatusVC.containerDidTransition()
    }
}
