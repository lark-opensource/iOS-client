//
//  FloatingContainerViewController.swift
//  ByteView
//
//  Created by Prontera on 2021/6/2.
//

import Foundation
import ByteViewNetwork

class FloatingContainerViewController: VMViewController<InMeetViewModel>, InMeetDataListener, InMeetShareDataListener {
    private var isShareScreenMeeting = false
    private var child: UIViewController? { children.first }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = nil
        isShareScreenMeeting = viewModel.meeting.subType == .screenShare
        setCurrentVC()
    }

    override func bindViewModel() {
        viewModel.meeting.data.addListener(self)
        viewModel.meeting.shareData.addListener(self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func createInMeetingVC() -> FloatingInMeetingViewController {
        FloatingInMeetingViewController(viewModel: InMeetFloatingViewModel(resolver: viewModel.resolver))
    }

    private func setCurrentVC() {
        let inMeetingInfo = viewModel.meeting.data.inMeetingInfo
        let inMagicShare = inMeetingInfo?.followInfo?.url.isEmpty == false
        let resolver = viewModel.resolver
        let vc: UIViewController
        if isShareScreenMeeting && viewModel.meeting.shareData.isSharingWhiteboard {
            let vm = InMeetWhiteboardViewModel(resolver: resolver)
            let wbVC = InMeetWhiteboardViewController(viewModel: vm)
            wbVC.isContentOnly = true
            wbVC.whiteboardVC.setLayerMiniScale()
            vc = wbVC
        } else if isShareScreenMeeting && !inMagicShare {
            vc = FloatingSelfShareScreenViewController(viewModel: resolver.resolve(InMeetSelfShareScreenViewModel.self)!)
        } else {
            vc = createInMeetingVC()
        }
        let from = self.child
        addChild(vc)
        from?.willMove(toParent: nil)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        guard newScene.shareScreenData != oldScene.shareScreenData else { return }
        if oldScene.shareScreenData != nil, newScene.shareScreenData?.identifier != oldScene.shareScreenData?.identifier {
            Util.runInMainThread { [weak self] in
                self?.viewModel.viewContext.isSketchMenuEnabled = false
            }
        }
        let isLocalProjection = viewModel.meeting.shareData.isLocalProjection
        if self.isShareScreenMeeting != isLocalProjection {
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                self.isShareScreenMeeting = isLocalProjection
                self.setCurrentVC()
                self.viewModel.router.window?.updateLayout(animated: true)
            }
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        InMeetOrientationToolComponent.statusBarOrientationRelay.accept(view.orientation ?? (Display.pad ? .landscapeRight : .portrait))
    }
}

extension FloatingContainerViewController: FloatingWindowTransitioning {
    private var transitioningObject: FloatingWindowTransitioning? {
        child as? FloatingWindowTransitioning
    }

    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        transitioningObject?.floatingWindowWillTransition(to: frame, isFloating: isFloating)
    }

    func floatingWindowWillChange(to isFloating: Bool) {
        transitioningObject?.floatingWindowWillChange(to: isFloating)
    }

    func floatingWindowDidChange(to isFloating: Bool) {
        transitioningObject?.floatingWindowDidChange(to: isFloating)
    }

    func animateAlongsideFloatingWindowTransition(to frame: CGRect, isFloating: Bool) {
        transitioningObject?.animateAlongsideFloatingWindowTransition(to: frame, isFloating: isFloating)
    }

    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) {
        transitioningObject?.floatingWindowDidTransition(to: frame, isFloating: isFloating)
    }
}
