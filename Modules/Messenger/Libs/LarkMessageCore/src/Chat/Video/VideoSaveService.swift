//
//  VideoDownloadService.swift
//  Action
//
//  Created by kongkaikai on 2018/10/30.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkFoundation
import LarkUIKit
import Photos
import LarkSDKInterface
import LarkMessengerInterface
import LarkCache
import UniverseDesignToast
import LarkContainer
import RustPB
import LKCommonsLogging
import LarkStorage
import LarkSendMessage
import LarkLocalizations
import LarkSensitivityControl

private typealias Path = LarkSDKInterface.PathWrapper

public final class VideoSaveServiceImpl: VideoSaveService, UserResolverWrapper {

    enum VideoSaveServiceImplToken: String {
        case creationRequestForAssetFromVideo
        case checkPhotoWritePermission

        var token: Token {
            switch self {
            case .creationRequestForAssetFromVideo:
                return Token("LARK-PSDA-VideoSaveService_creationRequestForAssetFromVideo")
            case .checkPhotoWritePermission:
                return Token("LARK-PSDA-VideoSaveService_checkPhotoWritePermission")

            }
        }
    }

    static var logger = Logger.log(VideoSaveServiceImpl.self, category: "VideoSaveServiceImpl")

    private var _videoSavePush = PublishSubject<(String, VideoSavePush)>()
    public var videoSavePush: Driver<(String, VideoSavePush)> {
        return _videoSavePush.asDriver(onErrorRecover: { _ in return .empty() })
    }

    private let disposeBag = DisposeBag()
    private var downloadCache: [String: (String, Float)] = [String: (String, Float)]()
    private let fileAPI: SecurityFileAPI
    private let pushDownloadFile: Driver<PushDownloadFile>
    private let pushSaveToSpaceStoreState: Driver<PushSaveToSpaceStoreState>
    public let userResolver: UserResolver
    /// 权限管控服务
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    @ScopedInjectedLazy var transcodeService: VideoTranscodeService?

    public init(fileAPI: SecurityFileAPI,
                pushDownloadFile: Driver<PushDownloadFile>,
                pushSaveToSpaceStoreState: Driver<PushSaveToSpaceStoreState>,
                userResolver: UserResolver) {
        self.fileAPI = fileAPI
        self.pushDownloadFile = pushDownloadFile
        self.pushSaveToSpaceStoreState = pushSaveToSpaceStoreState
        self.userResolver = userResolver

        self.addDownloadObserver()
    }

    // swiftlint:disable function_parameter_count
    public func saveVideoToAlbumOb(with messageId: String,
                                   key: String,
                                   authToken: String?,
                                   absolutePath: String,
                                   type: RustPB.Basic_V1_File.EntityType,
                                   channelId: String,
                                   sourceType: Message.SourceType,
                                   sourceID: String,
                                   from vc: UIViewController?,
                                   downloadFileScene: RustPB.Media_V1_DownloadFileScene?)
    -> Observable<Result<Void, Error>> {
        self._videoSavePush.onNext((messageId, .downloadStart))
        return fileAPI.downloadFile(messageId: messageId,
                                    key: key,
                                    authToken: authToken,
                                    authFileKey: "",
                                    absolutePath: absolutePath,
                                    isCache: false,
                                    type: type,
                                    channelId: channelId,
                                    sourceType: sourceType,
                                    sourceID: sourceID,
                                    downloadFileScene: downloadFileScene)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (path) in
                self?.downloadCache[messageId] = (path, 0)
            }, onError: { [weak self] (error) in
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .securityControlDeny(let message):
                        self?.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo,
                                                                                authResult: nil,
                                                                                from: vc,
                                                                                errorMessage: message)
                    default: break
                    }
                }
                self?._videoSavePush.onNext((messageId, .downloadFailed))
            })
            .map({ _ -> Result<Void, Error> in
                return Result.success(())
            })
            .catchError({ error in
                Observable.just(Result.failure(error))
            })
    }
    // swiftlint:enable function_parameter_count

    public func saveVideoToAlbum(with messageId: String,
                                 asset: LKDisplayAsset,
                                 info: VideoInfo,
                                 riskDetectBlock: @escaping () -> Observable<Bool>,
                                 from vc: UIViewController?,
                                 downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        chatSecurityControlService?.downloadAsyncCheckAuthority(event: .saveVideo, securityExtraInfo: asset.securityExtraInfo(for: .saveVideo)) { [weak self] authority in
            guard let self = self else { return }
            if !authority.authorityAllowed {
                self.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo,
                                                                       authResult: authority,
                                                                       from: vc,
                                                                       errorMessage: nil)
                 return
            }
            riskDetectBlock().subscribe(onNext: { canDownloadAfterRiskDetect in
                guard canDownloadAfterRiskDetect else { return }
                self._videoSavePush.onNext((messageId, .downloadStart))
                Self.logger.info("save video \(messageId) absolutePath \(info.absolutePath)")
                self.fileAPI.downloadFile(messageId: messageId,
                                          key: info.key,
                                          authToken: info.authToken,
                                          authFileKey: "", // 文件夹、压缩文件嵌套场景，后端需要根文件的key做鉴权，视频、文件的下载是复用的一个接口，视频这里不需要传
                                          absolutePath: info.absolutePath,
                                          isCache: false,
                                          type: info.type,
                                          channelId: info.channelId,
                                          sourceType: info.sourceType,
                                          sourceID: info.sourceID,
                                          downloadFileScene: downloadFileScene)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (path) in
                        Self.logger.info("get video \(messageId) download path \(path)")
                        self?.downloadCache[messageId] = (path, 0)
                    }, onError: { [weak self] (error) in
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .securityControlDeny(let message):
                                self?.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo,
                                                                                        authResult: nil,
                                                                                        from: vc,
                                                                                        errorMessage: message)
                            case .clientErrorRiskFileDisableDownload:
                                let body = RiskFileAppealBody(fileKey: asset.key, locale: LanguageManager.currentLanguage.rawValue)
                                if let window = vc?.view.window {
                                    self?.userResolver.navigator.present(body: body, from: window)
                                }
                            default: break
                            }
                        }
                        self?._videoSavePush.onNext((messageId, .downloadFailed))
                    })
                    .disposed(by: self.disposeBag)
            }).disposed(by: self.disposeBag)
        }
    }

    private func addDownloadObserver() {
        pushDownloadFile.drive(onNext: { [weak self] (push) in
            guard let `self` = self, self.downloadCache.keys.contains(push.messageId) else { return }
            switch push.state {
            case .uploadWait, .uploading, .uploadFail,
                 .uploadCancel, .uploadSuccess, .uploadCreated, .uploadCancelForSwitch:
                break
            case .downloadWait, .downloading:
                let progress: Float = Float(push.progress) / 100.0
                self.downloadCache[push.messageId]?.1 = progress
                self._videoSavePush.onNext((push.messageId, .downloading(progress)))
            case .downloadFail, .downloadCancel, .downloadFailBurned, .downloadFailRecall, .cancelByRisk:
                self.downloadCache.removeValue(forKey: push.messageId)
                self._videoSavePush.onNext((push.messageId, .downloadFailed))
            case .downloadSuccess:
                self._videoSavePush.onNext((push.messageId, .downloading(1)))
                if let path = self.downloadCache[push.messageId]?.0 {
                    self.saveVideoToAlbum(with: path, messageId: push.messageId)
                }
                self.downloadCache.removeValue(forKey: push.messageId)
            case .compressMediaComplete:
                assert(false, "to be implemented")
                break
            @unknown default:
                assert(false, "new value")
                break
            }
        }).disposed(by: disposeBag)

        pushSaveToSpaceStoreState.drive(onNext: { [weak self] (push) in
            switch push.state {
            case .success:
                self?._videoSavePush.onNext((push.messageId, .saveToNutSuccess))
            case .failed:
                self?._videoSavePush.onNext((push.messageId, .saveToNutFailed))
            case .inProgress:
                break
            }
        }).disposed(by: disposeBag)
    }

    // 保存视频到相册
    private func saveVideoToAlbum(with videoPath: String, messageId: String) {
        Self.logger.info("videoPath \(videoPath) exist \(Path(videoPath).exists) messageId \(messageId)")
        try? Utils.checkPhotoWritePermission(token: VideoSaveServiceImplToken.checkPhotoWritePermission.token) { [weak self] (granted) in
            guard granted else {
                self?._videoSavePush.onNext((messageId, .downloadFailed))
                return
            }

            guard !LarkCache.isCryptoEnable() else {
                self?._videoSavePush.onNext((messageId, .cryptoError))
                return
            }
            let url = URL(fileURLWithPath: videoPath)
            PHPhotoLibrary.shared().performChanges({
                try? AlbumEntry.creationRequestForAssetFromVideo(forToken: VideoSaveServiceImplToken.creationRequestForAssetFromVideo.token, atFileURL: url)
            }) { [weak self] (saved, error) in
                Self.logger.info("save video result \(saved) \(error)")
                if !saved {
                    /// 不支持编码格式，需要转码后再存储
                    guard let self = self else { return }
                    let avasset = AVURLAsset(url: url)
                    guard let naturalSize = VideoParser.naturalSize(with: avasset) else {
                        self._videoSavePush.onNext((messageId, .downloadSaveError))
                        return
                    }
                    let tmpPath = IsoPath.temporary() + (UUID().uuidString + ".mp4")

                    var strategy = VideoTranscodeStrategy()
                    strategy.isOriginal = true
                    strategy.isForceReencode = true

                    self.transcodeService?.transcode(
                        key: UUID().uuidString,
                        form: url.path,
                        to: tmpPath.absoluteString,
                        strategy: strategy,
                        videoSize: naturalSize,
                        extraInfo: [:],
                        progressBlock: nil,
                        dataBlock: nil,
                        retryBlock: nil
                    )
                    .subscribe(onNext: { [weak self] arg in
                        guard case .finish = arg.status else { return }
                        let url = URL(fileURLWithPath: videoPath)
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tmpPath.url)
                        }) { [weak self] (saved, error) in
                            Self.logger.info("retry save video result \(saved) \(error)")
                            self?._videoSavePush.onNext((messageId, saved ? .downloadSuccess : .downloadSaveError))
                        }
                    }, onError: { [weak self] (error) in
                        Self.logger.error("save video failed \(error)")
                        self?._videoSavePush.onNext((messageId, .downloadSaveError))
                    }).disposed(by: self.disposeBag)
                } else {
                    self?._videoSavePush.onNext((messageId, saved ? .downloadSuccess : .downloadSaveError))
                }
            }
        }
    }

    public func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: LarkModel.Message.SourceType, sourceID: String) {
        fileAPI.saveFileToSpaceStore(messageId: messageId, chatId: chatId, key: key, sourceType: sourceType, sourceID: sourceID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?._videoSavePush.onNext((messageId, .saveToNutSuccess))
            }, onError: { [weak self] (error) in
                if let apiError = error.underlyingError as? APIError {
                    switch apiError.type {
                    case .storageSpaceReachedLimit:
                        self?._videoSavePush.onNext((messageId, .saveToNutFailedWithMoreThanLimit))
                    default:
                        self?._videoSavePush.onNext((messageId, .saveToNutFailed))
                    }
                }
            }).disposed(by: disposeBag)
    }

    public func isVideoDownloadingAndProgress(for key: String) -> (Bool, Float) {
        return (downloadCache.keys.contains(key), downloadCache[key]?.1 ?? 0)
    }
}
