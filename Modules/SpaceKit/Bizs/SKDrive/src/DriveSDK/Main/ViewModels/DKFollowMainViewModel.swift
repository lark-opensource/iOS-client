//
//  DKFollowMainViewModel.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2021/8/21.
//  

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SpaceInterface

class DKFollowMainViewModel: DKMainViewModel {
    var followTitle: String = ""
    var followMeetingID: String?
    var isCCMPermission: Bool
    var fileBlockMountToken: String?

    weak private(set) var followController: FollowableViewController?
    weak private(set) var followAPIDelegate: SpaceFollowAPIDelegate?
    weak private(set) var followContentProvider: DriveFollowContentProvider?

    private let commentStateSubject = PublishSubject<DriveCommentManager.State>()
    private let followAPIDidSetup = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()

    init(files: [DKFileCellViewModelType], initialIndex: Int, supportLandscape: Bool, isCCMPermission: Bool) {
        self.isCCMPermission = isCCMPermission
        super.init(files: files, initialIndex: initialIndex, supportLandscape: supportLandscape)
        subscribeActions()
    }

    deinit {
        DocsLogger.driveInfo("drive.main.follow --- DKFollowMainViewModel deinit")
        // 非跟随者退出附件时通知前端，避免跟随者被动退出附件也发送 onExitAttachFile
        guard followAPIDelegate?.followRole != .follower else { return }

        // 当前回收的附件与当前 Follow 打开的是同个附件，才发送附件退出信号
        // 同层渲染下会有个多个 FileBlock 页面，避免 iPad 横竖屏切换导致其它 FileBlock 回收，误发送关闭附件信号
        // currentFollowToken 为 nil 说明没有打开附件，也发送附件退出信号
        let currentFollowToken = followAPIDelegate?.currentFollowAttachMountToken
        guard fileBlockMountToken == currentFollowToken || currentFollowToken == nil else { return }

        DocsLogger.driveInfo("drive.main.follow --- exiting file in following, isCCMPermission : \(isCCMPermission)")
        if isCCMPermission {
            followAPIDelegate?.follow(nil, onOperate: .onExitAttachFile(isNewAttach: false))
        } else {
            followAPIDelegate?.follow(nil, onOperate: .onExitAttachFile(isNewAttach: true))
        }
    }

    private func subscribeActions() {
        hostModule?.subModuleActionsCenter.subscribe(onNext: { [weak self] event in
            switch event {
            case let .didSetupCommentManager(manager):
                self?.bindCommentEvent(with: manager)
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
}

// MARK: - Comment Follow State
extension DKFollowMainViewModel {

    func bindCommentEvent(with commentManager: DriveCommentManager) {
        interceptCommentLink(commentManager: commentManager)
        register(followContent: commentManager)
        commentManager.commentFollowStateSubject
            .bind(to: commentStateSubject)
            .disposed(by: disposeBag)
    }

    private func interceptCommentLink(commentManager: DriveCommentManager) {
        commentManager.commentAdapter.commentLinkInterceptor = { [weak self] url in
            guard let self = self else { return false }
            guard let followDelegate = self.followAPIDelegate else {
                DocsLogger.driveInfo("drive.main.follow --- failed to redirect comment link in follow mode, delegate is nil")
                return false
            }
            followDelegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: url.absoluteString)))
            return true
        }
    }
}

// MARK: - DriveFollowContentManager
extension DKFollowMainViewModel: DriveFollowContentManager {
    var followStatisticParameters: [String: String]? {
        var params = ["app_form": "vc"]
        if let meetingID = followMeetingID {
            params["meeting_id"] = meetingID
        }
        return params
    }

    func setup(followController: FollowableViewController, followAPIDelegate: SpaceFollowAPIDelegate) {
        DocsLogger.driveInfo("drive.main.follow --- setting up followAPIDelegate")
        self.followController = followController
        self.followAPIDelegate = followAPIDelegate
        followMeetingID = followAPIDelegate.meetingID
        if let fileBlockVC = followController as? DriveFileBlockVCProtocol {
            self.fileBlockMountToken = fileBlockVC.fileBlockMountToken
        }
        var statisticParameters = additionalStatisticParameters
        statisticParameters.merge(other: followStatisticParameters)
        additionalStatisticParameters = statisticParameters
        // 重新注册 FollowableContent
        self.followContentProvider?.registerFollowableContent()
        followAPIDidSetup.accept(true)
    }

    var commentFollowStateUpdated: Driver<DriveCommentManager.State> {
        if isSpaceFile {
            return commentStateSubject.asDriver(onErrorJustReturn: .default)
        } else {
            return .never()
        }
    }

    func refreshInFollowContext() {
        // VC Follow 场景下，VC 可能会刷新当前页
        // 非 Space 云空间文件刷新没有意义，应该退出附件，并刷新docs
        guard isSpaceFile else { return }
        followContentProvider?.unregisterFollowableContent()
        self.hostModule?.subModuleActionsCenter.accept(.refreshVersion(version: nil))
    }

    func setupFollowConfig(for contentProvider: DriveFollowContentProvider) {
        // contentProvider 的 setup 需在 followAPI 配置后
        followAPIDidSetup.distinctUntilChanged().subscribe(onNext: { [weak self] isSetup in
            guard isSetup, let self = self else { return }
            DocsLogger.driveInfo("drive.main.follow --- setting up follow config for contentProvider")
            self.followContentProvider = contentProvider
            contentProvider.setup(followDelegate: self, mountToken: self.fileBlockMountToken)
        }).disposed(by: disposeBag)
    }

    var shouldHideBackButton: Bool {
        return isSpaceFile
    }

    var shouldSkipCellularCheck: Bool {
        return true
    }

    var shouldEnterFullScreenMode: Bool {
        // MagicShare 原生内容时才自动进入沉浸态
        return followAPIDelegate?.isHostNativeContent ?? false
    }
}

// MARK: - DriveFollowAPIDelegate
extension DKFollowMainViewModel {

    var followRole: FollowRole {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when get followRole")
            return .none
        }
        return followDelegate.followRole
    }

    var isHostNativeContent: Bool {
        return followAPIDelegate?.isHostNativeContent ?? false
    }

    func register(followContent: FollowableContent) {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when registing \(followContent.moduleName) module")
            return
        }
        DocsLogger.driveInfo("drive.main.follow --- registing \(followContent.moduleName) module as followable content")
        followDelegate.follow(followController, register: followContent)
    }

    func unregister(followContent: FollowableContent) {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when unregisting \(followContent.moduleName) module")
            return
        }
        DocsLogger.driveInfo("drive.main.follow --- unregisting \(followContent.moduleName) module as followable content")
        followDelegate.follow(followController, unRegister: followContent)
    }

    func handle(operation: SpaceFollowOperation) {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when processing operation")
            return
        }
        DocsLogger.driveInfo("drive.main.follow --- processing operation", extraInfo: ["operation": operation])
        followDelegate.follow(followController, onOperate: operation)
    }

    func followDidReady() {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when follow content provider is ready")
            return
        }
        if followDelegate.isHostNativeContent {
            followDelegate.followDidReady(followController)
            DocsLogger.driveInfo("drive.main.follow --- processing follow content provider did ready event")
        } else {
            // 非同层附件 didReady，开始注册 BoxPreview
            guard followController?.isSameLayerFollow == false else { return }
            followDelegate.followAttachDidReady()
            DocsLogger.driveInfo("drive.main.follow --- attach content did ready event")
        }

    }

    func followDidRenderFinish() {
        guard let followDelegate = followAPIDelegate else {
            DocsLogger.error("drive.main.follow --- followAPIDelegate is nil when follow content provider render finish")
            return
        }
        guard followDelegate.isHostNativeContent else { return }
        DocsLogger.driveInfo("drive.main.follow --- processing follow content provider render finish")
        followDelegate.followDidRenderFinish(followController)
    }
}
