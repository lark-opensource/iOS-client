//
//  WikiTreeDraggableViewModel.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/29.
//

import Foundation
import RxSwift
import RxCocoa
import SKSpace
import SKCommon
import SKFoundation
import SKWorkspace
import SpaceInterface
import LarkContainer

class WikiTreeDraggableViewModel {

    let bag = DisposeBag()
    // Output
    // 点击目录树节点, 同时提供同步数据供其他列表使用
    var clickTreeNodeContent: Signal<(WikiTreeNodeMeta, WikiTreeContext)> {
        treeViewModel.onClickNodeSignal
    }

    // 点击搜索结果, viewController 通过这个事件实现文档内容跳转、协同给其他目录树
    var clickSearchResult: Signal<WikiNodeMeta> {
        didClickSearchResult.asSignal()
    }

    /// 面板被dismiss
    var dismissVC: Signal<Void> {
        return didDismiss.asSignal()
    }

    var currentNodeDeleted: Signal<Void> {
        treeViewModel.onManualDeleteNodeSignal
    }

    // Input
    let didClickSearchResult = PublishRelay<WikiNodeMeta>()
    let didDismiss = PublishRelay<Void>()

    private let wikiTokenRelay: BehaviorRelay<String>
    var wikiToken: String {
        wikiTokenRelay.value
    }

    // 当前 nodeUID，通过链接打开场景可能为 nil
    private let currentNodeUIDRelay = BehaviorRelay<WikiTreeNodeUID?>(value: nil)
    var currentNodeUID: WikiTreeNodeUID? {
        currentNodeUIDRelay.value
    }

    // Time for transition duration (s)
    let presentAnimationDuration: TimeInterval = 0.25
    let dismissAnimationDuration: TimeInterval = 0.25
    
    // upload
    // upload info
    let uploadState: BehaviorRelay<DriveStatusItem?> = BehaviorRelay<DriveStatusItem?>(value: nil)
    private var uploadHelper: SpaceListDriveUploadHelper
    private var driveListConfig: DriveListConfig { uploadHelper.driveListConfig }
    let mountToken: String = "all_files_token"
    private var currentStatusItem: DriveStatusItem?
    
    var supportOrientation: UIInterfaceOrientationMask?

    let treeViewModel: WikiMainTreeViewModel
    let userResolver: UserResolver
    
    init(userResolver: UserResolver,
         wikiToken: String,
         spaceId: String,
         treeContext: WikiTreeContext?,
         synergyUUID: String) {
        self.userResolver = userResolver
        wikiTokenRelay = BehaviorRelay(value: wikiToken)
        treeViewModel = WikiMainTreeViewModel(userResolver: userResolver,
                                              spaceID: spaceId,
                                              wikiToken: wikiToken,
                                              scene: .documentDraggablePage,
                                              treeContext: treeContext,
                                              synergyUUID: synergyUUID)
        uploadHelper = SpaceListDriveUploadHelper(mountToken: mountToken,
                                                  mountPoint: DriveConstants.workspaceMountPoint,
                                                  scene: .workspace,
                                                  identifier: "wiki-treeview")
        if let nodeUID = treeContext?.nodeUID {
            currentNodeUIDRelay.accept(nodeUID)
        }
        setupUploadHelper()

        didClickSearchResult.map(\.wikiToken)
            .bind(to: wikiTokenRelay)
            .disposed(by: bag)

        treeViewModel.onClickNodeSignal
            .map { $0.0.wikiToken }
            .emit(to: wikiTokenRelay)
            .disposed(by: bag)

        treeViewModel.onClickNodeSignal
            .map { $0.1.nodeUID }
            .emit(to: currentNodeUIDRelay)
            .disposed(by: bag)
    }

    func updateData(_ wikiToken: String) {
        treeViewModel.focusByWikiTokenInput.accept(wikiToken)
    }
    
    func setupUploadHelper() {
        uploadHelper.setup()
        uploadHelper.uploadStateChanged.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.updateUploadState(driveConfig: self.driveListConfig)
        }).disposed(by: bag)
        uploadHelper.fileDidUploaded.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.updateUploadState(driveConfig: self.driveListConfig)
        }).disposed(by: bag)
        uploadHelper.fileUploadFinishSuccess.subscribe(onNext: { [weak self] success in
            guard let self = self else { return }
            let status = success ? "success" : "failed"
            WikiStatistic.spaceUploadProgressClick(containerID: DocsTracker.encrypt(id: self.treeViewModel.spaceID),
                                                   uploadStatus: status)
        }).disposed(by: bag)
    }
    private func updateUploadState(driveConfig: DriveListConfig) {
        if driveConfig.isNeedUploading {
            DocsLogger.debug("[Drive Upload] uploadCount: \(driveConfig.remainder) progress: \(driveConfig.progress)")
            let status: DriveStatusItem.Status = driveConfig.failed ? .failed : .uploading
            let count = driveConfig.failed ? driveConfig.errorCount : driveConfig.remainder
            let driveStatusItem = DriveStatusItem(count: count, total: driveConfig.totalCount,
                                                  progress: driveConfig.progress, status: status)
            if currentStatusItem == nil { // 出现进度条上报
                WikiStatistic.spaceUploadProgressView(containerID: DocsTracker.encrypt(id: treeViewModel.spaceID))
            }
            currentStatusItem = driveStatusItem
            uploadState.accept(driveStatusItem)
        } else {
            currentStatusItem = nil
            uploadState.accept(nil)
        }
    }
}
