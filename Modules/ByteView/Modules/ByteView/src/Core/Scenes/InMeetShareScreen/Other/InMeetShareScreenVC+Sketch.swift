//
//  InMeetShareScreenVC+Sketch.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ByteViewNetwork
import ByteViewCommon
import ByteViewUI
import Whiteboard

extension SketchView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

extension SketchMenuView {
    var isTranslucent: Bool {
        return true
    }
}

extension InMeetShareScreenVC: InMeetShareScreenViewModelListener {

    func didChangeSketchEvent(newEvent: SketchEvent) {
        adaptSketchEventChange(newEvent: newEvent)
    }
    func didChangeSketchSettings(newSetting: SketchSettings) {
        adaptSketchEventChange(newSetting: newSetting)
    }

    func didChangeAdjustAnnotate(selfNeedAdjust: Bool, sharerNeedAdjust: Bool) {
        selfNeedAdjustAnnotate = selfNeedAdjust
        sharerNeedAdjustAnnotate = sharerNeedAdjust
    }

    func didChangeSketchPermissionStatus(newStatus: SketchPermissionStatus) {
        Util.runInMainThread {
            switch newStatus {
            case .invisible, .disabled, .isSharingPause, .noPermission:
                self.dismissSketchMenuView()
            case .enabled:
                break
            }
        }
        self.changeSketchBtnStatus(sketchPermissionStatus: newStatus, canShow: self.viewModel.canShowSketch)
    }

    func didChangeCanShowSketch(canShow: Bool) {
        self.changeSketchBtnStatus(sketchPermissionStatus: self.viewModel.sketchPermissionStatus, canShow: canShow)
    }

    func didChangeScreenSharedData(newData: ScreenSharedData) {
        Util.runInMainThread {
            let ccmInfo = newData.ccmInfo
            self.freeToBrowseButtonDisplayStyle = ccmInfo?.freeToBrowseButtonDisplayStyle ?? .hidden
            self.bottomView.freeToBrowseButtonDisplayStyle = ccmInfo?.freeToBrowseButtonDisplayStyle ?? .hidden
        }
    }

    func didChangeCursorInfo(newCursorInfo: CursorInfo) {
        Util.runInMainThread {
            self.videoView.sketchVideoWrapperView.updateCursor(info: newCursorInfo)
        }
    }

    func didChangeIsSharingPause(isPause: Bool) {
        Util.runInMainThread {
            if isPause, self.viewModel.isMenuShowingWhenSharingPause == true {
                Toast.showOnVCScene(I18n.View_G_SharePauseNoAnnoate, in: self.view)
            } else if self.needShowMenuView == true, let shareScreenData = self.viewModel.screenSharedData {
                self.showSketchMenuView(with: shareScreenData.shareScreenID, animated: true)
            }
        }
    }
}

extension InMeetShareScreenVC {

    func changeSketchBtnStatus(sketchPermissionStatus: SketchPermissionStatus, canShow: Bool) {
        Util.runInMainThread {
            let sketchBtn = self.bottomView.annotateButton
            switch (sketchPermissionStatus, canShow) {
            case (_, false):
                sketchBtn.isHidden = true
            case (.invisible, _):
                sketchBtn.isHidden = true
            case (.disabled, _):
                sketchBtn.isHidden = false
                sketchBtn.isEnabled = false
                sketchBtn.isLoading = false
            case (.isSharingPause, _):
                sketchBtn.isHidden = false
                sketchBtn.isEnabled = true
                sketchBtn.isLoading = false
            case (_, _):
                // no permission || enabled
                sketchBtn.isHidden = false
                sketchBtn.isEnabled = true
            }
        }
    }

    func adaptSketchEventChange(newEvent: SketchEvent? = nil, newSetting: SketchSettings? = nil) {
        Util.runInMainThread {
            guard let settings = newSetting ?? self.viewModel.sketchSettings else { return }
            let event = newEvent ?? self.viewModel.sketchEvent
            switch event {
            case .start(let data):
                let showMenuView = self.delegate?.isShareScreenSketchMenuEnabled() ?? false
                self.startSketch(shareScreenData: data,
                                  settings: settings,
                                  isActively: false,
                                  showMenuView: showMenuView)
            case .end(let data):
                self.endSketch(shareScreenData: data)
            case .update(old: let oldData, new: let newData):
                if self.sketchViewModel == nil {
                    let showMenuView = self.delegate?.isShareScreenSketchMenuEnabled() ?? false
                    self.startSketch(shareScreenData: newData,
                                      settings: settings,
                                      isActively: false,
                                      showMenuView: showMenuView)
                } else {
                    self.updateSketch(oldData: oldData, newData: newData)
                }
            case .change(old: let oldData, new: let newData):
                self.endSketch(shareScreenData: oldData)
                let showMenuView = self.delegate?.isShareScreenSketchMenuEnabled() ?? false
                self.startSketch(shareScreenData: newData,
                                  settings: settings,
                                  isActively: false,
                                  showMenuView: showMenuView)
            // 暂停共享状态，对标注已有内容不产生影响，仅使其无法使用标注功能。
            case .pause(let data):
                if self.sketchViewModel == nil, data.isSketch {
                    self.startSketch(shareScreenData: data,
                                      settings: settings,
                                      isActively: false,
                                      showMenuView: false)
                }
            default:
                break
            }
        }
    }

    private static let sketchLoadingIdentifier = "sketchLoadingIdentifier"

    func bindSketch() {
        bottomView.annotateButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.didTapStartSketch()
            })
            .disposed(by: self.disposeBag)
    }

    func createSketchMenuView() -> SketchMenuView {
        let sketchMenuView = SketchMenuView(frame: .zero, isSaveEnabled: viewModel.setting.isWhiteboardSaveEnabled)
        sketchMenuView.delegate = self
        return sketchMenuView
    }

    func startOrStopLoading(isLoading: Bool) {
        Util.runInMainThread {
            self.bottomView.annotateButton.isLoading = isLoading
        }
    }

    func didTapStartSketch() {
        MeetingTracksV2.trackClickAnnotate(isSharingContent: viewModel.meeting.shareData.isSharingContent,
                                           isMinimized: false,
                                           isMore: false)
        switch self.viewModel.sketchPermissionStatus {
        case .enabled:
            Util.runInMainThread {
                guard let data = self.viewModel.screenSharedData, let sketchSettings = self.viewModel.sketchSettings else { return }
                self.startSketch(shareScreenData: data,
                                 settings: sketchSettings,
                                 isActively: true)
            }
            SketchTracks.trackClickAnnotate(meetType: viewModel.meeting.type)
        case .noPermission:
            ByteViewDialog.Builder()
                .title(I18n.View_VM_ThePersonSharingShortNew)
                .message(I18n.View_VM_ThePersonSharingDescriptionNew)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    SketchTracks.trackCancelAccessibility()
                })
                .rightTitle(I18n.View_M_SendRequest)
                .rightHandler({ [accessAction = self.viewModel.requestSketchAccessAction] _ in
                    accessAction.execute()
                    SketchTracks.trackRequestAccessibility()
                })
                .show()
        case .isSharingPause:
            Toast.showOnVCScene(I18n.View_G_NoAnnotatePauseShare)
        case .disabled, .invisible:
            break
        }
    }

    private func startSketch(shareScreenData: ScreenSharedData,
                             settings: SketchSettings,
                             isActively: Bool,
                             showMenuView: Bool = false) {
        ByteViewSketch.logger.info("startSketch(id: \(shareScreenData.shareScreenID), isActively: \(isActively))")
        self.viewModel.startSketch()
        if isActively && viewModel.meeting.service.shouldShowGuide(.followerStartAnnoate) {
            Toast.show(I18n.View_G_AnnotationsVisibleToAll, style: .emphasize)
            viewModel.meeting.service.didShowGuide(.followerStartAnnoate)
            SketchTracks.trackOnboardingToast()
        }
        if self.sketchViewModel == nil {
            let canvasSize = CGSize(width: CGFloat(shareScreenData.width),
                                    height: CGFloat(shareScreenData.height))
            let currentAcount = viewModel.meeting.account
            let sketch = RustSketch(deviceID: currentAcount.deviceId,
                                    userID: currentAcount.id,
                                    userType: .larkUser,
                                    logInstance: RustSketch.defaultLogInstance,
                                    settings: settings,
                                    currentStep: 0)
            if self.sketchMenuView == nil {
                self.sketchMenuView = createSketchMenuView()
            }
            let sketchService = SketchService(meeting: viewModel.meeting,
                                                  shareScreenID: shareScreenData.shareScreenID)
            let sketchViewModel = SketchViewModel(sketch: sketch,
                                                  sketchService: sketchService,
                                                  meeting: viewModel.meeting,
                                                  selfNeedAdjustAnnotate: selfNeedAdjustAnnotate,
                                                  sharerNeedAdjustAnnotate: sharerNeedAdjustAnnotate,
                                                  canvasSize: canvasSize)
            self.sketchViewModel = sketchViewModel
            self.sketchViewModel?.delegate = self
            sketchView = SketchView()
            sketchView?.clipsToBounds = true
            sketchView?.bindViewModel(sketch: sketchViewModel)
            self.videoView.sketchVideoWrapperView.sketchView = sketchView
            if isActively {
                startOrStopLoading(isLoading: true)
            }
            sketchViewModel.startSketch(isActive: isActively, shouldShowMenu: showMenuView, shareScreenData: shareScreenData)
        } else if isActively, sketchViewModel?.currentStatus == .connected {
            showSketchMenuView(with: shareScreenData.shareScreenID, animated: true)
        } else {
            if isActively {
                startOrStopLoading(isLoading: true)
            }
            sketchViewModel!.startSketch(isActive: isActively, shouldShowMenu: showMenuView, shareScreenData: shareScreenData)
        }
    }

    private func endSketch(shareScreenData: ScreenSharedData) {
        ByteViewSketch.logger.info("endSketch")
        viewModel.stopSketch()
        needShowMenuView = false
        cleanupSketch()
    }

    private func cleanupSketch() {
        ByteViewSketch.logger.info("cleanupSketch")
//        if hasSharedScreenGridCell {
//            sharedScreenGridCell?.gridViews.first?.sketchVideoWrapperView.sketchView = nil
//        }
        videoView.sketchVideoWrapperView.sketchView = nil
        sketchView = nil
        sketchViewModel = nil
        dismissSketchMenuView()
    }

    private func updateSketch(oldData: ScreenSharedData,
                              newData: ScreenSharedData) {
        guard let sketchVM = sketchViewModel else {
            return
        }
        if sketchVM.updateSketch(oldData: oldData,
                                 newData: newData),
            let gest = sketchGest,
            gest.isEnabled {
            gest.isEnabled = false
            gest.isEnabled = true
        }
    }

    private func showSketchMenuView(with shareScreenID: String, animated: Bool = false) {
        ByteViewSketch.logger.info("showSketchMenuView start currentColor: \(viewModel.currentColor), currentTool: \(viewModel.currentTool)")
        guard let sketchMenuView = self.sketchMenuView,
            let sketchView = self.videoView.sketchVideoWrapperView.sketchView else {
                ByteViewSketch.logger.error("showSketchMenuView failed, can't locate sketchView")
                return
        }
        if self.sketchGest != nil {
            ByteViewSketch.logger.error("showSketchMenuView called while another sketchGest is attached")
            dismissSketchMenuView()
        }
        self.needShowMenuView = false
        self.viewModel.isMenuShowing = true
        self.sketchGest = WhiteboardGestRecognizer()
        guard let sketchGest = self.sketchGest else { return }
        self.sketchGest?.isWhiteboardScene = false
        sketchGest.touchDelegate = sketchView
        sketchGest.delegate = sketchView
        sketchGest.isTracking
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isTracking in
                if isTracking {
                    self?.sketchMenuView?.fadeOut()
                } else {
                    self?.sketchMenuView?.fadeIn()
                }
            })
            .disposed(by: sketchMenuDisposeBag)

        self.sketchMenuView?.undoButton.isEnabled = sketchViewModel?.canUndo ?? false

        // 避免 collectionView.reloadData() 导致 touchesCancelled
        if view.isPhoneLandscape {
            view.addGestureRecognizer(sketchGest)
        } else {
            sketchView.addGestureRecognizer(sketchGest)
        }

        if sketchMenuView.currentShareScreenID != shareScreenID {
            if let color = viewModel.currentColor {
                sketchMenuView.setDefaultConfiguration(color: color, shareScreenID: shareScreenID, tool: viewModel.currentTool)
            } else {
                if let defaultColor = sketchViewModel?.getDefaultColor() {
                    sketchMenuView.setDefaultConfiguration(color: defaultColor, shareScreenID: shareScreenID, tool: viewModel.currentTool)
                }
            }
        }

        self.view.addSubview(sketchMenuView)
        self.isSketchEnabled = true
        sketchMenuView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(parentContainerGuide.snp.bottom)
        }
        sketchMenuView.backgroundView?.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.parentContainerGuide.snp.bottom)
        }
        sketchMenuView.gradientLayer.isHidden = false
        self.view.layoutIfNeeded()
        // nolint-next-line: magic number
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.bottomView.alpha = 0.0
            self.updateBottomViewConstraint()
            sketchMenuView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.contentLayoutGuide)
            }
            self.delegate?.shareScreenDidShowSketchMenu(sketchMenuView)
            self.view.window?.layoutIfNeeded()
        }, completion: { _ in
            guard self.isSketchEnabled else {
                return
            }
            self.bottomView.isHidden = true
        })
    }

    private func dismissSketchMenuView() {
        guard self.isSketchEnabled,
              self.sketchMenuView?.superview != nil else {
            return
        }
        self.needShowMenuView = viewModel.screenSharedData?.isSharingPause ?? false
        self.viewModel.isMenuShowing = false
        if let gest = sketchGest {
            self.view.removeGestureRecognizer(gest)
            self.sketchView?.removeGestureRecognizer(gest)
        }
        sketchGest = nil
        sketchMenuDisposeBag = DisposeBag()

        sketchMenuView?.gradientLayer.isHidden = true
        self.isSketchEnabled = false
//        self.container.setSubView(self.bottomView, direction: Display.phone ? .bottom : .top,
//                                  originView: self.sketchMenuView, originDirection: .bottom,
//                                  animateIn: false,
//                                  animateOut: true) {
//            self.delegate?.shareScreenDidHideSketchMenu()
//        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.bottomView.isHidden = false
            self.bottomView.alpha = 1.0
            self.updateBottomViewConstraint()
            self.delegate?.shareScreenDidHideSketchMenu()
            self.sketchMenuView?.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.parentContainerGuide.snp.bottom)
            }
            // 加common ancestor检查，避免crash
//            if let shareBarGuide = self.shareBarGuide, shareBarGuide.canUse(on: self.bottomView) {
//                self.shareBarGuide?.snp.remakeConstraints { make in
//                    make.edges.equalTo(self.bottomView)
//                }
//            }
            self.view.window?.layoutIfNeeded()
        }, completion: { _ in
            guard self.isSketchEnabled == false else {
                return
            }
            self.sketchMenuView?.removeFromSuperview()
        })
    }
}

extension InMeetShareScreenVC: SketchViewModelDelegate {
    func showMenuView(shareScreenID: String, animated: Bool) {
        Util.runInMainThread {
            self.showSketchMenuView(with: shareScreenID, animated: animated)
        }
    }

    func stopButtonLoading() {
        startOrStopLoading(isLoading: false)
    }

    func showOtherCannotSketchTip() {
        self.viewModel.showOtherCannotSketchTip()
    }

    func changeUndoState(canUndo: Bool) {
        self.sketchMenuView?.undoButton.isEnabled = canUndo
    }

    func changeCanvasSize(newSize: CGSize) {
        Util.runInMainThread {
            self.sketchView?.setNeedsLayout()
        }
    }

    func didChangeSketchData() {
        viewModel.meeting.shareData.isSketchSaved = false
    }
}

extension InMeetShareScreenVC: SketchMenuViewDelegate {
    func didChangeTool(newTool: ActionType, color: UIColor) {
        self.sketchViewModel?.setNewToolOrColor(tool: newTool, color: color)
        self.viewModel.currentTool = newTool
    }

    func didChangeColor(currentTool: ActionType, newColor: UIColor) {
        self.sketchViewModel?.setNewToolOrColor(tool: currentTool, color: newColor)
        self.viewModel.currentColor = newColor
    }

    func didTapUndo() {
        self.sketchViewModel?.didTapUndo()
    }

    func didTapExit() {
        self.dismissSketchMenuView()
    }

    func didTapSave() {
        let saveBlock: (UIView?) -> Void = { watermarkView in
            self.saveSketch(with: watermarkView)
        }
        let getGlobalWatermarkView: () -> Void = {
            self.viewModel.meeting.service.larkUtil.getWatermarkView {
                saveBlock($0)
            }
        }
        if viewModel.shareWatermark.showWatermarkRelay.value {
            // 若有全局水印会返回 nil，此时需要重新拉取全局水印
            viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView()
                .take(1)
                .subscribe(onNext: {
                    if let watermarkView = $0 {
                        saveBlock(watermarkView)
                    } else {
                        getGlobalWatermarkView()
                    }
                }).disposed(by: rx.disposeBag)
        } else {
            getGlobalWatermarkView()
        }
    }

    private func saveSketch(with watermarkView: UIView?) {
        guard !isSketchSaving else {
            self.logger.debug("save sketch is running, skip")
            return
        }
        isSketchSaving = true
        self.logger.debug("save sketch start")
        SketchTracks.trackClickSave(is_sharer: viewModel.meeting.shareData.isMySharingScreen)

        guard let renderImage = videoView.sketchVideoWrapperView.videoView.createRenderImage() else {
            self.logger.error("save sketch failed: render image error")
            isSketchSaving = false
            return
        }
        guard let sketchLayer: CALayer = videoView.sketchVideoWrapperView.sketchView?.layer.vc.copy() else {
            self.logger.error("save sketch failed: layer copy error")
            isSketchSaving = false
            return
        }
        let videoImage = renderImage.ud.scaled(by: videoView.sketchVideoWrapperView.bounds.height / renderImage.size.height)
        let layer = CALayer()
        layer.bounds = .init(origin: .zero, size: videoImage.size)
        layer.addSublayer(UIImageView(image: videoImage).layer)
        layer.addSublayer(sketchLayer)

        if let watermarkView = watermarkView {
            self.logger.debug("save sketch with watermark")
            watermarkView.frame = .init(origin: .zero, size: renderImage.size)
            layer.addSublayer(watermarkView.layer)
            // 需要强制渲染一下，否则不显示水印
            layer.setNeedsLayout()
            layer.layoutIfNeeded()
        }
        let isOpaque = layer.isOpaque
        let bounds = layer.bounds

        DispatchQueue.main.async {
            DispatchQueue.global(qos: .userInteractive).async {
                // 此步骤会造成主线程阻塞，放子线程处理
                guard let data = layer.vc.toImage(isOpaque: isOpaque, bounds: bounds).pngData() else {
                    self.logger.error("save sketch failed: image to data error")
                    self.isSketchSaving = false
                    return
                }
                PhotoManager.shared.savePhoto(data: data) { result in
                    switch result {
                    case .success:
                        self.logger.debug("save sketch success")
                        Toast.show(I18n.View_G_SavedToAlbum_Toast)
                        self.viewModel.meeting.shareData.isSketchSaved = true
                    case .failure(let error):
                        self.logger.error("save sketch failed: \(error.localizedDescription)")
                    }
                    self.isSketchSaving = false
                }
            }
        }
    }
}
