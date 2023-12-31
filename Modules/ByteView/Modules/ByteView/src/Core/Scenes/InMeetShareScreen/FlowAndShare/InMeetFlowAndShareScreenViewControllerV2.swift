//
//  InMeetFlowAndShareScreenViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/4/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import SnapKit

class InMeetFlowAndShareScreenViewControllerV2: InMeetFlowAndShareContainerViewControllerV2 {

    var sketchMenuView: SketchMenuView? {
        guard let vc = shareScreenVC as? InMeetShareScreenVC else { return nil }
        return vc.sketchMenuView
    }

    weak var shareDelegate: InMeetShareScreenVCDelegate?

    convenience init(gridViewModel: InMeetGridViewModel, shareViewModel: InMeetShareScreenVM, shareDelegate: InMeetShareScreenVCDelegate) {
        let shareScreenVC = InMeetShareScreenVC(viewModel: shareViewModel)
        shareScreenVC.videoView.streamRenderView.isCellVisible = false
        self.init(gridViewModel: gridViewModel, shareVC: shareScreenVC, hasShrinkView: true)
        self.shareDelegate = shareDelegate
        shareScreenVC.delegate = self
        shareScreenVC.container = self.container
        shareViewModel.addListener(shareScreenVC)
        GuideManager.shared.addListener(shareScreenVC)
        addChild(shareScreenVC)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func makeConstraints() {
        super.makeConstraints()
    }

    override func updatePageControlLayout() {
        super.updatePageControlLayout()
    }


    override func updateShareScreenPageControl() {
        super.updateShareScreenPageControl()
        if viewModel.context.isSketchMenuEnabled {
            shareScreenPageControl.isHidden = true
        } else {
            shareScreenPageControl.isHidden = false
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        if cell is InMeetShareScreenGridCell,
           let vc = self.shareScreenVC as? InMeetShareScreenVC {
            vc.videoView.streamRenderView.isCellVisible = true
        }
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        if cell is InMeetShareScreenGridCell,
           let vc = self.shareScreenVC as? InMeetShareScreenVC {
            vc.videoView.streamRenderView.isCellVisible = false
        }
    }
}

extension InMeetFlowAndShareScreenViewControllerV2: InMeetShareScreenVCDelegate {
    func shareScreenDidShowSketchMenu(_ sketchMenuView: UIView) {
        shareDelegate?.shareScreenDidShowSketchMenu(sketchMenuView)
        updateShareScreenPageControl()
    }

    func shareScreenDidHideSketchMenu() {
        shareDelegate?.shareScreenDidHideSketchMenu()
        updateShareScreenPageControl()
    }

    func isShareScreenSketchMenuEnabled() -> Bool {
        shareDelegate?.isShareScreenSketchMenuEnabled() ?? viewModel.context.isSketchMenuEnabled
    }
}
