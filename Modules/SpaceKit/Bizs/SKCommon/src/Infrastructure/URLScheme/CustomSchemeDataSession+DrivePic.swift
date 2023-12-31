//
//  CustomSchemeDataSession+DrivePic.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/12/13.
// swiftlint:disable line_length

import SKFoundation
import SpaceInterface
import RxSwift
import UIKit
import SKInfra

extension CustomSchemeDataSession {

    func downloadDriveFile(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        debugPrint("huaguantest, url=\(url)")
        let beginTime = Date.timeIntervalSinceReferenceDate
        let tokenFromUrl = DocsUrlUtil.getTokenFromDriveImageUrl(url)

        guard let token = tokenFromUrl, !token.isEmpty else {
            DocsLogger.error("download drive pic failed, unable to get token from url")
            return
        }

        // gif图片不能下载cover图片，不然会变成静态图片
        let queryDic = url.queryParameters
        let isGif: Bool = url.absoluteString.contains("contentType=gif")
        let forceOrigin = forceUseOrigin(queryDic: queryDic)
        let longPic: Bool = self.isLongPic(queryDic: queryDic)
        var downloadType: DocCommonDownloadType = .defaultCover
        if isGif || forceOrigin || longPic {
            downloadType = .image
        } else if coverVariableFg {
            downloadType = Self.getCoverType(queryDic: queryDic)
        }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            //如果是本地上传的图片，本地可能有缓存，所以先查下本地(本地是原图)
            let assetInfo = DocsContainer.shared.resolve(CommentImageCacheInterface.self)?.getAssetWith(fileTokens: [token]).first
            var cacheData: Data?
            var cacheCoverType: DocCommonDownloadType = downloadType
            if assetInfo?.cacheKey != nil,
               let data = self.downloadCacheServive.data(key: token, type: .image) {
                DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)),  hascache=true, localUploadPic")
                cacheData = data
                cacheCoverType = .image
            } else if let data = self.downloadCacheServive.data(key: token, type: downloadType) {
                DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType), hascache=true")
                cacheData = data
                cacheCoverType = downloadType
            } else if downloadType != .defaultCover, let data = self.downloadCacheServive.data(key: token, type: .defaultCover) {
                //查询下默认缩略图（预加载目前用了1280默认尺寸）
                DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType), hascache=true, from defaultCover")
                cacheData = data
                cacheCoverType = .defaultCover
            } else if let data = self.downloadCacheServive.dataWithVersion(key: token, type: .image, dataVersion: nil) {
                //dataVersion设为nil会去拿数据库中的默认版本号
                DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType), dataVersion=nil, hascache=true, localUploadPic")
                cacheData = data
                cacheCoverType = downloadType
            }

            if let cacheData = cacheData {
                let picSize: Int = cacheData.count
                let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                SKDownloadPicStatistics.downloadPicReport(0, type: cacheCoverType.rawValue, from: .customSchemeDrive, fileType: self.fileType, picSize: picSize, cost: Int(costTime * 1000), cache: .driveCache)
                completionHandler(cacheData, nil, nil)
            } else {
                DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), downloadType=\(downloadType), hascache=false")
                let context = DocCommonDownloadRequestContext(fileToken: token,
                                                              mountNodePoint: "",
                                                              mountPoint: "doc_image",
                                                              priority: .default,
                                                              downloadType: downloadType,
                                                              localPath: nil,
                                                              isManualOffline: self.isOfflineToken(),
                                                              dataVersion: nil,
                                                              originFileSize: nil,
                                                              fileName: nil)
                self.downloader.download(with: context)
                    .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
                    .subscribe(onNext: {  [weak self] (context) in
                        guard let `self` = self else { return }
                        let status = context.downloadStatus
                        if status == .pending {
                            DocsLogger.info("download drive pic, init, key=\(context.key)")
                            self.downloadingDriveKey = context.key
                            self.handleCustomTimeOut(key: context.key, complete: completionHandler)
                        }
                        guard status == .failed || status == .success else { return }
                        guard self.downloadingDriveKey != nil else {
                            DocsLogger.error("download drive pic, downloadingDriveKey is nil")
                            return
                        }
                        self.downloadingDriveKey = nil
                        var picSize = 0
                        var errorCode: Int = (status == .success) ? 0 : context.errorCode
                        let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                        if status == .success, let data = self.downloadCacheServive.data(key: token, type: downloadType) {
                            DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), result=success, costTime=\(costTime)")
                            picSize = data.count
                            completionHandler(data, nil, nil)
                            self.newCacheAPI.mapTokenAndPicKey(token: self.getFileToken(), picKey: token, picType: downloadType.rawValue, needSync: false, isDrivePic: true)
                        } else {
                            DocsLogger.error("download drive pic, token=\(DocsTracker.encrypt(id: token)), result=\(status),but get data fail, key=\(context.key), errorCode=\(context.errorCode)")
                            completionHandler(nil, nil, NSError(domain: "failed=\(status)", code: context.errorCode, userInfo: nil))
                            if status == .success {
                                //成功但是获取不到数据
                                errorCode = SKDownloadPickErrorCode.successButNoData.rawValue
                            }
                        }
                        SKDownloadPicStatistics.downloadPicReport(errorCode, type: downloadType.rawValue, from: .customSchemeDrive, fileType: self.fileType, picSize: picSize, cost: Int(costTime * 1000), cache: .none)
                    }, onError: { (error) in
                        completionHandler(nil, nil, error)
                    })
                    .disposed(by: self.disposeBag)
            }
        }
    }

    private func handleCustomTimeOut(key: String, complete: @escaping (Data?, URLResponse?, Error?) -> Void) {
        //超时逻辑，超过5分钟没下载完返回给前端
        DispatchQueue.main.asyncAfter(deadline: .now() + 300, execute: { [weak self] in
            guard let self = self else {
                return
            }
            if let downloadingKey = self.downloadingDriveKey, key == downloadingKey {
                DocsLogger.error("download drive pic, custom TimeOut, key=\(key)")
                _ = self.downloader.cancelDownload(key: key)
                self.downloadingDriveKey = nil
                complete(nil, nil, NSError(domain: "failed timeOut", code: SKDownloadPickErrorCode.customTimeOut.rawValue, userInfo: nil))
            }
        })
    }

    //https://meego.feishu.cn/larksuite/issue/detail/4709234
    private func forceUseOrigin(queryDic: [String: String]) -> Bool {
        let useOrigin = (queryDic["useOrigin"] as NSString?)?.boolValue
        if useOrigin == true {
            DocsLogger.info("download drive pic, forceUseOrigin=true")
            return true
        }
        return false
    }

    private func isLongPic(queryDic: [String: String]) -> Bool {
        // 如果图片 高 > 宽 * 2，且计算后台压缩后的图片宽度，如果图片宽度小于屏幕则认为是原图
        let widthStr = queryDic["width"] as NSString?
        let heightStr = queryDic["height"] as NSString?
        var widthAfterCompress: CGFloat = 0
        if let height = heightStr?.floatValue,
           let width = widthStr?.floatValue,
           width > 0, height > 0 {
            if height > width * 2, height > 1280.0 {
                widthAfterCompress = CGFloat(width * 1280.0 / height)
            }
        }
        DocsLogger.info("islongPic, picW=\(widthStr?.integerValue ?? 0), picH=\(heightStr?.integerValue ?? 0), widthCompress=\(widthAfterCompress), webWidth=\(webviewWidth)")
        if widthAfterCompress > 0, widthAfterCompress < webviewWidth {
            return true
        }
        return false
    }

    //图片尺寸拉取规则 https://bytedance.feishu.cn/docx/doxcncwx7EqdxC7myMOhAufUy0f
    static func getCoverType(queryDic: [String: String]) -> DocCommonDownloadType {
        let useDisplayWidth = (queryDic["useDisplayParams"] as NSString?)?.boolValue
        let widthValue = (queryDic["width"] as NSString?)?.floatValue
        let heightValue = (queryDic["height"] as NSString?)?.floatValue
        let scaleValue = (queryDic["scale"] as NSString?)?.floatValue
        return SKDocsCoverUtil.getCoverType(width: widthValue.map { CGFloat($0) },
                                            height: heightValue.map { CGFloat($0) },
                                            scale: scaleValue.map { CGFloat($0) },
                                            useDisplayWidth: useDisplayWidth)
    }
}
