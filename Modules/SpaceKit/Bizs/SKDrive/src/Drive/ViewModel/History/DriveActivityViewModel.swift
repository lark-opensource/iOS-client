//
//  DriveActivityViewModel.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/12.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignToast
import RxSwift
import RxCocoa
import SpaceInterface
import SKInfra

/// The size of page
private let pageSize = 20

class DriveActivityViewModel: NSObject {

    enum ViewModelAction {
        case reloadData
        case stopLoading
        case noMoreData
        case resetNoMoreData
        case removeFooter
    }
    var bindAction: ((ViewModelAction) -> Void)?

    /// Dictionary of UserInfo
    static var userInfoDic: [String: [String: Any]] = [:]

    /// Records of history
    private(set) var historyRecords: [DriveHistoryRecordModel] = []
    /// The request of fetch records
    private var fetchFileHistoryRequest: DocsRequest<JSON>?

    /// The meta data of file
    let fileMeta: DriveFileMeta
    ///  The info of docments
    let docsInfo: DocsInfo
    /// Is current user is guest
    let isGuest: Bool

    /// Exist or not more data
    private var hasMore: Bool = false

    /// Is loading flag
    private(set) var isLoadingData: Bool = false

    // 弹 toast 用
    weak var hostController: UIViewController?

    init(fileMeta: DriveFileMeta, docsInfo: DocsInfo, isGuest: Bool) {
        self.fileMeta = fileMeta
        self.docsInfo = docsInfo
        self.isGuest = isGuest
        super.init()
    }
}

// MARK: - Fetch
extension DriveActivityViewModel {

    var baseParams: [String: Any] {
        return ["file_token": fileMeta.fileToken,
                "page_size": pageSize]
    }

    func fetchHistoryRecords(loadMore: Bool = false, onlyTag: Bool = false, completion: @escaping (DriveResult<Void>) -> Void) {
        var params = baseParams
        if loadMore && hasMore, let lastEditTime = historyRecords.last?.editTime {
            params["last_edit_time"] = lastEditTime
        }
        if onlyTag {
            params["only_tag"] = onlyTag
        }
        fetchFileHistoryRequest?.cancel()
        fetchFileHistoryRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.fileHistoryList, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        fetchFileHistoryRequest?.start(result: { [weak self] (result, error) in
            guard let `self` = self else { return }
            if let error = error {
                completion(DriveResult.failure(error))
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    completion(DriveResult.failure(DriveError.fetchHistoryError))
                    return
            }
            if code != 0 { // paraser error code
                completion(DriveResult.failure(DriveError.serverError(code: code)))
                return
            }
            guard let dataDic = json["data"].dictionaryObject else {
                completion(DriveResult.failure(DriveError.fetchHistoryError))
                return
            }
            self.handleHistoryData(dataDic: dataDic, loadMore: loadMore)
            completion(DriveResult.success(()))
        })
    }
}

// MARK: - Data handle
private extension DriveActivityViewModel {

    func handleError(_ error: Error) {
        if let error = error as? DriveError {
            DocsLogger.error(error.localizedDescription)
        } else {
            let error = error as NSError
            DocsLogger.error("\(String(describing: error))")
        }
        if let window = hostController?.view.window {
            UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_LoadingFail,
                                   on: window)
        }
    }

    func handleHistoryData(dataDic: [String: Any], loadMore: Bool) {
        self.hasMore = (dataDic["has_more"] as? Bool) ?? false
        if let userDic = dataDic["users"] as? [String: [String: Any]] {
            DriveActivityViewModel.userInfoDic.merge(other: userDic)
        } else {
            DocsLogger.error("server data did not return users")
        }
        if let list = dataDic["list"] as? [[String: Any]] {
            var records = [DriveHistoryRecordModel]()
            for recordDic in list {
                let record = DriveHistoryRecordModel(dataDic: recordDic)
                records.append(record)
            }

            if loadMore {
                self.historyRecords.append(contentsOf: records)
            } else {
                self.historyRecords = records
            }
        } else {
            DocsLogger.error("server data did not return list of history record ")
        }
    }
}

// MARK: - Load data
extension DriveActivityViewModel {
    func loadData(loadMore: Bool = false) {
        if !DocsNetStateMonitor.shared.isReachable {
            endLoadingData()
            if let window = hostController?.view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_NetInterrupt,
                                       on: window)
            }
            return
        }
        isLoadingData = true
        fetchHistoryRecords(loadMore: loadMore) { [weak self] (result) in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.bindAction?(.reloadData)
            case .failure(let error):
                self.handleError(error)
            }
            self.endLoadingData()
            self.isLoadingData = false
        }
    }

    private func endLoadingData() {
        bindAction?(.stopLoading)
        if historyRecords.count > 0 {
            bindAction?(hasMore ? .resetNoMoreData : .noMoreData)
        } else {
            bindAction?(.removeFooter)
        }
    }

    func generatePreviewViewModel(record: DriveHistoryRecordModel) -> DriveSDKAttachmentFile {
        // space云盘文件更多菜单不需要外部配置
        let moreVisable: Observable<Bool> = .never()
        let actions: [DriveSDKMoreAction] = []
        let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .never())
        let action = DKAttachDefaultActionDependencyImpl()
        let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
        let file = DriveSDKAttachmentFile(fileToken: fileMeta.fileToken,
                                          mountNodePoint: fileMeta.mountNodeToken,
                                          mountPoint: DriveConstants.driveMountPoint,
                                          fileType: record.fileExtension ?? "",
                                          name: record.name ?? "",
                                          version: record.version,
                                          authExtra: nil,
                                          dependency: dependency)
        return file
    }
}
