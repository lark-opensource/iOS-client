//
//  DriveImageDownloader.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/8/25.
//  swiftlint:disable line_length

import UIKit
import Alamofire
import RxSwift
import RxCocoa
import SwiftyJSON
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignToast

protocol DriveImageDownloaderDependency {
    var liinearizedURL: String? { get }
    var fileSize: UInt64 { get } // 文件大小，用于判断非wifi环境下是否需要弹提示
    var downloadPath: SKFilePath { get } // 下载目录
    var imageSize: CGSize? { get } // 用于判断是否需要对渐进式图片进行downsample
    func saveImage(_ completion: @escaping (Bool, SKFilePath?) -> Void) // 将图片从下载目录保存到目标路径，保存成功回调目标路径
}

class DriveImageDownloader: DriveImageLinearizedDownloader {
    class ImageDownloadError: Error {}
    typealias DataResult = Result<(Data, SKFilePath?)>
    typealias ImageResult = Result<(UIImage?, SKFilePath?)>

    private let displaySize: CGSize
    
    private let netWorkFlowHelper = NetworkFlowHelper()
    /// 屏幕大小的4倍即会downSample
    private lazy var maxPixel: CGFloat = {
        displaySize.width * displaySize.height * SKDisplay.scale * SKDisplay.scale * 4
    }()
    private let decodeSerialName = "com.drive.linearizeImageDecode"
    private let downloadSerialName = "com.drive.linearizeImageDownload"

    weak var hostContainer: UIViewController?
    var skipCellularCheck: Bool
    /// 由于流量提醒而取消下载的回调
    var forbidDownload: (() -> Void)?

    lazy var downloadStream: Driver<ImageResult> = {
        return self._dataUpdate.asObservable()
            .throttle(DispatchQueueConst.MilliSeconds_100, scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: decodeSerialName))
            .map({ [weak self] result -> ImageResult in
                guard let self = self else { return .failure(ImageDownloadError()) }
                switch result {
                case .success(let result):
                    return .success((self._decodeImage(with: result.0), result.1))
                case .failure(let error):
                    return .failure(error)
                }
            })
            .asDriver(onErrorJustReturn: .failure(ImageDownloadError()))
    }()

    private let dependency: DriveImageDownloaderDependency
    private var imageData = Data()
    private var dataRequest: DataRequest?
    private let serialQueue: DispatchQueue
    private let _dataUpdate = PublishSubject<DataResult>()

    init(dependency: DriveImageDownloaderDependency, skipCellularCheck: Bool, displaySize: CGSize) {
        self.dependency = dependency
        self.skipCellularCheck = skipCellularCheck
        self.serialQueue = DispatchQueue(label: downloadSerialName)
        self.displaySize = displaySize
    }

    deinit {
        dataRequest?.cancel()
        dataRequest = nil
    }

    func downloadLinearizedImage() {
        guard let fromVC = hostContainer else {
            spaceAssertionFailure("NetworkFlowHelper need from vc")
            return
        }

        guard let url = dependency.liinearizedURL else {
            DocsLogger.error("streamming filePreview has no url")
            return
        }
        /// 流量提醒条件： 能够获取文件大小 且 不处于wifi 且 文件大于50M 且 第一次提醒
        let size = dependency.fileSize
        netWorkFlowHelper.process(size, skipCheck: skipCellularCheck, requestTask: { [weak self] in
            self?._downloadLinearizedImage(with: url)
        }, judgeToast: {[weak self] in
            self?.netWorkFlowHelper.presentToast(view: fromVC.view, fileSize: size)
        })
    }
    
    private(set) var requestId: String = {
        return RequestConfig.generateRequestID()
    }()
    
    private(set) var xttLogId: String = {
        return RequestConfig.generateTTLogid()
    }()

    private func _downloadLinearizedImage(with url: String) {
        if let urlInfo = URL(string: url) {
            DocsLogger.driveInfo("DriveImageDownloader--start download linearizedImage scheme \(String(describing: urlInfo.scheme)),host: \(String(describing: urlInfo.host)) xRequestID:\(requestId),\(DocsCustomHeader.xttLogId.rawValue):\(xttLogId)")
        } else {
            DocsLogger.driveInfo("DriveImageDownloader -- start download linearizedImage url invalid")
        }
        dataRequest = Alamofire.request(url,
                                        method: .get,
                                        parameters: nil,
                                        encoding: URLEncoding.default,
                                        headers: [DocsCustomHeader.xRequestID.rawValue: requestId,
                                                  DocsCustomHeader.requestID.rawValue: requestId,
                                                  DocsCustomHeader.xttTraceID.rawValue: requestId,
                                                  DocsCustomHeader.xttLogId.rawValue: xttLogId]
                                                  )
            .stream(closure: { [weak self] data in
                guard let self = self else { return }
                self.serialQueue.async {
                    self.imageData.append(data)
                    self._dataUpdate.onNext(.success((self.imageData, nil)))
                }
            }).response(completionHandler: { [weak self] (response) in
                guard let self = self else { return }
                self.serialQueue.async {
                    self.dataRequest = nil

                    if let error = response.error {
                        self._dataUpdate.onNext(.failure(error))
                        DocsLogger.error("linearized image download failed \(error)")
                        return
                    }

                    do {
                        try self.imageData.write(to: self.dependency.downloadPath)
                    } catch {
                        assertionFailure("write image data fail \(error)")
                        DocsLogger.error("write image data fail \(error)")
                        return
                    }


                    self.dependency.saveImage { isSuccess, targetPath in
                        if isSuccess, let url = targetPath {
                            self._dataUpdate.onNext(.success((self.imageData, url)))
                        }
                    }
                }
            })
    }

    func suspend() {
        dataRequest?.suspend()
    }

    func resume() {
        dataRequest?.resume()
    }

    private func _decodeImage(with data: Data) -> UIImage? {
        let imageSource = CGImageSourceCreateIncremental(nil)
        CGImageSourceUpdateData(imageSource, data as CFData, false)
        if let size = dependency.imageSize {
            if size.height * size.width > maxPixel {
                let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                         kCGImageSourceThumbnailMaxPixelSize: (size.height > size.width ? displaySize.height : displaySize.width) * SKDisplay.scale,
                                         kCGImageSourceShouldCacheImmediately: true,
                                         kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
                guard let imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
                    DocsLogger.warning("fail to create image")
                    return nil
                }
                return UIImage(cgImage: imageRef)
            } else {
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                    DocsLogger.warning("fail to create image")
                    return nil
                }
                return UIImage(cgImage: imageRef)
            }
        } else {
            // 兜底策略，后端没有返回extra字段，默认压缩
            let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                     kCGImageSourceThumbnailMaxPixelSize: displaySize.width * SKDisplay.scale,
                                     kCGImageSourceShouldCacheImmediately: true,
                                     kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
            guard let imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
                DocsLogger.warning("fail to create image")
                return nil
            }
            return UIImage(cgImage: imageRef)
        }
    }
}
