//
//  MediaCompressDependencyImpl.swift
//  CCMMod
//
//  Created by bupozhuang on 2022/8/31.
//

import Foundation
import SKDrive
import ByteWebImage
import Photos
import RxSwift
import LarkContainer
import Swinject
import SKFoundation
import SKCommon
import LKCommonsLogging
import SpaceInterface
#if MessengerMod
import LarkSendMessage
#endif

class MediaCompressDependencyImpl: MediaCompressDependency {
    private static let logger = Logger.log(MediaCompressDependencyImpl.self, category: "MediaCompress.larkCompress")
    private static let compressQueue = DispatchQueue(label: "Drive.CompressMedia")
    private let bag = DisposeBag()
    private let resolver: Resolver?
    init(resolver: Resolver?) {
        self.resolver = resolver
    }
    
    func cancelCompress(taskIDs: [String]) {
        Self.compressQueue.async {[weak self] in
            guard let self = self else {
                Self.logger.info("Self is deinited, taskIDs: \(taskIDs)")
                return
            }
        }
#if MessengerMod
        guard let r = self.resolver else {
            spaceAssertionFailure("MediaCompressDependencyImpl: resolver is nil")
            Self.logger.info("No resolver taskIDs: \(taskIDs)")
            return
        }
        guard let impl = r.resolve(VideoMessageSendService.self) else {
            spaceAssertionFailure("MediaCompressDependencyImpl: no VideoMessageSendService impl")
            Self.logger.info("No VideoMessageSendService implement taskIDs: \(taskIDs)")
            return
        }
        for taskID in taskIDs {
            Self.logger.info("start cancel taskID: \(taskID)")
            impl.cancelVideoTranscode(key: taskID)
        }
#else
        Self.logger.info("Messenger Mod not import")
#endif
    }
    
    func compressImage(asset: PHAsset, taskID: TaskID, complete: @escaping (CompressImageResult) -> Void) {
        Self.compressQueue.async { [weak self] in
            guard let self = self else {
                Self.logger.info("self is deinited taskID: \(taskID)")
                complete(CompressImageResult(image: nil, data: nil, taskID: taskID))
                return
            }
            guard let r = self.resolver else {
                spaceAssertionFailure("MediaCompressDependencyImpl: resolver is nil")
                Self.logger.info("resolver is nil taskID: \(taskID)")
                complete(CompressImageResult(image: nil, data: nil, taskID: taskID))
                return
            }
            guard let impl = r.resolve(SendImageProcessor.self) else {
                spaceAssertionFailure("MediaCompressDependencyImpl: no SendImageProcessor impl")
                Self.logger.info("no SendImageProcessor impl taskID: \(taskID)")
                complete(CompressImageResult(image: nil, data: nil, taskID: taskID))
                return
            }
            var dependecy = ImageInfoDependency(useOrigin: false, sendImageProcessor: impl)
            let imageSourceResult: ImageSourceResult = asset.imageInfo(dependecy)
            let result = CompressImageResult(image: imageSourceResult.image, data: imageSourceResult.data, taskID: taskID)
            Self.logger.info("conpressed image taskID: \(taskID)")
            complete(result)
        }
    }
    func compressVideo(videoParseInfo: DriveVideoParseInfo, taskID: TaskID, complete: @escaping (CompressVideoStatus) -> Void) {
        Self.compressQueue.async {[weak self] in
            guard let self = self else {
                Self.logger.info("self is deinited taskID: \(taskID)")
                complete(.failed(msg: "Self is deinited", taskID: taskID))
                return
            }
#if MessengerMod
            guard let r = self.resolver else {
                spaceAssertionFailure("MediaCompressDependencyImpl: resolver is nil")
                Self.logger.info("resolver is nil taskID: \(taskID)")
                complete(.failed(msg: "No resolver", taskID: taskID))
                return
            }
            guard let impl = r.resolve(VideoMessageSendService.self) else {
                spaceAssertionFailure("MediaCompressDependencyImpl: no VideoMessageSendService impl")
                Self.logger.info("No VideoMessageSendService implement: \(taskID)")
                complete(.failed(msg: "No VideoMessageSendService implement", taskID: taskID))
                return
            }
            let response = impl.transcode(key: taskID,
                                          form: videoParseInfo.originPath.path,
                                            to: videoParseInfo.exportPath.path,
                                            isOriginal: false,
                                            videoSize: videoParseInfo.videoSize,
                                            extraInfo: [:],
                                            progressBlock: { progress in
                Self.logger.info("compress video progress \(progress), taskID: \(taskID)")
                complete(CompressVideoStatus.progress(progress: progress, taskID: taskID))
            }, dataBlock: nil, retryBlock: nil)
            Self.logger.info("start call compress video with taskID: \(taskID)")
            response.subscribe(onNext: { arg in
                if arg.key == taskID, case .finish = arg.status {
                    Self.logger.info("compress video success \(taskID)")
                    let result = CompressVideoStatus.success(taskID: taskID)
                    complete(result)
                } else {
                    Self.logger.info("compress video status \(arg.status), taskID: \(taskID)")
                }
            }, onError: { error in
                Self.logger.info("compress video error \(error), taskID: \(taskID)")
                complete(.failed(msg: "compress error \(error.localizedDescription)", taskID: taskID))
            }).disposed(by: self.bag)
#else
            Self.logger.info("no messengerMod")
            complete(.failed(msg: "No MessengerMod", taskID: taskID))
#endif
        }
    }
}
