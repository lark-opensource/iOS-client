//
//  PreloadPicture.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/6.
//
// 预加载文档里图片的逻辑放这里
// swiftlint:disable function_body_length

import Foundation
import SpaceInterface
import SKFoundation
import SKInfra

struct PreloadPictureTask: PreloadTask {
    private var completeBlock: ((Result<Any, Preload.Err>) -> Void)?
    private var preloadQueue: DispatchQueue
    let key: PreloadKey
    let canUseCarrierNet: Bool
    private var enqueueTime: TimeInterval
    private var loadPriority: PreloadPriority // 预加载优先级
    init(key: PreloadKey, preloadQueue: DispatchQueue, canUseCarrier: Bool, enqueueTime: TimeInterval) {
        self.key = key
        self.preloadQueue = DispatchQueue(label: "docPreloadPicture-\(UUID())", target: preloadQueue)
        self.loadPriority = key.loadPriority
        self.enqueueTime = enqueueTime
        self.canUseCarrierNet = canUseCarrier
    }
    
    func currentPriority() -> PreloadPriority {
        return loadPriority
    }
    
    func getEnqueueTime() -> TimeInterval {
        return enqueueTime
    }
    
    mutating func updatePriority(_ newPriority: PreloadPriority) {
        loadPriority = newPriority
    }
    
    mutating func updateEnqueueTime(_ newEnqueueTime: TimeInterval) {
        enqueueTime = newEnqueueTime
    }
    
    mutating func cancel() {
        completeBlock?(.failure(.cancel))
        completeBlock = nil
    }

    mutating func start(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        self.completeBlock = complete
        self.loadPictures(complete: complete)
    }
    
    fileprivate func loadPictures(complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        preloadQueue.async {
            DocsLogger.info("loadPictures start!", component: LogComponents.preload)
            key.innerLoadPictures(preloadQueue: preloadQueue, complete: complete)
        }
    }
}

struct PreloadPicInfo: Decodable {
    let isDirvePic: Bool?
    let mimeType: String?
    let url: String?
    let picToken: String?
    let scale: CGFloat?
    let oriWidth: CGFloat?
    let oriHeigth: CGFloat?

    enum CodingKeys: String, CodingKey {
        case isDirvePic
        case url
        case mimeType = "mimeType"
        case picToken = "token"
        case scale = "scale"
        case oriWidth = "width"
        case oriHeigth = "height"
    }
}

extension PreloadPictureTask: Hashable {
    static func == (lhs: PreloadPictureTask, rhs: PreloadPictureTask) -> Bool {
        return lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension PreloadKey {

    func makePictureTask(canUseCarrierNetwork: Bool, enqueueTime: TimeInterval, preloadQueue: DispatchQueue) -> PreloadPictureTask {
        return PreloadPictureTask(key: self, preloadQueue: preloadQueue, canUseCarrier: canUseCarrierNetwork, enqueueTime: enqueueTime)
    }

    private func isOfflineToken() -> Bool {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return false
        }
        let token = self.objToken
        let manuOfflineTokens = dataCenterAPI.manualOfflineTokens
        let isOfflined = manuOfflineTokens.contain(objToken: token)
        return isOfflined
    }

    fileprivate func innerLoadPictures(preloadQueue: DispatchQueue, complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        var hasError = false
        var driveRequestDone = true
        var docsRequestDone = true
        var driveImages: [DocCommonDownloadRequestContext] = [] //需要走drive请求的图片
        var docsImages: [URL] = [] //需要走DocsRequst的图片
        let coverVariableFg: Bool = LKFeatureGating.coverVariableFg
        pictureUrls.forEach { (imgInfo) in
            if imgInfo.isDirvePic ?? true {
                let mimeType = imgInfo.mimeType ?? ""
                var downloadType: DocCommonDownloadType = .defaultCover
                if mimeType.contains("gif") {
                    downloadType = .image
                } else if coverVariableFg {
                    downloadType = SKDocsCoverUtil.getCoverType(width: imgInfo.oriWidth, height: imgInfo.oriHeigth, scale: imgInfo.scale, useDisplayWidth: false)
                    debugPrint("preload pic, ,token=\(imgInfo.picToken ?? ""), type=\(downloadType)")
                }
                if let token = imgInfo.picToken, driveDownloadCacheServive.data(key: token, type: downloadType) == nil {
                    let context = DocCommonDownloadRequestContext(fileToken: token,
                                                                  docToken: self.objToken,
                                                                  docType: Int32(self.type.rawValue),
                                                                  mountNodePoint: "",
                                                                  mountPoint: "doc_image",
                                                                  priority: .default,
                                                                  downloadType: downloadType,
                                                                  localPath: nil,
                                                                  isManualOffline: self.isOfflineToken(),
                                                                  dataVersion: nil,
                                                                  originFileSize: nil,
                                                                  fileName: nil)
                    driveImages.append(context)
                } else {
                    debugPrint("preload pic, pic has cache,token=\(imgInfo.picToken ?? ""), type=\(downloadType)")
                }
            } else {
                if let urlStr = imgInfo.url,
                   let imgurl = URL(string: urlStr), !newCacheAPI.hasImge(forKey: imgurl.path, token: self.objToken) {
                    docsImages.append(imgurl)
                }
            }
        }
        /// 走drive通道请求
        if driveImages.count > 0 {
            driveRequestDone = false
            var completeCount = 0
            driverDownloader.download(with: driveImages).subscribe(onNext: { (context) in
                preloadQueue.async {
                    let status = context.downloadStatus
                    guard status == .success || status == .failed else {
                        return
                    }
                    let errorCode: Int = (status == .success) ? 0 : context.errorCode
                    SKDownloadPicStatistics.downloadPicReport(errorCode, type: context.requestContext.downloadType.rawValue, from: .preloadDrive)
                    debugPrint("preload pic, ,token=\(context.requestContext.fileToken), errorCode=\(errorCode), type=\(context.requestContext.downloadType.rawValue)")
                    completeCount += 1
                    if status == .failed {
                        let errorCode = context.errorCode
                        DocsLogger.error("preload pic err, token=\(DocsTracker.encrypt(id: context.requestContext.fileToken)), errorCode: \(errorCode)", component: LogComponents.preload)

                        if errorCode == 403 {
                            //图片预加载403错误，标记该文档不再预加载图片
                            let uid = User.current.info?.userID ?? ""
                            let values: Data? = CacheService.configCache.object(forKey: "ccm.bytedance.preload" + uid)
                            do {
                                var tokens: [String] = []
                                if let resultValues = values {
                                    tokens = try JSONDecoder().decode([String].self, from: resultValues)
                                }

                                if !tokens.contains(self.objToken) {
                                    tokens.append(self.objToken)
                                    let saveData: Data? = try JSONEncoder().encode(tokens.self)
                                    guard let data = saveData else { return }
                                    CacheService.configCache.set(object: data, forKey: "ccm.bytedance.preload" + uid)
                                }
                            } catch {
                                spaceAssertionFailure("preload token cache error")
                            }
                        }

                        hasError = true
                    }
                    if completeCount == driveImages.count {
                        driveRequestDone = true
                        self.callBackIfComplete(driveRequstDone: driveRequestDone, docsRequestDone: docsRequestDone, hasErr: hasError, complete: complete)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        }

        /// 走docsRequest请求
        var requests = docsImages.map {
            return DocsRequest<Any>(url: $0.absoluteString, params: nil, trafficType: .preloadPicture).set(method: .GET)
        }
        if requests.count > 0 {
            docsRequestDone = false
        }

        func loadNext() {
            guard !requests.isEmpty else {
                docsRequestDone = true
                callBackIfComplete(driveRequstDone: driveRequestDone, docsRequestDone: docsRequestDone, hasErr: hasError, complete: complete)
                return
            }
            let request = requests.removeFirst()
            request.start { (data, response, err) in
                preloadQueue.async {
                    var errorCode: Int = 0
                    err.map { _ in
                        hasError = true
                    }
                    data.map { data in
                        let jsonDic = data.jsonDictionary
                        errorCode = jsonDic?["code"] as? Int ?? 0
                        if errorCode != 0 {
                            DocsLogger.error("docsRequest preload pic err, jsonDic=\(String(describing: jsonDic)), token=\(self.objToken.encryptToken), imagesCount=\(docsImages.count)",
                                component: LogComponents.preload
                            )
                        }
                        if let path = request.request?.urlRequest?.url?.path {
                            DispatchQueue.global().async {
                                self.newCacheAPI.storeImage(data as NSCoding, token: self.objToken, forKey: path, needSync: false)
                            }
                        }
                    }
                    if let err = err, let httpRespnose = response as? HTTPURLResponse {
                        if httpRespnose.statusCode != 200 {
                            errorCode = httpRespnose.statusCode
                        } else {
                            errorCode = -1
                        }
                        DocsLogger.error("docsRequest preload pic errorCode=\(errorCode), err=\(err), token=\(self.objToken.encryptToken), imagesCount=\(docsImages.count)",
                            component: LogComponents.preload
                        )

                    }
                    SKDownloadPicStatistics.downloadPicReport(errorCode, type: -1, from: .preloadDocsService)
                    loadNext()
                }
            }
        }
        loadNext()
    }

    func callBackIfComplete(driveRequstDone: Bool, docsRequestDone: Bool, hasErr: Bool, complete: @escaping (Result<Any, Preload.Err>) -> Void) {
        if driveRequstDone, docsRequestDone {
            if hasErr {
                let error = Preload.Err.other
                complete(.failure(error))
            } else {
                complete(.success(()))
            }
        }
    }

    var pictureUrls: [PreloadPicInfo] {
        let preloadMaxCount: Int = 10
        if type == .docX {
            return docxPreloadImages(preloadMaxCount: preloadMaxCount)
        } else {
            var pictureResource = [String: Any]()
            if let src = resources {
                pictureResource = src
            }
            if let imagesrcs = customeParseImageSrcs {
                pictureResource["images"] =  imagesrcs
            }
            guard var images = pictureResource["images"] as? [[String: Any]] else { return [] }
            if images.count > preloadMaxCount, self.isOfflineToken() == false {
                DocsLogger.info("too much picture to preload,need reomve,token is:\(self.objToken.encryptToken)")
                images.removeSubrange((preloadMaxCount..<images.count))
            }
            return images.compactMap({ (imageDict) -> PreloadPicInfo? in
                guard let src = imageDict["src"] as? String else {
                    return nil
                }
                guard let urlStr = src.removingPercentEncoding, let url = URL(string: urlStr) else {
                    return nil
                }
                let imageType = imageDict["image_type"] as? String
                let isDrivePic = DocsUrlUtil.isDriveImageUrl(urlStr)
                let driveToken = DocsUrlUtil.getTokenFromDriveImageUrl(url)
                return PreloadPicInfo(isDirvePic: isDrivePic, mimeType: imageType, url: urlStr, picToken: driveToken, scale: nil, oriWidth: nil, oriHeigth: nil)
            })
        }
    }

    private func docxPreloadImages(preloadMaxCount: Int) -> [PreloadPicInfo] {
        let imageInfosFromRN = PreloadKey.preloadImagesDic[objToken]
        return imageInfosFromRN ?? []
    }
}
