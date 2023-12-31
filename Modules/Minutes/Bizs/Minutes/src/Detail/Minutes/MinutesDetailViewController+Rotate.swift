//
//  MinutesDetailViewController+VideoView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/1/31.
//

extension MinutesDetailViewController {

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
        if isSearching {
            self.searchView.finishSearching()
        }
        coordinator.animate { _ in
            if self.isText {

            } else {
                self.updateVideoView(size: size)
            }
        }
    }
}
