//
//  OfficialCoverPhotosDataProvider.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//

import SKFoundation
import SpaceInterface
import SKCommon
import RxSwift
import SwiftyJSON
import ThreadSafeDataStructure
import SKInfra

class OfficialCoverPhotosProvider {
    private struct APIPath {
        static let officialCoverPhotos = "/api/doc.v2/cover/candidates/" //封面背景拉取
    }
}

extension OfficialCoverPhotosProvider: OfficialCoverPhotosNetWorkAPI {
    func fetchOfficialCoverPhotosTokenWith(_ parmas: [String: Any]) -> Observable<OfficialCoverPhotosSeries> {
        let fetchSequence = RxDocsRequest<JSON>()
            .request(APIPath.officialCoverPhotos,
                     params: parmas,
                     method: .GET)
            .flatMap { (result) -> Observable<OfficialCoverPhotosSeries> in
                guard let code = result?["code"].int, code == 0 else {
                    DocsLogger.info("fetch oOfficialCoverPhotos: error code")
                    return .error(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                }
                guard let msg = result?["msg"].string, msg == "Success", let data = result?["data"].dictionary else {
                    DocsLogger.info("fetch OfficialCoverPhotos: msg fail")
                    return .error(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                }
                guard let coverSeries = data["cover_series"]?.array else {
                    DocsLogger.info("fetch OfficialCoverPhotos: info lose")
                    return .error(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                }
                var series: OfficialCoverPhotosSeries = OfficialCoverPhotosSeries()
                // 用于手动设置下载优先级，解决展示图片从下往上加载
                // 设置一个最大值，不需要后面多遍历一次
                var maxPriority: Int32 = 100
                coverSeries.forEach { (modelJson) in
                    guard let dataString = modelJson.rawString(),
                        let data = dataString.data(using: .utf8) else {
                        DocsLogger.info("fetch OfficialCoverPhotos: failed to parse data")
                        return
                    }
                    do {
                        var serie = try JSONDecoder().decode(OfficialCoverPhotosSerie.self, from: data)
                        DocsLogger.debug("fetch OfficialCoverPhotos: success")
                        serie.infos = serie.infos.map({ (info) -> OfficialCoverPhotoInfo in
                            var tempInfo = info
                            tempInfo.priority = maxPriority
                            maxPriority -= 1
                            return tempInfo
                        })
                        series.append(serie)
                    } catch {
                        DocsLogger.info("fetch OfficialCoverPhotos: failed to parse data \(error)")
                    }
                }
                
                // 如果是空，按照错误处理
                if series.count == 0 {
                    DocsLogger.info("fetch OfficialCoverPhotos count is 0")
                    return .error(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                }
                
                return .just(series)
            }
        return fetchSequence
    }
}

class OfficialCoverPhotoDataProvider {
    lazy var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!
    lazy var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    lazy private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!
    private var cacheData: SafeDictionary<String, UIImage> = [:] + .readWriteLock
}

extension OfficialCoverPhotoDataProvider: OfficialCoverPhotoDataAPI {
    func fetchOfficialCoverPhotoDataWith(_ photoInfo: OfficialCoverPhotoInfo,
                                         coverSize: CGSize,
                                         resumeBag: DisposeBag,
                                         completionHandler: @escaping (UIImage?, URLResponse?, Error?) -> Void) {
        let token = photoInfo.token
        let downloadType: DocCommonDownloadType = .cover(width: 360, height: 360, policy: .allowUp)
        if let image = self.cacheData[token] {
            completionHandler(image, nil, nil)
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let data = self.downloadCacheServive.data(key: token, type: downloadType) {
                DocsLogger.info("download drive pic cover, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType)")
                guard let image = UIImage(data: data) else {
                    DocsLogger.info("download drive pic cover, data parse fail")
                    completionHandler(nil, nil, nil)
                    return
                }
                self.cacheData[token] = image
                completionHandler(image, nil, nil)
            } else {
                DocsLogger.info("download drive pic cover, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType)")
                let priority: DocCommonDownloadPriority = .custom(priority: photoInfo.priority ?? 0)
                let context = DocCommonDownloadRequestContext(fileToken: token,
                                                              mountNodePoint: "",
                                                              mountPoint: "doc_image",
                                                              priority: priority,
                                                              downloadType: downloadType,
                                                              localPath: nil,
                                                              isManualOffline: false,
                                                              dataVersion: nil,
                                                              originFileSize: nil,
                                                              fileName: nil)
                self.downloader.download(with: context)
                    .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
                    .subscribe(onNext: {  [weak self] (context) in
                        guard let `self` = self else { return }
                        let status = context.downloadStatus
                        guard status == .failed || status == .success else { return }
                        let errorCode: Int = (status == .success) ? 0 : context.errorCode
                        SKDownloadPicStatistics.downloadPicReport(errorCode, type: Int(downloadType.rawValue), from: .customSchemeDrive)

                        if status == .success, let data = self.downloadCacheServive.data(key: token, type: downloadType) {
                            DocsLogger.info("download drive pic cover, token=\(DocsTracker.encrypt(id: token)), result=success")
                            guard let image = UIImage(data: data) else {
                                DocsLogger.info("download drive pic cover, data parse fail")
                                completionHandler(nil, nil, nil)
                                return
                            }
                            self.cacheData[token] = image
                            completionHandler(image, nil, nil)
                            self.newCacheAPI.mapTokenAndPicKey(token: token, picKey: token, picType: Int(downloadType.rawValue), needSync: false, isDrivePic: true)
                        } else {
                            DocsLogger.error("download drive pic cover, token=\(DocsTracker.encrypt(id: token)), result=\(status)")
                            completionHandler(nil, nil, NSError(domain: "get data is failed=\(status)", code: -999, userInfo: nil))
                        }
                    }, onError: { (error) in
                        completionHandler(nil, nil, error)
                    })
                    .disposed(by: resumeBag)
            }
        }
    }
}
