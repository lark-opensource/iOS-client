//
//  CommentFetchImageUtil.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/10/12.
//

import SKFoundation
import Kingfisher
import SpaceInterface
import RxSwift
import ByteWebImage
import SKUIKit
import Foundation
import SKCommon
import SKInfra

enum CommentFetchImageError {
    case docsRequestJsonErr
    case docsRequestNormalErr
    case driveDownloadErr
    case urlErr
}

class CommentFetchImageUtil {
    public internal(set) static var shared: CommentFetchImageUtil = CommentFetchImageUtil()
    lazy var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    lazy var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!
    private let getCacheImageQueue = DispatchQueue(label: "com.bytedance.docs.commentfetchimage.\(UUID().uuidString)")
    private let disposeBag = DisposeBag()
    
    func isDriveImageUrl(_ urlStr: String) -> Bool {
        return DocsUrlUtil.isDriveImageUrl(urlStr) ||
            urlStr.contains(OpenAPI.APIPath.thumbnailDownload)
    }

    func cacheImage(urlStr: String, picToken: String?) -> UIImage? {
        let result = cacheImageData(urlStr: urlStr, picToken: picToken)
        let data = result.0
        if let size = result.1 {
            let image = try? ByteImage(data, downsampleSize: size)
            DocsLogger.info("CommentFetchImageUtil, get cacheImage: \(image), scaleDownTargetSize: \(size)")
            return image
        }
        let image = try? ByteImage(data)
        DocsLogger.info("CommentFetchImageUtil, no scaleDown get cacheImage: \(image)")
        return image
    }
    
    // 返回值: 图片数据、需要压缩到的目标大小
    private func cacheImageData(urlStr: String, picToken: String?) -> (Data, CGSize?) {
        let url = URL(string: urlStr)
        var result: (Data, CGSize?) = (Data(), nil)
        if let url = url {
            let cacheData: NSCoding? =  CommentImageCache.shared.getImage(byKey: url.path)
            if let cacheData = cacheData as? Data {
                let imageFormat = cacheData.kf.imageFormat
                let orignalSize = SKImagePreviewUtils.originSizeOfImage(data: cacheData) ?? .zero
                if imageFormat == .GIF { // gif暂时无法压缩尺寸, 因为逐帧压缩很耗时
                    result = (cacheData, nil)
                    DocsLogger.info("CommentFetchImageUtil, get cacheImage format: GIF, cacheData:\(String(describing: cacheData)), orignalSize:\(orignalSize)")
                } else {
                    let maxMemoryBytes = 80 * 1024 * 1024
                    let checkResult = SKImagePreviewUtils.isOverSizeAndSampleSize(orignalSize: orignalSize, maxMemoryBytes: maxMemoryBytes)
                    if checkResult.0 {
                        result = (cacheData, checkResult.1)
                    } else {
                        result = (cacheData, nil)
                    }
                    let text = "shouldScaleDown: \(checkResult.0), targetSize:\(checkResult.1), cacheData:\(String(describing: cacheData)), orignalSize:\(orignalSize)"
                    DocsLogger.info("CommentFetchImageUtil, get cacheImage format: \(imageFormat), \(text)")
                }
            } else {
                DocsLogger.error("CommentFetchImageUtil,本地找不到上传图片")
            }
        }
        if result.0.isEmpty, let token = picToken {
            //先判断本地是否有uuid映射，如果有说明曾经本地上传过
            let assetInfo = CommentImageCache.shared.getAssetWith(fileTokens: [token]).first
            if let uuidKeyPath = assetInfo?.cacheKey {
                if  let imageData: NSCoding = CommentImageCache.shared.getImage(byKey: uuidKeyPath),
                    let cacheData = imageData as? Data {
                     result = (cacheData, nil)
                     DocsLogger.error("CommentFetchImageUtil,token=\(DocsTracker.encrypt(id: token)), 本地有曾经上传的图片")
                }
            } else {
                // 有token,但链接不一定要走drive下载通道，因为有可能是前端拼接的cover图片
                if isDriveImageUrl(urlStr) {
                    let drivePicType = DocCommonDownloadType.image
                    if let imageData = downloadCacheServive.data(key: token, type: drivePicType) {
                        DocsLogger.info("CommentFetchImageUtil, token=\(DocsTracker.encrypt(id: token)), driver channel, hascache=true")
                        result = (imageData, nil)
                    }
                }
            }
        }
        return result
    }
    
    /// cacheImage(urlStr: String, picToken: String?)方法的异步版本
    func getCacheImage(imageInfo: CommentImageInfo, useOriginalSrc: Bool, completion: @escaping (UIImage?, CommentImageInfo) -> Void) {
        let urlStr = useOriginalSrc ? (imageInfo.originalSrc ?? "") : imageInfo.src
        let result = cacheImageData(urlStr: urlStr, picToken: imageInfo.token)
        let data = result.0
        let downSize = result.1 ?? CGSize.zero
        
        if data.count >= (1024 * 100) { //100kB及以上图片异步处理
            getCacheImageQueue.async {
                let image = try? ByteImage(data, downsampleSize: downSize)
                DispatchQueue.main.async {
                    completion(image, imageInfo)
                }
            }
        } else {
            let image = try? ByteImage(data, downsampleSize: downSize)
            completion(image, imageInfo)
        }
    }
    
    func fetchImage(urlStr: String, picToken: String?, complete: @escaping (_ urlId: String, _ image: UIImage?, _ err: CommentFetchImageError?) -> Void) {
        let url = URL(string: urlStr)
        let beginTime = Date.timeIntervalSinceReferenceDate

        if let token = picToken, let url = url {
            // 有token,但链接不一定要走drive下载通道，因为有可能是前端拼接的cover图片
            if isDriveImageUrl(urlStr) {
                DispatchQueue.global().async {
                    let drivePicType = DocCommonDownloadType.image
                    let context = DocCommonDownloadRequestContext(fileToken: token,
                                                                  mountNodePoint: "",
                                                                  mountPoint: "doc_image",
                                                                  priority: .default,
                                                                  downloadType: drivePicType,
                                                                  localPath: nil,
                                                                  isManualOffline: false,
                                                                  dataVersion: nil,
                                                                  originFileSize: nil,
                                                                  fileName: nil)
                    self.downloader.download(with: context)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (context) in
                            var picSize: Int = -1
                            let status = context.downloadStatus
                            if status == .success || status == .failed {
                                if status == .success, let data = self?.downloadCacheServive.data(key: token, type: drivePicType) {
                                    DocsLogger.info("CommentFetchImageUtildownload drive suc, token=\(DocsTracker.encrypt(id: token)), result=success")
                                    picSize = data.count
                                    let resultImage = try? ByteImage(data)
                                    complete(urlStr, resultImage, nil)
                                } else {
                                    DocsLogger.error("CommentFetchImageUtildownload drive err, token=\(DocsTracker.encrypt(id: token))")
                                    complete(urlStr, nil, .driveDownloadErr)
                                }
                            }
                            //上报
                            let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                            let errorCode: Int = (status == .success) ? 0 : context.errorCode
                            SKDownloadPicStatistics.downloadPicReport(errorCode, type: drivePicType.rawValue, from: .commentCardDrive, picSize: picSize, cost: Int(costTime * 1000))
                        })
                        .disposed(by: self.disposeBag)
                }
            } else {
                // 走docrequest下载
                let docsRuest = DocsRequest<Any>(url: urlStr, params: nil, trafficType: .download).set(method: .GET).makeSelfReferenced()
                docsRuest.start(rawResult: { (data, _, error) in
                    var reportCode: Int = -1
                    var picSize: Int = -1
                    if let data = data, error == nil {
                        if let jsonDic = data.jsonDictionary, let errorCode = jsonDic["code"] as? Int, errorCode != 0 {
                            reportCode = errorCode
                            DocsLogger.error("docsRequest fetchImage pic err, jsonDic=\(String(describing: jsonDic)), token=\(token.encryptToken)")
                            complete(urlStr, nil, .docsRequestJsonErr)
                        } else {
                            reportCode = 0
                            picSize = data.count
                            CommentImageCache.shared.storeImage(data as NSCoding, forKey: url.path)
                            let resultImage = try? ByteImage(data)
                            complete(urlStr, resultImage, nil)
                        }
                    } else {
                        DocsLogger.info("downloadPic,token=\(DocsTracker.encrypt(id: token)),  error=\(String(describing: error))")
                        complete(urlStr, nil, .docsRequestNormalErr)
                    }
                    //上报
                    let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                    SKDownloadPicStatistics.downloadPicReport(reportCode, type: -1, from: .commentCardDocs, picSize: picSize, cost: Int(costTime * 1000))
                })
            }
        } else {
            complete(urlStr, nil, .urlErr)
            DocsLogger.error("CommentFetchImageUtil,url错误")
        }
    }

}
