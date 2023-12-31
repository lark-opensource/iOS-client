//
//  DriveFileInfoProvider.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/21.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation

// 接口文档 https://bytedance.feishu.cn/wiki/wikcnj55mEH7DzMViRaNgQc1OWg#IjVnJQ
class DriveFileInfoProvider: DKFileInfoProvider {
    typealias FileInfo = DriveFileInfo
    private let netManager: DrivePreviewNetManagerProtocol
    private let showInRecent: Bool
    private let optionParams: [String]
    private let pollingStrategy: DrivePollingStrategy
    
    init(netManager: DrivePreviewNetManagerProtocol,
         showInfRecent: Bool,
         optionParams: [String] = [],
         pollingStrategy: DrivePollingStrategy = DriveInfoPollingStrategy()) {
        self.netManager = netManager
        self.showInRecent = showInfRecent
        self.optionParams = optionParams
        self.pollingStrategy = pollingStrategy
    }

    func request(version: String?) -> Observable<FileInfoResult<DriveFileInfo>> {
        Observable<FileInfoResult<DriveFileInfo>>.create { (observer) -> Disposable in
            let context = FetchFileInfoContext(showInRecent: self.showInRecent,
                                               version: version,
                                               optionParams: self.optionParams,
                                               pollingStrategy: self.pollingStrategy)
            self.netManager.fetchFileInfo(context: context) {
                observer.onNext(FileInfoResult.storing)
            } completion: { (result) in
                switch result {
                case let .success(info):
                    observer.onNext(.succ(info: info))
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                self.netManager.cancelFileInfo()
            }

        }
    }
}
