//
//  ReadingDataRequest.swift
//  SpaceKit
//
//  Created by Webster on 2019/3/1.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKUIKit
import SKResource
import SKInfra

/// 阅读数据请求器
public protocol ReadingDataFrontDataSource: AnyObject {
    func requestData(request: ReadingDataRequest, docs: DocsInfo, finish: @escaping (ReadingInfo) -> Void)
    // info 数据用于新版详情
    func requestRefresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, error: Bool)
}

public struct ReadingItemInfo {
    public var type: ReadingDataType
    public var detail: String
    public init(_ type: ReadingDataType, _ detail: String) {
        self.type = type
        self.detail = detail
        formatDetail()
    }

    mutating func formatDetail() {
        guard let number = Int(detail), number >= 1000 else { return }
        let split = ","
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###,###"
        formatter.negativeFormat = "-###,###"
        formatter.groupingSeparator = split
        if let result = formatter.string(from: NSNumber(value: number)) {
            self.detail = result
        }
    }
}

public enum ReadingDataError: Error, LocalizedError {
    case reuestError
    public var errorDescription: String? {
        switch self {
        case .reuestError:
            return BundleI18n.SKResource.Doc_Facade_OperateFailed
        }
    }
}

public typealias ReadingInfo = [ReadingItemInfo]

public struct FilePanelInfo {
    var title: String = ""
    var text: String = ""
    var imgURL: String = ""
    var image: UIImage?
    var type: FileInfoType = .ownerInfo
    var showImage: Bool = true
    //3.6挪到这边来，3.5的高度就是这样，外边会真正传宽度，所以这里给了默认值
    var size: CGSize = CGSize(width: SKDisplay.activeWindowBounds.width, height: 75)

    public init() {}
}

public struct ReadingPanelInfo {
    public var info: ReadingInfo
    public var title: String

    public init(info: ReadingInfo = ReadingInfo(), title: String = "") {
        self.info = info
        self.title = title
    }
}

public final class ReadingDataRequest {
    public static let loadingToken: String = "com.bytedance.ee.readingdata.loading"
    public weak var dataSource: ReadingDataFrontDataSource?
    private let info: DocsInfo
    private var avatarUrl: String?
    private var docsRequest: DocsRequest<JSON>?
    private var sheetRequest: DocsRequest<JSON>?
    private var driveRequest: DocsRequest<JSON>?
    private var firstPanelInfo: ReadingPanelInfo = ReadingPanelInfo()
    private var secondPanelInfo: ReadingPanelInfo = ReadingPanelInfo()
    private var currentPanelInfos: [ReadingPanelInfo] = [ReadingPanelInfo]()

    var haveLikeCount: Bool {
        switch info.inherentType {
        case .doc, .docX, .file:
            return true
        default:
            return false
        }
    }

    public init(_ docsInfo: DocsInfo) {
        self.info = docsInfo
    }

    public func request() {
        switch info.inherentType {
        case .doc, .docX, .mindnote:
            requestDocs()
        case .sheet, .bitable:
            requestSheet()
        case .file:
            requestDrive()
        case .slides:
            requestSlides()
        default:
            ()
        }
    }

    public func cancel() {
        dataSource = nil
        docsRequest?.cancel()
    }

    public static func fakeData(info: DocsInfo) -> [ReadingPanelInfo] {
        var defaultData = [ReadingPanelInfo]()
        switch info.inherentType {
        case .doc, .docX:
            var firstPanel = ReadingPanelInfo()
            firstPanel.title = BundleI18n.SKResource.Doc_Doc_WordStatistics
            firstPanel.info = [ReadingItemInfo(.wordNumber, ReadingDataRequest.loadingToken),
                               ReadingItemInfo(.charNumber, ReadingDataRequest.loadingToken)]
            var secondPanel = ReadingPanelInfo()
            secondPanel.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
            secondPanel.info = [ReadingItemInfo(.readerNumber, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.readingTimer, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.thumbUpNumber, ReadingDataRequest.loadingToken)]

            defaultData.append(firstPanel)
            defaultData.append(secondPanel)
        case .mindnote:
            var firstPanel = ReadingPanelInfo()
            firstPanel.title = BundleI18n.SKResource.Doc_Doc_WordStatistics
            firstPanel.info = [ReadingItemInfo(.wordNumber, ReadingDataRequest.loadingToken)]
            var secondPanel = ReadingPanelInfo()
            secondPanel.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
            secondPanel.info = [ReadingItemInfo(.readerNumber, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.readingTimer, ReadingDataRequest.loadingToken)]
            defaultData.append(firstPanel)
            defaultData.append(secondPanel)
        case .sheet:
            /*暂时屏蔽字数、字符数
            var firstPanel = ReadingPanelInfo()
            firstPanel.title = BundleI18n.SKResource.Doc_Doc_WordStatistics
            firstPanel.info = [ReadingItemInfo(.wordNumber, ReadingDataRequest.loadingToken)]
            defaultData.append(firstPanel)
            */
            var secondPanel = ReadingPanelInfo()
            secondPanel.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
            secondPanel.info = [ReadingItemInfo(.readerNumber, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.readingTimer, ReadingDataRequest.loadingToken)]
            defaultData.append(secondPanel)
        case .bitable:
            var secondPanel = ReadingPanelInfo()
            secondPanel.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
            secondPanel.info = [ReadingItemInfo(.readerNumber, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.readingTimer, ReadingDataRequest.loadingToken)]
            defaultData.append(secondPanel)
        case .file:
            var secondPanel = ReadingPanelInfo()
            secondPanel.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
            secondPanel.info = [ReadingItemInfo(.readerNumber, ReadingDataRequest.loadingToken),
                                ReadingItemInfo(.readingTimer, ReadingDataRequest.loadingToken)]
            defaultData.append(secondPanel)
        default:
            ()
        }
        return defaultData
    }

    private func requestDocs() {
        let loadingToken = ReadingDataRequest.loadingToken
        firstPanelInfo = ReadingPanelInfo()
        firstPanelInfo.title = BundleI18n.SKResource.Doc_Doc_WordStatistics
        firstPanelInfo.info = [ReadingItemInfo(.wordNumber, loadingToken)]

        secondPanelInfo = ReadingPanelInfo()
        secondPanelInfo.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
        secondPanelInfo.info = [ReadingItemInfo(.readerNumber, loadingToken),
                                ReadingItemInfo(.readingTimer, loadingToken)]

        let supportNewDetailInfoTypes = DocDetailInfoViewController.supportDocTypes
        if supportNewDetailInfoTypes.contains(info.inherentType) {
            firstPanelInfo.info.append(ReadingItemInfo(.charNumber, loadingToken))
            secondPanelInfo.info.append(ReadingItemInfo(.thumbUpNumber, loadingToken))
        }

        dataSource?.requestData(request: self, docs: self.info, finish: { [weak self] (readingInfo) in
            self?.firstPanelInfo.info = readingInfo
            guard let firstInfo = self?.firstPanelInfo, let secondInfo = self?.secondPanelInfo else {
                return
            }
            let resultInfos = [firstInfo, secondInfo]
            self?.dataSource?.requestRefresh(info: .words(readingInfo), data: resultInfos, avatarUrl: self?.avatarUrl, error: false)
        })

        docsRequest?.cancel()
        var token = info.objToken
        if let wikiInfo = info.wikiInfo {
            token = wikiInfo.objToken
        }
        DocsLogger.info("request docs detail info...", component: LogComponents.docsDetailInfo)
        let params: [String: Any] = ["token": token,
                                     "obj_type": String(info.inherentType.rawValue)]
        docsRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.readingData, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { [weak self] (readingInfo, error) in
                let code = readingInfo?["code"].int ?? -1000
                guard code == 0, error == nil else {
                    DocsLogger.error("requestDocs error code: \(code)", error: error, component: LogComponents.docsDetailInfo)
                    self?.reportDocRequestFinish(info: .details(nil), error: true)
                    return
                }
                guard let datas = readingInfo?["data"] else {
                    DocsLogger.error("requestDocs data is nil", component: LogComponents.docsDetailInfo)
                    self?.reportDocRequestFinish(info: .details(nil), error: true)
                    return
                }
                self?.secondPanelInfo.info.removeAll()

                if let uv = datas["uv"].int {
                    let info = ReadingItemInfo(.readerNumber, String(uv))
                    self?.secondPanelInfo.info.append(info)
                }

                if let pv = datas["pv"].int {
                    let info = ReadingItemInfo(.readingTimer, String(pv))
                    self?.secondPanelInfo.info.append(info)
                }
                // 可以不依赖外部传入ownerID，避免业务方调用未传
                if let ownerID = datas["owner_user_id"].string {
                    self?.info.ownerID = ownerID
                }
                if let users = datas["entities"]["users"].dictionaryObject,
                   let user = users[self?.info.ownerID ?? ""] as? [String: Any],
                   let avatarUrl = user["avatar_url"] as? String {
                    self?.avatarUrl = avatarUrl
                }
                DocsLogger.info("request docs detail info success", component: LogComponents.docsDetailInfo)
                //目前只有docs有点赞数据
                if let likeCount = datas["like_count"].int, self?.haveLikeCount ?? false {
                    let info = ReadingItemInfo(.thumbUpNumber, String(likeCount))
                    self?.secondPanelInfo.info.append(info)
                }
                let model = DocsReadingInfoModel(params: datas.dictionaryObject ?? [:], ownerId: self?.info.ownerID ?? "")
                self?.reportDocRequestFinish(info: .details(model), error: false)
            })
    }

    private func requestSheet() {
        requestActivitytStatistics()
    }

    private func requestDrive() {
        requestActivitytStatistics()
    }
    
    private func requestSlides() {
        requestActivitytStatistics()
    }

    private func requestActivitytStatistics() {
        let loadingToken = ReadingDataRequest.loadingToken

        secondPanelInfo = ReadingPanelInfo()
        secondPanelInfo.title = BundleI18n.SKResource.Doc_Doc_ActivitytStatistics
        secondPanelInfo.info = [ReadingItemInfo(.readerNumber, loadingToken),
                                ReadingItemInfo(.readingTimer, loadingToken)]

        dataSource?.requestData(request: self, docs: self.info, finish: { [weak self] (readingInfo) in
            self?.firstPanelInfo.info = readingInfo
            guard let firstInfo = self?.firstPanelInfo, let secondInfo = self?.secondPanelInfo else {
                return
            }
            let resultInfos = [firstInfo, secondInfo]
            self?.dataSource?.requestRefresh(info: .words(readingInfo), data: resultInfos, avatarUrl: self?.avatarUrl, error: false)
        })
        
        docsRequest?.cancel()
        var token = info.objToken
        if let wikiInfo = info.wikiInfo {
            token = wikiInfo.objToken
        }
        let params: [String: Any] = ["token": token,
                                     "obj_type": String(info.inherentType.rawValue)]
        docsRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.readingData, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { [weak self] (readingInfo, error) in
                let code = readingInfo?["code"].int ?? -1000
                guard code == 0, error == nil else {
                    self?.reportSheetRequestFinish(info: nil, error: true)
                    return
                }
                guard let datas = readingInfo?["data"] else {
                    self?.reportSheetRequestFinish(info: nil, error: true)
                    return
                }
                self?.secondPanelInfo.info.removeAll()
                if let uv = datas["uv"].int {
                    let info = ReadingItemInfo(.readerNumber, String(uv))
                    self?.secondPanelInfo.info.append(info)
                }

                if let pv = datas["pv"].int {
                    let info = ReadingItemInfo(.readingTimer, String(pv))
                    self?.secondPanelInfo.info.append(info)
                }
                // 可以不依赖外部传入ownerID，避免业务方调用未传
                if let ownerID = datas["owner_user_id"].string {
                    self?.info.ownerID = ownerID
                }

                if let users = datas["entities"]["users"].dictionaryObject,
                   let user = users[self?.info.ownerID ?? ""] as? [String: Any],
                   let avatarUrl = user["avatar_url"] as? String {
                    self?.avatarUrl = avatarUrl
                }
                let model = DocsReadingInfoModel(params: datas.dictionaryObject ?? [:], ownerId: self?.info.ownerID ?? "")
                self?.reportSheetRequestFinish(info: .details(model), error: false)
            })
    }

    private func reportDocRequestFinish(info: DocsReadingData?, error: Bool) {
        let oldInfo = [firstPanelInfo, secondPanelInfo]
//        guard let url = avatarUrl else { return }
        dataSource?.requestRefresh(info: info, data: oldInfo, avatarUrl: avatarUrl ?? "", error: error)
    }

    private func reportSheetRequestFinish(info: DocsReadingData?, error: Bool) {
        let oldInfo = [secondPanelInfo]
        guard let url = avatarUrl else {
            DocsLogger.error("missing url")
            return
        }
        dataSource?.requestRefresh(info: info, data: oldInfo, avatarUrl: url, error: error)
    }
}
