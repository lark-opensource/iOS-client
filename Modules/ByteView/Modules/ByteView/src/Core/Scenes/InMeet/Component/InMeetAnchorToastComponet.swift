//
//  InMeetAnchorToastComponent.swift
//  ByteView
//
//  Created by lutingting on 2022/8/30.
//

import Foundation
import UIKit
import ByteViewUI

final class InMeetAnchorToastComponent: InMeetViewComponent {
    var componentIdentifier: InMeetViewComponentIdentifier = .anchorToast

    private weak var anchorToastView: AnchorToastView?
    private weak var container: InMeetViewContainer?
    private let view: UIView
    private let toolBarViewModel: ToolBarViewModel
    private let topBarViewModel: InMeetTopBarViewModel
    private(set) var currentToast: AnchorToastDescriptor?
    var currentLayoutType: LayoutType
    let context: InMeetViewContext

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard oldValue !== blockFullScreenToken else {
                return
            }
            oldValue?.invalidate()
        }
    }

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.view = container.loadContentViewIfNeeded(for: .anchorToast)
        self.container = container
        self.context = viewModel.viewContext
        self.currentLayoutType = layoutContext.layoutType
        self.toolBarViewModel = viewModel.resolver.resolve()!
        self.topBarViewModel = viewModel.resolver.resolve()!
        AnchorToast.shared.setComponent(component: self)
        toolBarViewModel.addListener(self)
    }

    // MARK: - Private
    private func setupToastView() {
        guard self.anchorToastView == nil else { return }
        let anchorToastView = AnchorToastView(frame: view.bounds)
        view.addSubview(anchorToastView)
        anchorToastView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.anchorToastView = anchorToastView
    }

    private func removeToastView() {
        anchorToastView?.removeFromSuperview()
        blockFullScreenToken = nil
        anchorToastView = nil
        currentToast = nil
    }

    private func updateCurrentToast() {
        guard let current = AnchorToast.shared.current,
              let anchorToastView = anchorToastView,
              let referenceView = referenceView(for: current.type) else { return }
        anchorToastView.updateLayout(referenceView: referenceView, distance: distance(for: current.type), arrowDirection: arrowDirection(for: current.type))
    }

    private func referenceView(for toastType: AnchorToastType) -> UIView? {
        switch toastType {
        case .participants, .attendees: return toolBarItemView(for: .participants)
        case .more: return toolBarItemView(for: .more)
        }
    }

    private func distance(for toastType: AnchorToastType) -> CGFloat? {
        return nil
    }

    private func arrowDirection(for toastType: AnchorToastType) -> TriangleView.Direction {
        return currentLayoutType.isPhoneLandscape ? .bottom : .top
    }

    private func toolBarItemView(for type: ToolBarItemType) -> UIView? {
        toolBarViewModel.itemOrContainerView(with: type)
    }

    func viewLayoutContextDidChanged() {
        if let currentToast = self.currentToast, currentToast.identifier == .handsUp {
            dismissToast(currentToast)
        } else {
            updateCurrentToast()
            self.anchorToastView?.isHidden = false
        }
    }

    func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {
        self.anchorToastView?.isHidden = true
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
    }

    func show(_ toast: AnchorToastDescriptor) {
        guard !toolBarViewModel.isExpanded, !context.isSingleVideoVisible, let view = referenceView(for: toast.type) else { return }
        self.currentToast = toast
        setupToastView()

        self.blockFullScreenToken = self.container?.fullScreenDetector.requestBlockAutoFullScreen()

        anchorToastView?.sureAction = { [weak self] in
            self?.removeToastView()
            toast.sureAction?()
        }
        anchorToastView?.pressToastAction = { [weak self] in
            self?.removeToastView()
            toast.pressToastAction?()
        }

        let toastType = toast.type
        anchorToastView?.setStyle(toast.title ?? "",
                                  actionTitle: toast.actionTitle,
                                  on: arrowDirection(for: toastType),
                                  of: view,
                                  distance: distance(for: toastType))
        if let duration = toast.duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismissToast(toast)
            }
        }
    }

    func dismissToast(_ toast: AnchorToastDescriptor) {
        guard let currentToast = self.currentToast, currentToast == toast else { return }
        anchorToastView?.sure()
        self.removeToastView()
    }
}

extension InMeetAnchorToastComponent: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        updateCurrentToast()
    }
}
