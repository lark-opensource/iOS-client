//
//  OfficialCoverPhotosDataProvider.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//

import RxSwift
import Alamofire
import SwiftyJSON
import ThreadSafeDataStructure

protocol MailCoverLoadableInfo {
    var token: String { get }
    var priority: Int32? { get }
}

private let kCoverRequestTimeout: TimeInterval = 5.0
private let successCode: Int = 200
class OfficialCoverPhotosProvider: OfficialCoverPhotosNetWorkAPI, MailApmHolderAble  {
    typealias EventType = MailAPMEvent.MailLoadCoverListData

    var loadDataScene: EventType.EndParam = .coverLoadScene(.add)

    private var configurationProvider: ConfigurationProxy?
    init(configurationProvider: ConfigurationProxy?) {
        self.configurationProvider = configurationProvider
    }

    func fetchOfficialCoverPhotosTokenWith(_ parmas: [String: Any]) -> Observable<OfficialCoverPhotosSeries> {
        startAPMEvent()

        guard let url = URL(string: MailCoverAPI.getOfficalCoverURL(configurationProvider: configurationProvider)),
              var urlRequest = try? URLRequest(url: url, method: .get)
        else {
            MailLogger.error("Failed to create cover url")
            endAPMEvent(status: .status_exception, response: nil, coverData: nil)
            return .empty()
        }

        return Observable<OfficialCoverPhotosSeries>.create({ [weak self] (observer) -> Disposable in
            urlRequest.timeoutInterval = kCoverRequestTimeout
            let request = Alamofire.request(urlRequest).responseData { response in
                guard let self = self else {
                    self?.endAPMEvent(status: .status_exception, response: nil, coverData: nil)
                    return
                }

                if let error = response.error {
                    let status: MailAPMEventConstant.CommonParam = error.isRequestTimeout ?
                        .status_timeout : .status_exception
                    self.endAPMEvent(status: status, response: response, coverData: nil)
                    observer.onError(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                    MailLogger.error("Failed to fetch cover: \(error.desensitizedMessage)")
                } else if let data = response.data, let result = try? JSON(data: data) {

                    guard let code = result["code"].int,
                          code == successCode,
                          let msg = result["msg"].string,
                          msg == "ok",
                          let data = result["data"].dictionary,
                          let coverSeries = data["categories"]?.array
                    else {
                        MailLogger.info("fetch oOfficialCoverPhotos: error code")
                        self.endAPMEvent(status: .status_http_fail,
                                         response: response, coverData: nil, result: result)
                        observer.onError(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                        return
                    }

                    var series: OfficialCoverPhotosSeries = OfficialCoverPhotosSeries()
                    // 用于手动设置下载优先级，解决展示图片从下往上加载
                    // 设置一个最大值，不需要后面多遍历一次
                    var maxPriority: Int32 = 100
                    coverSeries.forEach { (modelJson) in
                        guard let dataString = modelJson.rawString(),
                            let data = dataString.data(using: .utf8) else {
                            MailLogger.error("Failed to parse cover dara")
                            observer.onError(OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError)
                            return
                        }
                        do {
                            var serie = try JSONDecoder().decode(OfficialCoverPhotosSerie.self, from: data)
                            MailLogger.error("Parse cover dara success")
                            serie.infos = serie.infos.map({ (info) -> OfficialCoverPhotoInfo in
                                var tempInfo = info
                                tempInfo.priority = maxPriority
                                maxPriority -= 1
                                return tempInfo
                            })
                            series.append(serie)
                        } catch {
                            MailLogger.info("fetch OfficialCoverPhotos: failed to parse data \(error)")
                            self.endAPMEvent(status: .status_exception,
                                             response: nil, coverData: nil)
                            observer.onError(error)
                            return
                        }
                    }
                    self.endAPMEvent(status: .status_success, response: nil, coverData: series)
                    observer.onNext(series)
                } else {
                    self.endAPMEvent(status: .status_exception, response: nil, coverData: nil)
                    observer.onError(OfficialCoverPhotosProviderError.parseOfficialPhotosDataError)
                    MailLogger.error("Failed to parse cover dara")
                }
            }

            return Disposables.create {
                request.cancel()
            }
        })
    }

    // MARK: - APM Event

    private func startAPMEvent() {
        apmHolder[EventType.self] = EventType()
        apmHolder[EventType.self]?.commonParams.append(loadDataScene)
        apmHolder[EventType.self]?.markPostStart()
    }

    private  func endAPMEvent(status: MailAPMEventConstant.CommonParam,
                              response: DataResponse<Data>?,
                              coverData: OfficialCoverPhotosSeries?,
                              result: JSON? = nil) {
        apmHolder[EventType.self]?.endParams.append(status)

        switch status {
        case .status_http_fail:
            /// Extra failure data
            if let response = response as? HTTPURLResponse {
                if let logID = response.headerString(field: "x-tt-logid") {
                    apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.error_log_id(logID))
                }
                if response.statusCode != successCode {
                    apmHolder[EventType.self]?
                        .endParams.append(MailAPMEventConstant.CommonParam.error_code(response.statusCode))
                } else if let code = result?["code"].int, code != successCode {
                    apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.error_code(code))
                }
                if let msg = result?["msg"].string, msg != "ok" {
                    apmHolder[EventType.self]?
                        .endParams.append(MailAPMEventConstant.CommonParam.debug_message(msg))
                }
            }
        default:
         break
        }

        if let coverData = coverData {
            let totalCount = coverData.reduce(0, { $0 + $1.infos.count })
            apmHolder[EventType.self]?.endParams.append(EventType.EndParam.coverListGroupLength(coverData.count))
            apmHolder[EventType.self]?.endParams.append(EventType.EndParam.coverListImageLength(totalCount))
        }
        apmHolder[EventType.self]?.postEnd()
    }
}

class OfficialCoverPhotoDataProvider {
    var defaultThumbnailSize: CGSize { CGSize(width: 300, height: 300) }
    private let downloadQueue = DispatchQueue(label: "com.bytedance.mail.coverDownload", qos: .userInitiated)

    private var imageService: MailImageService?
    private var configurationProvider: ConfigurationProxy?
    init(configurationProvider: ConfigurationProxy?, imageService: MailImageService?) {
        self.imageService = imageService
        self.configurationProvider = configurationProvider
    }
}

extension OfficialCoverPhotoDataProvider: OfficialCoverPhotoDataAPI {
    func fetchOfficialCoverPhotoDataWith(_ photoInfo: OfficialCoverPhotoInfo, coverSize: CGSize?, resumeBag: DisposeBag, completionHandler: @escaping (UIImage?, Error?, MailImageDownloadType) -> Void) {

        guard let imageService = imageService else {
            mailAssertionFailure("imageService should not be nil")
            completionHandler(nil, OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError, .unknown)
            return
        }

        let token = photoInfo.token
        let md5Token = token.md5()
        let isThumbnail = coverSize != nil
        let requestSize = isThumbnail ? defaultThumbnailSize : nil
        let cacheKey = imageService.cache.cacheKey(token: token, size: requestSize)
        if let cacheData = imageService.cache.get(key: cacheKey, type: .transient),
           let image = UIImage(data: cacheData) {
            completionHandler(image, nil, .cache)
            MailLogger.error("[Cover] return cached cover for token: \(md5Token), isThumbnail: \(isThumbnail)")
            return
        }

        guard let url = URL(string: MailCoverAPI.officalCoverURL(configurationProvider: configurationProvider, token: token, isThumbnail: isThumbnail)) else {
            completionHandler(nil, OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError, .unknown)
            return
        }

        downloadQueue.async {
            Observable<Void>.create { _ in
                let request = Alamofire.request(url, method: .get).responseData { response in
                    if let error = response.error {
                        completionHandler(nil, error, .http)
                        MailLogger.error("[Cover] Fetch offical cover failed for token: \(md5Token), error: \(error), isThumbnail: \(isThumbnail)")
                    } else if let imageData = response.data {
                        if let image = UIImage(data: imageData) {
                            imageService.cache.set(key: cacheKey, image: imageData, type: .transient, completion: {})
                            completionHandler(image, nil, .http)
                            MailLogger.error("[Cover] success fetched cover for token: \(md5Token) isThumbnail: \(isThumbnail)")
                        } else {
                            completionHandler(nil, OfficialCoverPhotosProviderError.parseOfficialPhotosDataError, .http)
                            MailLogger.error("[Cover] Failed to parse image data for token: \(md5Token) isThumbnail: \(isThumbnail)")
                        }
                    } else {
                        completionHandler(nil, OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError, .http)
                    }
                }
                return Disposables.create {
                    request.cancel()
                }
            }
            .subscribe(onNext: {})
            .disposed(by: resumeBag)
        }
    }
}
