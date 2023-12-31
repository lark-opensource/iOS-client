//
//  FolderBrowserViewModel.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/21.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LKCommonsLogging

final class FolderBrowserViewModel: UserResolverWrapper {
    private static let logger = Logger.log(FolderBrowserViewModel.self, category: "LarkFile.FolderBrowserViewModel")

    // parent folder info
    struct FolderInfo {
        let key: String
        // 消息链接化场景需要使用previewID鉴权
        let authToken: String?
        // 嵌套文件/文件夹需要使用根文件的key做鉴权
        let authFileKey: String
        let name: String
        let size: Int64
        let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    }
    let folderInfo: FolderInfo
    var allCount: Int64?
    var pageCount: Int = 20 /// 默认一页拉取多少个
    private var offset: Int = 0 /// 当前已拉取数量

    var hasMoreDriver: Driver<Bool> {
        return hasMoreSubject.asDriver(onErrorJustReturn: true)
    }
    private let hasMoreSubject = PublishSubject<Bool>()

    var errorDriver: Driver<Error> {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<Error>.empty() })
    }
    private let errorPublish = PublishSubject<Error>()

    var dataSourceDriver: Driver<[RustPB.Media_V1_BrowseFolderResponse.SerResp.BrowseInfo]> {
        return dataSourceBehaviorRelay.asDriver()
    }
    private let dataSourceBehaviorRelay = BehaviorRelay<[RustPB.Media_V1_BrowseFolderResponse.SerResp.BrowseInfo]>(value: [])

    @ScopedInjectedLazy private var fileAPI: SecurityFileAPI?
    private let disposeBag = DisposeBag()

    let gridSubject: BehaviorSubject<Bool>
    //在解压缩情境下，会通过push获得首屏数据，此时不需要再次调用loadData()
    private let firstScreenData: Media_V1_BrowseFolderResponse?
    let userResolver: UserResolver
    init(key: String,
         authToken: String?,
         authFileKey: String,
         name: String,
         size: Int64,
         downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
         gridSubject: BehaviorSubject<Bool>,
         firstScreenData: Media_V1_BrowseFolderResponse? = nil,
         resolver: UserResolver) {
        self.gridSubject = gridSubject
        self.folderInfo = FolderInfo(key: key,
                                     authToken: authToken,
                                     authFileKey: authFileKey,
                                     name: name,
                                     size: size,
                                     downloadFileScene: downloadFileScene)
        self.firstScreenData = firstScreenData
        self.userResolver = resolver
    }

    func loadFirstScreenData() {
        if let response = firstScreenData {
            handleResponse(response)
        } else {
            loadData()
        }
    }
    func loadData() {
        self.fileAPI?.browseFolderRequest(
            key: self.folderInfo.key,
            authToken: self.folderInfo.authToken,
            authFileKey: self.folderInfo.authFileKey,
            start: Int64(offset),
            step: Int64(pageCount),
            downloadFileScene: folderInfo.downloadFileScene
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                self.handleResponse(response)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                Self.logger.error("browse folder fail", error: error)
                self.errorPublish.onNext(error)
            }).disposed(by: self.disposeBag)
    }
    private func handleResponse(_ response: Media_V1_BrowseFolderResponse) {
        self.allCount = response.serResp.allCount
        self.hasMoreSubject.onNext(response.serResp.hasMore_p)
        var currentDataSource = self.dataSourceBehaviorRelay.value
        self.offset += response.serResp.infos.count
        currentDataSource += response.serResp.infos
        self.dataSourceBehaviorRelay.accept(currentDataSource)
    }
}
