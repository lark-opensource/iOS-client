//
//  WikiTreeCoverViewModel.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/19.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation
import SKSpace
import SKCommon
import SKWorkspace
import LarkContainer

class WikiTreeCoverViewModel {
    // input
    let tapStar = PublishSubject<Bool>()

    lazy var handleStar: Observable<Event<Bool>> = {
        return tapStar.flatMap({ [weak self] isStar -> Observable<Event<Bool>> in
            guard let self = self else { return Observable<Event<Bool>>.never() }
            WikiStatistic.starWorkSpace(isStar: isStar)
            return WikiNetworkManager.shared.setStarSpaceV2(spaceID: self.space.spaceID, isAdd: isStar).materialize()
        })
    }()

    lazy var spaceInfoUpdate: Observable<WikiSpace> = {
        return self._spaceInfoUpdate.asObservable()
    }()

    let treeViewModel: WikiMainTreeViewModel
    var space: WikiSpace
    let bag = DisposeBag()
    private let _spaceInfoUpdate = PublishSubject<WikiSpace>()

    // upload info
    let uploadState: BehaviorRelay<DriveStatusItem?> = BehaviorRelay<DriveStatusItem?>(value: nil)
    private var uploadHelper: SpaceListDriveUploadHelper
    private var driveListConfig: DriveListConfig { uploadHelper.driveListConfig }
    let mountToken: String = "all_files_token"
    private var currentStatusItem: DriveStatusItem?

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         space: WikiSpace,
         wikiToken: String? = nil) {
        self.userResolver = userResolver
        self.space = space
        treeViewModel = WikiMainTreeViewModel(userResolver: userResolver,
                                              spaceID: space.spaceID,
                                              wikiToken: wikiToken, scene: .spacePage)
        uploadHelper = SpaceListDriveUploadHelper(mountToken: mountToken,
                                                  mountPoint: DriveConstants.workspaceMountPoint,
                                                  scene: .workspace,
                                                  identifier: "wiki-treeview")
        setupUploadHelper()
    }

    convenience init(userResolver: UserResolver, spaceId: String, wikiToken: String? = nil) {
        let mockSpace = WikiSpace(spaceId: spaceId,
                                  spaceName: "",
                                  rootToken: "",
                                  tenantID: nil,
                                  wikiDescription: "",
                                  cover: .init(originPath: "",
                                               thumbnailPath: "",
                                               name: "",
                                               isDarkStyle: false,
                                               rawColor: ""),
                                  lastBrowseTime: nil,
                                  wikiScope: 0,
                                  ownerPermType: 0,
                                  migrateStatus: nil,
                                  openSharing: nil,
                                  spaceType: nil,
                                  createUID: nil,
                                  displayTag: nil)
        self.init(userResolver: userResolver, space: mockSpace, wikiToken: wikiToken)
        updateSpaceInfo(spaceId: spaceId)
    }

    func initailTreeData() {
        treeViewModel.setup()
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
    func updateSpaceInfo(spaceId: String) {
        WikiNetworkManager.shared.getSpace(spaceId: spaceId)
            .subscribe {[weak self] (space) in
                self?.space = space
                self?._spaceInfoUpdate.onNext(space)
            } onError: {(error) in
                DocsLogger.error("get space error \(error)")
            }
            .disposed(by: bag)
    }
    
    private func updateUploadState(driveConfig: DriveListConfig) {
        if driveConfig.isNeedUploading {
            DocsLogger.debug("[Drive Upload] uploadCount: \(driveConfig.remainder) progress: \(driveConfig.progress)")
            let status: DriveStatusItem.Status = driveConfig.failed ? .failed : .uploading
            let count = driveConfig.failed ? driveConfig.errorCount : driveConfig.remainder
            let driveStatusItem = DriveStatusItem(count: count, total: driveConfig.totalCount,
                                                  progress: driveConfig.progress, status: status)
            if currentStatusItem == nil { // 出现进度条上报
                WikiStatistic.spaceUploadProgressView(containerID: DocsTracker.encrypt(id: space.spaceID))
            }
            currentStatusItem = driveStatusItem
            uploadState.accept(driveStatusItem)
        } else {
            currentStatusItem = nil
            uploadState.accept(nil)
        }
    }
}
