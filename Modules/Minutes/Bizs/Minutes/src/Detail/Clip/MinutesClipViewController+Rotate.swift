//
//  MinutesClipViewController+Rotate.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

extension MinutesClipViewController {

    // MARK: - auto rotate
    public override var shouldAutorotate: Bool {
        let shouldShowVideoView = !(videoPlayer.isAudioOnly)
        if shouldShowVideoView {
            return true
        } else {
            return false
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.updateVideoView(size: size)
        }
    }
}
