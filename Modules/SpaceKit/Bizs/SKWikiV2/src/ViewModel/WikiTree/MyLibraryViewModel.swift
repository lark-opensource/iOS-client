//
//  MyLibraryViewModel.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/1/31.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKSpace
import SKWorkspace
import LarkContainer

enum MyLibraryAction: Equatable {
    case showEmpty(type: EmptyType)
    case getSpaceIdCompelete
    case createLibraryError
    
    enum EmptyType {
        case loading
        case empty
        case error
    }
}

class MyLibraryViewModel {
    var treeViewModel: WikiMainTreeViewModel?
    var spaceId: String?
    // Upload
    let uploadState: BehaviorRelay<DriveStatusItem?> = BehaviorRelay<DriveStatusItem?>(value: nil)
    let mountToken: String = "all_files_token"
    private var uploadHelper: SpaceListDriveUploadHelper
    private var driveListConfig: DriveListConfig { uploadHelper.driveListConfig }
    private var currentStatusItem: DriveStatusItem?
    let bag = DisposeBag()
    
    var actionOutput: Driver<MyLibraryAction> {
        actionInput.asDriver(onErrorJustReturn: .createLibraryError)
    }
    
    var actionInput = PublishSubject<MyLibraryAction>()
    
    public let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        uploadHelper = SpaceListDriveUploadHelper(mountToken: mountToken,
                                                  mountPoint: DriveConstants.wikiMountPoint,
                                                  scene: .wiki,
                                                  identifier: "wiki-treeview")
        setUploadHelper()
    }
    
    func setUploadHelper() {
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
            if let spaceId = self.spaceId {
                WikiStatistic.spaceUploadProgressClick(containerID: DocsTracker.encrypt(id: spaceId),
                                                       uploadStatus: status)
            }
        }).disposed(by: bag)
    }
    
    func initailTreeData() {
        treeViewModel?.setup()
    }
    
    func prepare() {
        // 缓存中如果有文档库的spaceID，则直接使用，不发送网络请求获取
        if let spaceId = MyLibrarySpaceIdCache.get() {
            DocsLogger.info("wiki.my.library --- get library spaceId succees from cache")
            self.spaceId = spaceId
            treeViewModel = WikiMainTreeViewModel(userResolver: userResolver, spaceID: spaceId, wikiToken: nil, scene: .myLibrary)
            actionInput.onNext(.getSpaceIdCompelete)
            return
        }
        
        actionInput.onNext(.showEmpty(type: .loading))
        WikiNetworkManager.shared.getWikiLibrarySpaceId()
            .subscribe(onSuccess: { [weak self] spaceId in
                guard let self else { return }
                DocsLogger.info("wiki.my.library --- get library spaceId succeed from network")
                self.getMyLibrarySpaceIdCompeletion(spaceId: spaceId)
            }, onError: { [weak self] error in
                let code = (error as NSError).code
                if let wikiError = WikiErrorCode(rawValue: code),
                   wikiError == .sourceNotExist {
                    //用户没有文档库，需要客户端调用创建接口新建
                    self?.createMyLibraryIfNeed()
                    DocsLogger.info("wiki.my.library --- get library spaceId error, code is sourceNotExist, should create library!")
                } else {
                    self?.actionInput.onNext(.showEmpty(type: .error))
                    DocsLogger.error("wiki.my.library --- get library spaceId error, error: \(error)")
                }
            })
            .disposed(by: bag)
    }
    
    private func createMyLibraryIfNeed() {
        let uniqID = String(Date().timeIntervalSince1970)
        WikiNetworkManager.shared.createMyLibrary(uniqID: uniqID)
            .subscribe(onSuccess: { [weak self] spaceId in
                guard let self else { return }
                DocsLogger.info("wiki.my.library --- create library success")
                self.getMyLibrarySpaceIdCompeletion(spaceId: spaceId)
            }, onError: { error in
                DocsLogger.error("wiki.my.library --- create library error: \(error)")
                //失败兜底页
                self.actionInput.onNext(.showEmpty(type: .error))
                self.actionInput.onNext(.createLibraryError)
            })
            .disposed(by: bag)
    }
    
    private func getMyLibrarySpaceIdCompeletion(spaceId: String) {
        self.spaceId = spaceId
        self.treeViewModel = WikiMainTreeViewModel(userResolver: userResolver, spaceID: spaceId, wikiToken: nil, scene: .spacePage)
        self.actionInput.onNext(.getSpaceIdCompelete)
        MyLibrarySpaceIdCache.set(spaceId: spaceId)
    }
    
    private func updateUploadState(driveConfig: DriveListConfig) {
        if driveConfig.isNeedUploading {
            DocsLogger.debug("[Drive Upload] uploadCount: \(driveConfig.remainder) progress: \(driveConfig.progress)")
            let status: DriveStatusItem.Status = driveConfig.failed ? .failed : .uploading
            let count = driveConfig.failed ? driveConfig.errorCount : driveConfig.remainder
            let driveStatusItem = DriveStatusItem(count: count, total: driveConfig.totalCount,
                                                  progress: driveConfig.progress, status: status)
            if currentStatusItem == nil, let spaceId { // 出现进度条上报
                WikiStatistic.spaceUploadProgressView(containerID: DocsTracker.encrypt(id: spaceId))
            }
            currentStatusItem = driveStatusItem
            uploadState.accept(driveStatusItem)
        } else {
            currentStatusItem = nil
            uploadState.accept(nil)
        }
    }
}
