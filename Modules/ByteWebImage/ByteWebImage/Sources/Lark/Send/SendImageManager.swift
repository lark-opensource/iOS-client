//
//  LarkSendImageManager.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/14.
//

import RxSwift
import Foundation
import AppReciableSDK
import LKCommonsLogging
import ThreadSafeDataStructure
import Photos

public final class SendImageManager {

    public static var shared = SendImageManager()
    private var sendImageRequestDic: SafeDictionary<UUID, Any> = [:] + .readWriteLock
    private static let logger = Logger.log(SendImageManager.self, category: "SendImageManager")
    init() { }

    /// 发送request
    public func sendImage<T, U>(request: SendImageRequest<T, U>) -> Observable<T> where U: LarkSendImageUploader, U.ResultType == T {
        addRequest(key: request.requestId, request: request)
        // 检查图片
        return concatProcess(request: request)
            .flatMap { () -> Observable<T> in
                if let result = request.context[SendImageRequestKey.UploadResult.ResultType] as? T {
                    return .just(result)
                } else {
                    return .error(LarkSendImageError(type: .upload, error: UploadImageError.noResult))
                }
            }.do(onDispose: { [weak self] in
                self?.removeRequest(key: request.requestId)
            })
    }

    // 当开始处理图片时，将request存储在字典中
    private func addRequest(key: UUID, request: Any) {
        sendImageRequestDic[key] = request
        SendImageManager.logger.info("request \(key) addRequest \(request)")
    }

    // 当图片处理结束后，将request从字典中移除
    private func removeRequest(key: UUID) {
        if let request = sendImageRequestDic.removeValue(forKey: key) {
            SendImageManager.logger.info("request \(key) removeRequest \(request)")
        } else {
            SendImageManager.logger.info("request \(key)")
        }
    }

    // 收集check和compress以及对应结束后的process，组成数组，逐个执行他们
    private func concatProcess<T, U>(request: SendImageRequest<T, U>) -> Observable<Void> {
        var proArray: [Observable<Void>] = []
        // 添加check的步骤
        proArray.append(observable(request.checkProcess, .check, request))
        // 添加after check的步骤
        request.afterCheckProcessorArray.forEach {
            proArray.append(observable($0, .check, request))
        }
        // 添加compress的步骤
        proArray.append(observable(request.compressProcess, .compress, request))
        // 添加after compress的步骤
        request.afterCompressProcessorArray.forEach {
            proArray.append(observable($0, .compress, request))
        }

        // 添加 upload 的步骤
        if request.getContext()[SendImageRequestKey.Other.isCustomTrack] as? Bool == true {
            SendImageManager.logger.info("UniteSendImage requestId: \(request.requestId) use custom track event")
            proArray.append(observable(request.uploaderProcess, .upload, request))
        } else {
            SendImageManager.logger.info("UniteSendImage requestId: \(request.requestId) sendImageManager help you to track event")
            proArray.append(addImageUploadTrackObservable(request.uploaderProcess, .upload, request))
        }
        // 添加after upload的步骤
        request.afterUploadProcessorArray.forEach {
            proArray.append(observable($0, .upload, request))
        }

        SendImageManager.logger.info("request \(request.requestId), proArray: \(proArray)")
        return Observable.create { observer in
            // 逐个执行observable
            return Observable.concat(proArray)
                .subscribe(onError: { error in
                    // check和compress阶段的error已经处理为LarkSendImageError类型
                    // 这里再报错为业务方自己使用afterProcessor产生的错误
                    let err = (error is LarkSendImageError) ? error : LarkSendImageError(type: .custom, error: error)
                    SendImageManager.logger.error("requestId \(request.requestId), a process failed \(error), currentTime: \(CACurrentMediaTime())")
                    observer.onError(err)
                }, onCompleted: {
                    // 执行完process后，发送next指令，进行下一步骤
                    observer.onNext(())
                    observer.onCompleted()
                    SendImageManager.logger.info("requestId \(request.requestId) check、compress、upload process completion")
                })
        }
    }

    func observable(_ processor: LarkSendImageProcessor, _ state: SendImageState, _ request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { observer in
            SendImageManager.logger.info("requestId: \(request.requestId), start a processor \(processor), startTime: \(CACurrentMediaTime())")
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }.flatMap { () -> Observable<Void> in
            return processor.imageProcess(sendImageState: state, request: request)
        }.flatMap { () -> Observable<Void> in
            SendImageManager.logger.info("requestId: \(request.requestId), end a processor, endTime: \(CACurrentMediaTime())")
            return .just(())
        }
    }

    func addImageUploadTrackObservable(_ processor: LarkSendImageProcessor, _ state: SendImageState, _ request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { observer in
            SendImageManager.logger.info("requestId: \(request.requestId), start a processor \(processor), startTime: \(CACurrentMediaTime())")
            let scene: Scene = request.getConfig().checkConfig.scene
            let biz: Biz = request.getConfig().checkConfig.biz
            let compressResults = request.getCompressResult() ?? []

            if compressResults.count == 1, let compressResult = compressResults.first {
                SendImageManager.logger.info("UniteSendImage requestId: \(request.requestId) only one to track")
                let uuid = UUID().uuidString
                compressResult.extraInfo["uuid"] = uuid
                UploadImageTracker.start(key: uuid, scene: scene, biz: biz)
            } else {
                // 如果是多图的发送场景，不应该在这里上传埋点，而是业务方自己封装一层，例如：AttachmentTrackerImage
                assertionFailure()
                for compressResult in compressResults {
                    let uuid = UUID().uuidString
                    compressResult.extraInfo["uuid"] = uuid
                    UploadImageTracker.start(key: uuid, scene: scene, biz: biz)
                }
            }
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }.flatMap { () -> Observable<Void> in
            return processor.imageProcess(sendImageState: state, request: request)
        }.catchError({ error in
            let compressResults = request.getCompressResult() ?? []
            for compressResult in compressResults {
                guard let uuid = compressResult.extraInfo["uuid"] as? String else { continue }
                UploadImageTracker.error(key: uuid, error: error)
            }
            return .error(error)
        }).flatMap { () -> Observable<Void> in
            guard let compressResults = request.getCompressResult() else { return .just(()) }
            let resourceCount = compressResults.count
            for compressResult in compressResults {
                guard let uuid = compressResult.extraInfo["uuid"] as? String else { continue }
                let info = UploadImageInfo()
                info.fromType = request.getConfig().checkConfig.fromType
                info.resourceCount = resourceCount
                info.useOrigin = request.getConfig().checkConfig.isOrigin
                // image_upload的场景是avatar、post、sticker、profile，所以目前不会有降级为文件的场景
                info.fallToFile = false
                info.addParams(compressResult: compressResult)
                UploadImageTracker.end(key: uuid, info: info)
                SendImageManager.logger.info("UniteSendImage requestId: \(request.requestId), completion a track event \(info)")
            }
            SendImageManager.logger.info("UniteSendImage requestId: \(request.requestId), end a processor, endTime: \(CACurrentMediaTime())")
            return .just(())
        }
    }
}
