//
//  RustDownloadTask.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/29.
//

import Foundation
import RxSwift
import EEAtomic
import LarkRustClient
import LKCommonsLogging

public final class RustDownloadTask: DownloadTask {
    public var fromLocal: Bool = false

    @AtomicObject
    private var disposeBag = DisposeBag()
    private var request: LarkImageRequest?

    public required init(with request: ImageRequest) {
        self.request = request as? LarkImageRequest
        super.init(with: request)
        LarkImageService.shared.dependency.progressValue?.subscribe(
                onNext: { [weak self] (progressValue) in
                    let (key, progress) = progressValue
                    if let `self` = self, key == self.url.lastPathComponent {
                        self.set(received: Int(progress.completedUnitCount), expected: 100)
                    }
                }).disposed(by: self.disposeBag)
    }

    public override func cancel() {
        super.cancel()
        self.disposeBag = DisposeBag()
    }

    public override func start() {
        super.start()
        // 可能不经过Resource走到这，做下兼容
        let fakeKey = self.url.lastPathComponent
        let resource: LarkImageResource = self.request?.resource ?? LarkImageResource.default(key: fakeKey)
        switch resource {
        case .avatar(let key, let entityID, let params):
            let id = Int64(entityID) ?? 0
            let size = Int32(params.size())
            let dpr = Float(UIScreen.main.scale)
            let format = params.format.displayName
            LarkImageService.shared.dependency.fetchAvatar(entityID: id,
                                                           key: key,
                                                           size: size,
                                                           dpr: dpr,
                                                           format: format).subscribe(onNext: { [weak self] (data) in
                guard let self = self else { return }
                self.isFinished = true // 先设 isFinished 才会有 finishTime
                if let data = data {
                    self.delegate?.downloadTask(self, finishedWith: Result.success(data), path: nil)
                } else {
                    let byteImageError = ImageError(ByteWebImageErrorZeroByte, userInfo: [NSLocalizedDescriptionKey: "empty data"])
                        self.delegate?.downloadTask(self, finishedWith: Result.failure(byteImageError), path: nil)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.isFinished = true
                 let byteImageError = error as? ByteWebImageError ?? ImageError(ByteWebImageErrorRequestFailed, userInfo: [NSLocalizedDescriptionKey: "request failed"])
                    self.delegate?.downloadTask(self, finishedWith: Result.failure(byteImageError), path: nil)
            }, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        default:
            let key = resource.getURLString()
            LarkImageService.shared.dependency.fetchResource(
                resource: resource,
                passThrough: request?.passThrough,
                path: self.savePath,
                onlyLocalData: self.fromLocal
            ).subscribe(onNext: { [weak self] rustResult in
                guard let `self` = self else { return }
                self.isFinished = true // 先设 isFinished 才会有 finishTime
                self.request?.performanceRecorder.contexID = rustResult.contextID
                self.request?.performanceRecorder.rustCost = rustResult.rustCost
                if let url = rustResult.url {
                    if !rustResult.isCrypto { // 非加密场景
                        if let data = try? Data(contentsOf: url) {
                            self.handleSuccess(data: data, key: key, rustResult: rustResult)
                        } else {
                            self.handleFail(key: key, error: rustResult.error)
                        }
                    } else { // 加密场景，还需要再调 Rust 解密接口
                        self.request?.performanceRecorder.decryptBegin = CACurrentMediaTime()
                        let result = LarkImageService.shared.dependency.fetchCryptoResource(path: url.path)
                        self.request?.performanceRecorder.decryptEnd = CACurrentMediaTime()
                        switch result {
                        case .success(let data):
                            self.handleSuccess(data: data, key: key, rustResult: rustResult)
                        case .failure(let error):
                            switch error {
                            case .rustError(let errorCode) where errorCode == 1: // 不是加密文件
                                if let data = try? Data(contentsOf: url) {
                                    self.handleSuccess(data: data, key: key, rustResult: rustResult)
                                } else {
                                    self.handleFail(key: key, error: rustResult.error)
                                }
                            default:
                                self.handleFail(key: key, error: error)
                            }
                        }
                    }
                } else {
                    self.handleFail(key: key, error: rustResult.error)
                }
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        }
    }

    private func handleSuccess(data: Data, key: String?, rustResult: RustImageResultWrapper) {
        guard let url = rustResult.url else {
            return
        }
        if let destKey = key {
            var downloadInfo = ImageDownloadInfo()
            downloadInfo.success = true
            downloadInfo.resourceLength = data.count
            downloadInfo.imageFileFormat = data.bt.imageFileFormat
            downloadInfo.imageSize = data.bt.imageSize
            downloadInfo.queueCost = self.startTime - self.createTime
            downloadInfo.downloadCost = self.finishTime - self.startTime
            downloadInfo.decryptCost = self.request?.performanceRecorder.decryptCost ?? 0
            downloadInfo.fromNet = rustResult.fromNet
            PerformanceMonitor.shared.receiveDownloadInfo(key: destKey, downloadInfo: downloadInfo)
        }
        self.delegate?.downloadTask(self, finishedWith: Result.success(data), path: url.absoluteString)
    }

    private func handleFail(key: String?, error: Error?) {
        if let destKey = key {
            // key必然是会有的
            var downloadInfo = ImageDownloadInfo()
            downloadInfo.queueCost = self.startTime - self.createTime
            downloadInfo.downloadCost = self.finishTime - self.startTime
            downloadInfo.decryptCost = self.request?.performanceRecorder.decryptCost ?? 0
            downloadInfo.success = false
            PerformanceMonitor.shared.receiveDownloadInfo(key: destKey, downloadInfo: downloadInfo)
        }
        if let byteError = error as? ByteWebImageError {
            self.delegate?.downloadTask(self, finishedWith: Result.failure(byteError), path: nil)
        } else if let rcError = error as? RCError,
                  case let .businessFailure(errorInfo: errorInfo) = rcError {
            // sdk mget_resource 接口 返回error_code 0 转600000
            let transCode: Int
            if errorInfo.errorCode == 0 {
                // disable-lint: magic number
                transCode = 600_000
                // enable-lint: magic number
            } else {
                transCode = Int(errorInfo.errorCode)
            }
            let newError = ImageError(transCode,
                                             userInfo: [NSLocalizedDescriptionKey: errorInfo.debugMessage,
                                                        ImageError.UserInfoKey.errorStatus: "\(errorInfo.errorStatus)",
                                                        ImageError.UserInfoKey.errorType: "sdk"])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(newError), path: nil)
        } else if let fetchCryptoError = error as? FetchCryptoError {
            let newError = ImageError(fetchCryptoError.code, userInfo: [NSLocalizedDescriptionKey: fetchCryptoError.description,
                                                                        ImageError.UserInfoKey.errorType: "sdk"])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(newError), path: nil)
        } else {
            let byteImageError = ImageError(ByteWebImageErrorRequestFailed, userInfo: [NSLocalizedDescriptionKey: "request failed: \(String(describing: error))"])
            self.delegate?.downloadTask(self, finishedWith: Result.failure(byteImageError), path: nil)
        }
    }
}
