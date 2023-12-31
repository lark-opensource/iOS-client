//
//  InMeetShareComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

/// 共享区域的显示，包含follow、shareScreen、mySharingScreen
///     - 提供 layoutGuide: shareBar
final class InMeetShareComponent: InMeetViewComponent {
    let view = UIView()
    /// contentViewController, follow or share screen
    fileprivate var vc: UIViewController?
    private let logger = Logger.ui
    private weak var container: InMeetViewContainer?
    private let disposeBag = DisposeBag()
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let resolver: InMeetViewModelResolver

    private var sketchBlockFullScreenToken: BlockFullScreenToken?
    private var whiteboardBlockFullScreenToken: BlockFullScreenToken?

    let shareExternalGuideToken: MeetingLayoutGuideToken

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.context = viewModel.viewContext
        self.resolver = viewModel.resolver
        self.meeting = viewModel.meeting
        self.container = container
        self.shareExternalGuideToken = container.layoutContainer.requestLayoutGuideFactory { ctx in
            let query = InMeetOrderedLayoutGuideQuery(topAnchor: .topShrinkBar,
                                                      bottomAnchor: .bottomToolbar,
                                                      specificInsets: Display.phone && ctx.isLandscapeOrientation ? [.bottomSafeArea: -4.0] : nil)
            return query
        }
        context.addListener(self, for: [.contentScene, .sketchMenu, .showSpeakerOnMainScreen, .whiteboardMenu])
        meeting.shareData.addListener(self)
        meeting.webSpaceData.addListener(self)
        updateFullScreenBlock()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .share
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        // 用于大小窗回来刷新共享状态
        recoverShareContentModeIfNeeded()
    }

    func setupConstraints(container: InMeetViewContainer) {
    }

    private func trackFollow(isSheet: Bool) {
        if VCScene.isLandscape, !isSheet {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .share_doc_note)
        } else if !VCScene.isLandscape, isSheet {
            MeetingTracksV2.trackChangeOrientation(toLandscape: true, reason: .share_sheet)
        }
    }

}

extension InMeetShareComponent: InMeetShareScreenVCDelegate, InMeetViewChangeListener, InMeetWhiteboardDelegate {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .sketchMenu, .contentScene, .showSpeakerOnMainScreen, .whiteboardMenu:
            updateFullScreenBlock()
        default:
            return
        }
    }

    func shareScreenDidShowSketchMenu(_ sketchMenuView: UIView) {
        guard !context.isSketchMenuEnabled else {
            return
        }
        context.isSketchMenuEnabled = true
    }

    func shareScreenDidHideSketchMenu() {
        guard context.isSketchMenuEnabled else {
            return
        }
        context.isSketchMenuEnabled = false
    }

    func isShareScreenSketchMenuEnabled() -> Bool {
        return context.isSketchMenuEnabled
    }

    func whiteboardDidShowMenu() {
        guard !context.isWhiteboardMenuEnabled else {
            return
        }
        context.isWhiteboardMenuEnabled = true
    }

    func whiteboardDidHideMenu(isUpdate: Bool) {
        guard context.isWhiteboardMenuEnabled else {
            return
        }
        context.isWhiteboardMenuEnabled = false
    }

    func isWhiteboardMenuEnabled() -> Bool {
        return context.isWhiteboardMenuEnabled
    }

    func whiteboardEditAuthorityChanged(canEdit: Bool) {
        guard context.isWhiteboardEditEnable != canEdit else { return }
        context.isWhiteboardEditEnable = canEdit
    }

    private func updateFullScreenBlock() {
        let scene = context.meetingScene
        let isSketchMenuEnabled = context.isSketchMenuEnabled
        let isWhiteboardMenuEnabled = context.isWhiteboardMenuEnabled
        let isShowSpeakerOnMainScreen = context.isShowSpeakerOnMainScreen
        let shouldBlockFullScreen = isSketchMenuEnabled && scene != .gallery && !isShowSpeakerOnMainScreen
        let whiteboardShouldBlockFullScreen = isWhiteboardMenuEnabled && scene != .gallery && !isShowSpeakerOnMainScreen
        if shouldBlockFullScreen && sketchBlockFullScreenToken == nil {
            self.sketchBlockFullScreenToken = container?.fullScreenDetector.requestBlockAutoFullScreen()
        } else if !shouldBlockFullScreen {
            self.sketchBlockFullScreenToken?.invalidate()
            self.sketchBlockFullScreenToken = nil
        }
        if whiteboardShouldBlockFullScreen && whiteboardBlockFullScreenToken == nil {
            self.whiteboardBlockFullScreenToken = container?.fullScreenDetector.requestBlockAutoFullScreen()
        } else if !whiteboardShouldBlockFullScreen {
            self.whiteboardBlockFullScreenToken?.invalidate()
            self.whiteboardBlockFullScreenToken = nil
        }
    }
}

extension InMeetShareComponent {
    func makeVCWithContent(_ content: InMeetSceneManager.ContentMode) -> (UIViewController & ShareContentVC)? {
        switch content {
        case .follow:
            guard let manager = resolver.resolve(InMeetFollowManager.self) else {
                return nil
            }
            let vm = InMeetFollowViewModel(meeting: meeting, context: context, manager: manager, resolver: resolver)
            let vc = FollowContainerViewController(viewModel: vm)
            vc.container = self.container
            trackFollow(isSheet: vm.manager.currentRuntime?.documentInfo.shareSubType.isSheetStyle == true)
            return vc
        case .shareScreen:
            if meeting.shareData.shareContentScene.shareScreenData == nil {
                logger.error("showContent \(content) failed: shareScreenViewModel is nil")
                return nil
            }
            if let vm = resolver.resolve(InMeetShareScreenVM.self) {
                let shareScreenVC = InMeetShareScreenVC(viewModel: vm, delegate: self)
                shareScreenVC.container = self.container
                GuideManager.shared.addListener(shareScreenVC)
                return shareScreenVC
            }
            return nil
        case .selfShareScreen:
            if let vm = resolver.resolve(InMeetSelfShareScreenViewModel.self) {
                let vc = InMeetSelfShareScreenViewController(viewModel: vm)
                self.container?.addMeetSceneModeListener(vc)
                self.container?.addMeetLayoutStyleListener(vc)
                return vc
            }
            return nil
        case .whiteboard:
            let vm = InMeetWhiteboardViewModel(resolver: resolver)
            let vc = InMeetWhiteboardViewController(viewModel: vm, delegate: self)
            return vc
        case .webSpace:
            guard let manager = resolver.resolve(InMeetWebSpaceManager.self), manager.hasData else {
                Logger.webSpace.error("showContent \(content) failed: no data")
                return nil
            }
            let vm = InMeetWebSpaceViewModel(manager: manager, resolver: resolver)
            let vc = InMeetWebSpaceContainerViewController(viewModel: vm)
            container?.addMeetSceneModeListener(vc)
            return vc
        case .flow:
            return nil
        }
    }

    func makeLandscapeVC(gridViewModel: InMeetGridViewModel, stageVC: WebinarStageVC) -> InMeetFlowAndStageViewController {
        let vc = InMeetFlowAndStageViewController(gridViewModel: gridViewModel, stageVC: stageVC)
        vc.container = self.container
        vc.delegate = (container?.component(by: .flow) as? InMeetFlowComponent)
        if let listener = vc.shareScreenVC as? MeetingLayoutStyleListener {
            self.container?.addMeetLayoutStyleListener(listener)
        }
        return vc
    }

    func makeLandscapeVCWithContent(_ content: InMeetSceneManager.ContentMode) -> InMeetFlowViewControllerV2? {
        guard let container = self.container else {
            return nil
        }
        switch content {
        case .shareScreen:
            if let gridViewModel = resolver.resolve(InMeetGridViewModel.self),
               let shareViewModel = resolver.resolve(InMeetShareScreenVM.self),
               let flowComponent = container.component(by: .flow) as? InMeetFlowComponent {
                let vc = InMeetFlowAndShareScreenViewControllerV2(gridViewModel: gridViewModel, shareViewModel: shareViewModel, shareDelegate: self)
                vc.container = self.container
                vc.delegate = flowComponent
                if let listener = vc.shareScreenVC as? MeetingLayoutStyleListener {
                    self.container?.addMeetLayoutStyleListener(listener)
                }
                return vc
            }
        case .whiteboard:
            let vm = InMeetWhiteboardViewModel(resolver: resolver)
            let whiteBoardVC = InMeetWhiteboardViewController(viewModel: vm)
            if let gridViewModel = resolver.resolve(InMeetGridViewModel.self),
               let flowComponent = container.component(by: .flow) as? InMeetFlowComponent {
                let vc = InMeetFlowAndWhiteBoardViewControllerV2(gridViewModel: gridViewModel, whiteBoardVC: whiteBoardVC, shareDelegate: self)
                vc.container = self.container
                vc.delegate = flowComponent
                if let listener = vc.shareScreenVC as? MeetingLayoutStyleListener {
                    self.container?.addMeetLayoutStyleListener(listener)
                }
                return vc
            }
        default:
            return nil
        }
        return nil
    }

    var shareScreenVM: InMeetShareScreenVM? {
        resolver.resolve(InMeetShareScreenVM.self)
    }
    func configureShareScreenCell(_ cell: InMeetGalleryShareContentCell) {
        Logger.scene.info("configure shareScreen cell")
        guard let shareScreenVM = self.shareScreenVM else {
            cell.setShareContentVC(nil)
            return
        }
        let vc = InMeetShareScreenVideoVC(viewModel: shareScreenVM)
        vc.view.isUserInteractionEnabled = false
        let currentUser = meeting.account
        cell.setShareContentVC(vc)
        shareScreenVM.shareScreenGridInfo
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak cell] (v: InMeetShareScreenVM.ShareScreenInfo?) in
                    guard let info = v else {
                        cell?.displayText = ""
                        return
                    }
                    if info.user == currentUser {
                        cell?.displayText = I18n.View_M_NowSharingToast
                    } else {
                        cell?.displayText = info.isSharingPause ? I18n.View_G_NameSharingPaused(info.name) : I18n.View_VM_SharingNameBraces(info.name)
                    }
                })
                .disposed(by: cell.disposeBag)
    }

    var followViewModel: InMeetFollowViewModel? {
        guard let manager = resolver.resolve(InMeetFollowManager.self) else {
            return nil
        }
        let vm = InMeetFollowViewModel(meeting: meeting, context: context, manager: manager, resolver: resolver)
        return vm
    }

    func configureMSCell(_ cell: InMeetGalleryShareContentCell) {
        Logger.scene.info("configure ms cell")
        guard let vm = self.followViewModel else {
            cell.setShareContentVC(nil)
            return
        }
        let thumbVM = InMeetFollowThumbnailVM(meeting: self.meeting, resolver: resolver)
        let vc = InMeetFollowThumbnailVC(viewModel: thumbVM)
        cell.setShareContentVC(vc)

        Observable.combineLatest(vm.shareUserName, vm.magicShareDocumentRelay.asObservable())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] (name: String, v: MagicShareDocument?) in
                guard let cell = cell else {
                    return
                }
                // 捕获 VM 避免 VM 析构
                _ = vm
                if vm.meeting.shareData.isSelfSharingContent {
                    cell.displayText = I18n.View_VM_YouAreSharingFileName(v?.nonEmptyDocTitle ?? "")
                } else {
                    cell.displayText = I18n.View_VM_NameIsSharingFileName(name, v?.nonEmptyDocTitle ?? "")
                }
            })
            .disposed(by: cell.disposeBag)
    }

    var whiteBoardViewModel: InMeetWhiteboardViewModel? {
        return InMeetWhiteboardViewModel(resolver: resolver)
    }

    func configureWhiteBoardCell(_ cell: InMeetGalleryShareContentCell) {
        Logger.scene.info("configure whiteboard cell")
        let vm = InMeetWhiteboardViewModel(resolver: resolver)
        let wbVC = InMeetWhiteboardViewController(viewModel: vm)
        wbVC.whiteboardVC.setLayerMiniScale()
        wbVC.view.isUserInteractionEnabled = false
        wbVC.isContentOnly = true
        wbVC.viewModel.userNameObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak cell] s in
                    let displayName = I18n.View_G_NameSharingBoard_Status(s)
                    cell?.displayText = displayName
                })
                .disposed(by: cell.disposeBag)
        cell.setShareContentVC(wbVC)
    }
}

// - MARK: 负责控制共享页面跳转
extension InMeetShareComponent: InMeetShareDataListener, InMeetWebSpaceDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        Util.runInMainThread {
            self.context.whiteboardID = newScene.whiteboardData?.whiteboardID
            self.context.magicShareUrl = newScene.magicShareDocument?.rawUrl
            self.context.screenShareID = newScene.shareScreenData?.shareScreenID
        }
        ProximityMonitor.isSharingScreen = meeting.shareData.isMySharingScreen
        if meeting.shareData.isLocalProjection || (!newScene.isNone && newScene.shareSceneType != oldScene.shareSceneType) {
            Logger.shareContent.info("update share component to newScene: \(newScene.shareSceneType), newContent: \(newScene.contentMode) from oldScene: \(oldScene.shareSceneType), oldContent: \(oldScene.contentMode)")
            beginShareContent(newScene.contentMode)
        } else if newScene.isNone, !oldScene.isNone {
            Logger.shareContent.info("end share component scene: \(oldScene.shareSceneType), content: \(oldScene.contentMode)")
            endShareContent(oldScene.contentMode)
        }
    }

    func didChangeWebSpace(_ isShow: Bool) {
        if isShow {
            beginShareContent(.webSpace)
            // 网页当前不支持宫格视图，默认切换至缩略视图
            if context.sceneManager?.sceneMode == .gallery {
                context.sceneManager?.switchSceneMode(.thumbnailRow)
            }
        } else {
            // 退出本地网页浏览时需要恢复当前共享状态
            recoverShareContentModeIfNeeded()
            endShareContent(.webSpace)
        }
    }

    /// 恢复当前共享 UI 状态
    /// 根据业务调整判断优先级
    func recoverShareContentModeIfNeeded() {
        let shareContentScene = meeting.shareData.shareContentScene
        if shareContentScene.isNone && !shareContentScene.isLocalProjection {
            [.shareScreen, .follow, .whiteboard, .selfShareScreen].forEach { [weak self] in
                self?.endShareContent($0)
            }
        } else {
            beginShareContent(shareContentScene.contentMode)
        }
    }

    private func beginShareContent(_ content: InMeetSceneManager.ContentMode) {
        guard let sceneManager = context.sceneManager else {
            Logger.scene.warn("sceneManager NOT found when share \(content) BEGIN")
            return
        }
        sceneManager.beginShareContent(content)
    }

    private func endShareContent(_ content: InMeetSceneManager.ContentMode) {
        guard let sceneManager = context.sceneManager else {
            Logger.scene.warn("sceneManager NOT found when share \(content) END")
            return
        }
        sceneManager.endShareContent(content)
    }
}

// - MARK: 外部Layout约束

extension FollowContainerViewController: ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer) {
        guard let shareComponent = container.shareComponent else {
            return
        }
        self.contentLayoutGuide.snp.remakeConstraints {
            $0.edges.equalTo(shareComponent.shareExternalGuideToken.layoutGuide)
        }
        /*
         *self.topBarLayoutGuide.snp.remakeConstraints {
         *    $0.edges.equalTo(container.topBarGuide)
         *}
         */
        self.bottomBarLayoutGuide.snp.remakeConstraints {
            $0.edges.equalTo(container.bottomBarGuide)
        }
    }
}

extension InMeetShareScreenVC: ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer) {
        guard let shareComponent = container.shareComponent else {
            return
        }
        self.parentContainerGuide.snp.makeConstraints { make in
            make.edges.equalTo(container.view)
        }
        self.contentLayoutGuide.snp.remakeConstraints { (maker) in
            maker.edges.equalTo(shareComponent.shareExternalGuideToken.layoutGuide)
        }
        container.addMeetLayoutStyleListener(self)
    }
}

extension InMeetWhiteboardViewController: ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer) {
        guard let shareComponent = container.shareComponent else {
            return
        }
        self.bottomBarLayoutGuide.snp.remakeConstraints { (maker) in
            maker.edges.equalTo(container.bottomBarGuide)
        }
        self.parentContainerGuide.snp.remakeConstraints { maker in
            maker.edges.equalTo(container.view)
        }
        self.contentLayoutGuide.snp.remakeConstraints { maker in
            maker.edges.equalTo(shareComponent.shareExternalGuideToken.layoutGuide)
        }
        container.addMeetLayoutStyleListener(self)
    }
}

extension InMeetSelfShareScreenViewController: ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer) {
        container.addMeetLayoutStyleListener(self)
    }
}

extension InMeetWebSpaceContainerViewController: ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer) {
        guard let shareComponent = container.shareComponent else {
            return
        }
        self.contentLayoutGuide.snp.remakeConstraints {
            $0.edges.equalTo(shareComponent.shareExternalGuideToken.layoutGuide)
        }
        self.bottomBarLayoutGuide.snp.remakeConstraints {
            $0.edges.equalTo(container.bottomBarGuide)
        }
        container.addMeetLayoutStyleListener(self)
    }
}

extension InMeetViewContainer {
    var shareComponent: InMeetShareComponent? {
        component(by: .share) as? InMeetShareComponent
    }
}
