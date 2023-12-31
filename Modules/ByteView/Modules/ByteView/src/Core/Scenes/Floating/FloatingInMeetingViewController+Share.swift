//
//  FloatingInMeetingViewController+Share.swift
//  ByteView
//
//  Created by liujianlong on 2023/5/25.
//

import Foundation
import RxSwift
import RxCocoa

extension FloatingInMeetingViewController {
    func displayShareScreen() {
        guard self.shareScreenVideoVC == nil,
              let vm = self.viewModel.shareScreenVM else {
            return
        }
        cleanAllShareVC()
//        let shareScreenHintView = FloatingHintView.makeShareScreenHintView()

        let vc = InMeetShareScreenVideoVC(viewModel: vm)
        if isPIPFloatingVC, viewModel.meeting.pip.isSampleBufferRenderEnabled {
            vc.streamRenderView.rendererType = .sampleBufferLayer
        } else {
            vc.streamRenderView.rendererType = .metalLayer
        }
        self.shareScreenVideoVC = vc

        let view = UIView()
        view.addSubview(vc.view)

        vc.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        let hintView = createFloatingShareLoadingHintView()
        view.addSubview(hintView)
        hintView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        vc.streamRenderView.addRenderingCallback { [weak vc] isRendering in
            hintView.isHidden = isRendering
            vc?.view.isHidden = !isRendering
        }
        vc.streamRenderView.shouldIgnoreAppState = isPIPFloatingVC
        self.floatingView.contentView = view
    }

    func displayWhiteboard() {
        guard self.whiteboardViewController == nil else {
            return
        }
        cleanAllShareVC()
        let vm = InMeetWhiteboardViewModel(resolver: viewModel.resolver)
        let wbVC = InMeetWhiteboardViewController(viewModel: vm)
        wbVC.isContentOnly = true
        wbVC.whiteboardVC.setLayerMiniScale()

        self.whiteboardViewController = wbVC
        self.floatingView.contentView = wbVC.view

    }

    func displayMSThumbnail() {
        guard self.msThumbVC == nil else {
            return
        }
        cleanAllShareVC()
        let vm = InMeetFollowThumbnailVM(meeting: self.viewModel.meeting, resolver: viewModel.resolver)
        var thumbnailSize: CGSize?
        if self.viewModel.context.floatingWindowSize.width > 0 && self.viewModel.context.floatingWindowSize.height > 0 {
            thumbnailSize = self.viewModel.context.floatingWindowSize
        }
        let vc = InMeetFollowThumbnailVC(viewModel: vm, thumbnailSize: thumbnailSize)
        self.msThumbVC = vc

        let view = UIView()
        view.addSubview(vc.view)

        vc.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        let hintView = createFloatingShareLoadingHintView()
        view.addSubview(hintView)
        hintView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.isThumbnailLoadedCallback = { [weak vc] loaded in
            hintView.isHidden = loaded
            vc?.view.isHidden = !loaded
        }

        self.floatingView.contentView = view
    }

    func displayParticipant() {
        guard self.participantView == nil else {
            return
        }
        cleanAllShareVC()
        let content: FloatingParticipantView
        if isPIPFloatingVC {
            content = viewModel.meeting.pip.participantView
        } else {
            content = FloatingParticipantView()
        }
        content.streamRenderView.multiResSubscribeConfig = self.subscribeConfig
        content.streamRenderView.bindMeetingSetting(viewModel.meeting.setting)
        self.participantView = content
        self.floatingView.contentView = content
    }

    private func cleanAllShareVC() {
        self.shareScreenVideoVC = nil
        self.whiteboardViewController = nil
        self.msThumbVC = nil
        self.participantView = nil
    }
}
