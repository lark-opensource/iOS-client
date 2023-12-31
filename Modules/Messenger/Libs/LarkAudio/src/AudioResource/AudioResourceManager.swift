//
//  AudioResourceManager.swift
//  Lark
//
//  Created by qihongye on 2018/8/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkFoundation
import LarkModel
import RxSwift
import RxCocoa
import LarkAudioKit
import LarkCore
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkMonitor
import LarkFeatureGating
import LarkContainer

extension AudioResource: CanStorage {
    public func getData() -> Data {
        return self.data
    }

    public static func generate(data: Data) -> AudioResource? {
        return AudioResource(data: data, duration: 0)
    }
}

final class AudioResourceManagerImpl: ResourceManager<AudioResource, SDKResourceStorageImpl<AudioResource>>, AudioResourceService {
    let disposeBag = DisposeBag()
    static let logger = Logger.log(AudioResourceManagerImpl.self, category: "AudioResourceManagerImpl")
    let pushChannelMessage: Observable<PushChannelMessage>
    private var powerLogSessionsDic: SafeDictionary<String, BDPowerLogSession> = [:] + .readWriteLock
    // FG功能：1. 取消encoder步骤。2. 并行改串行
    // “并行”改“串行”是底层行为。这里只做取消encoder
    private lazy var cancelEncoderFG = userResolver.fg.staticFeatureGatingValue(with: "messenger.audio.pre_decoder")

    private var downloadedResource: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    let userResolver: UserResolver
    init(
        userResolver: UserResolver,
        resourceAPI: ResourceAPI,
        pushChannelMessage: Observable<PushChannelMessage>
    ) {
        self.userResolver = userResolver
        self.pushChannelMessage = pushChannelMessage
        super.init(
            downloader: SDKResourceDownloaderImpl(
                resourceAPI: resourceAPI
            ),
            cache: SDKResourceStorageImpl<AudioResource>(
                resourceAPI: resourceAPI,
                memeryCacheSize: 2000 * 1000
            )
        )

        self.downloader.defaultDownloadOptions = .default

        self.downloader.defaultDownloadOptions?.processor.processReadData = { data -> Data? in
            if OpusUtil.isWavFormat(data) {
                return OpusUtil.encode_wav_data(data)
            }
            return data
        }

        self.downloader.defaultDownloadOptions?.processor.processReceiveData = { data -> Data? in
            if OpusUtil.isWavFormat(data) {
                return data
            }
            return OpusUtil.decode_opus_data(data)
        }

        var cacheOptions: [ResourceStorageOption] = [
            .decode({ (data) -> Data? in
                if OpusUtil.isWavFormat(data) {
                    return data
                }
                return OpusUtil.decode_opus_data(data)
            })
        ]
        if !cancelEncoderFG {
            cacheOptions.append(
                .encode({ (data) -> Data? in
                    if OpusUtil.isWavFormat(data) {
                        return OpusUtil.encode_wav_data(data)
                    }
                    return data
                })
            )
        }
        self.cacheOptions = cacheOptions

        // 清除已撤回消息缓存
        self.pushChannelMessage
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                let message = push.message
                if message.isRecalled && message.type == .audio {
                    // NOTE: 目前被撤回的 audio content 内的 key 是空 未来优化
                    self.cache.removeAllCache()
                }
            })
            .disposed(by: self.disposeBag)
    }

    /// 拉取语音消息：下载 + decode + 存缓存 + 自定义步骤
    func fetch(key: String, authToken: String?, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, compliteHandler: @escaping (Error?, AudioResource?) -> Void) {
        AudioResourceManagerImpl.logger.info("fetch audio key \(key)")
        self.downloader.defaultDownloadOptions?.context[SDKResourceDownloaderImpl.downloadSceneKey] = SDKResourceDownloaderImpl.DownloadScene.transform(downloadFileScene ?? .chat).rawValue
        self.startPowerSessionIfNeeded(key: key)
        self.fetchResource(key: key, authToken: authToken) { [weak self] (error, resource) in
            if resource != nil {
                self?.downloadedResource.insert(key)
            }
            compliteHandler(error, resource)
            self?.endPowerSessionIfNeeded(key: key, error: error, resource: resource)
        }
    }

    func store(key: String, oldKey: String, resource: AudioResource) {
        self.cache.store(key: key, oldKey: oldKey, resource: resource)
    }

    func resourceDownloaded(key: String) -> Bool {
        return self.downloadedResource.contains(key)
    }

    /// 开始功耗监控
    private func startPowerSessionIfNeeded(key: String) {
        guard powerLogSessionsDic[key] == nil else { return }
        let powerLogSession = BDPowerLogManager.beginSession("fetch_audio_resource")
        powerLogSessionsDic[key] = powerLogSession
    }

    /// 结束功耗监控
    private func endPowerSessionIfNeeded(key: String, error: Error?, resource: AudioResource?) {
        guard let session = powerLogSessionsDic[key] else { return }
        var params: [String: Any] = ["fg_is_open": cancelEncoderFG,
                                     "audio_key": key,
                                     "has_error": !(error == nil && resource != nil),
                                     "resource_data": resource?.data.count ?? 0]
        if let apiError = error?.underlyingError as? APIError {
            params["error_code"] = apiError.code
        }
        session.addCustomFilter(params)
        BDPowerLogManager.end(session)
        powerLogSessionsDic.removeValue(forKey: key)
    }
}
