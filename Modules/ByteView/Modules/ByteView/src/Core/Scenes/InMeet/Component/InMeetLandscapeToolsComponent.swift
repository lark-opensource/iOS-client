//
//  InMeetLandscapeToolsComponent.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/5/18.
//

import Foundation

/// iPhone 横屏模式顶部 topBar 点击更多按钮出现的工具面板
///     - 提供 layoutGuide: landscapeTools
final class InMeetLandscapeToolsComponent: InMeetViewComponent {
    let componentIdentifier: InMeetViewComponentIdentifier = .landscapeTools
    var landscapeMoreVC: LandscapeMoreViewController?
    private weak var container: InMeetViewContainer?
    private let resolver: InMeetViewModelResolver
    private var isLandscapeVCInitialized = false
    private var readyToSetupConstraints = false
    private var currentLayoutType: LayoutType

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        self.resolver = viewModel.resolver
        self.currentLayoutType = layoutContext.layoutType
        if layoutContext.layoutType.isPhoneLandscape {
            initLandscapeToolsView()
        }
    }

    func setupConstraints(container: InMeetViewContainer) {
        readyToSetupConstraints = true
        guard let landscapeMoreVC = landscapeMoreVC else {
            return
        }

        landscapeMoreVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func showLandscapeMoreView() {
        landscapeMoreVC?.show(animated: true)
    }

    func hideLandscapeMoreView(completion: (() -> Void)?) {
        _ = landscapeMoreVC?.hide(animated: true, completion: completion)
    }

    private func initLandscapeToolsView() {
        guard let container = container, !isLandscapeVCInitialized else {
            return
        }

        let toolbarVM: ToolBarViewModel = resolver.resolve()!
        let landscapeMoreVC = LandscapeMoreViewController(viewModel: toolbarVM)
        container.addContent(landscapeMoreVC, level: .landscapeTools)
        self.landscapeMoreVC = landscapeMoreVC
        isLandscapeVCInitialized = true
        if readyToSetupConstraints {
            setupConstraints(container: container)
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        if newContext.layoutType.isPhoneLandscape {
            self.initLandscapeToolsView()
        }
    }
}
