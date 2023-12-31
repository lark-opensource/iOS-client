//
//  MinutesAudioDataUploadCenter.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/26.
//

import Foundation
import MinutesFoundation
import LarkCache
import LarkContainer
import LarkAccountInterface
import LarkStorage
import AVFoundation
import MinutesNetwork
import LarkSetting

protocol MinutesAudioDataUploadListener: AnyObject {
    func audioDataUploadChanged(status: MinutesAudioDataUploadCenterWorkLoad)
    func audioDataUploadComplete(data: String)
}

public final class MinutesAudioDataUploadCenter {
    var containerView: UIView?

    public static let shared = MinutesAudioDataUploadCenter()
    private var spaceAPI = MinutesSapceAPI()

    let bizTracker = BusinessTracker()
    var userId: String = ""
    var uploaderListKey: String {
        "\(userId)-MinutesAudioDataUploaderList"
    }
    var uploaderListKeyCompatible: String {
        "Minutes-MinutesAudioDataUploaderList"
    }

    lazy var recordFinishOptimize: Bool = {
        guard let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "minutes_upload_optimize")) else {
            MinutesLogger.record.info("get record_finish_optimize config failed")
            return false
        }
        if let enabled = settings["record_finish_optimize"] as? Bool {
            MinutesLogger.record.info("get record_finish_optimize enabled: \(enabled)")
            return enabled
        } else {
            MinutesLogger.record.info("get record_finish_optimize failed")
            return false
        }
    }()

    var listeners = MulticastListener<MinutesAudioDataUploadListener>()
    
    public private(set) var workloadStatus: MinutesAudioDataUploadCenterWorkLoad = .light {
        didSet {
            guard oldValue != workloadStatus else {
                return
            }
            //workload.update(data: workloadStatus)
            self.listeners.invokeListeners { listener in
                listener.audioDataUploadChanged(status: workloadStatus)
            }
        }
    }

    var cachedTaskCount: [String: Int] = [:]

    private init() {
        MinutesLogger.upload.info("init")

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc func appWillEnterForeground() {
        MinutesLogger.uploadAppState.info("willEnterForeground")
    }

    @objc func appDidEnterBackground() {
        MinutesLogger.uploadAppState.info("didEnterBackground")
    }

    @objc func appWillTerminate() {
        MinutesLogger.uploadAppState.info("willTerminate")
    }

    lazy var cache = makeMinutesCache()

    var uploaders: [String: MinutesAudioDataUploader] = [:]

    let stoppedHandle = MinutesRecordStoppedTaskStateHandle()

    private let workQueue = DispatchQueue(label: "minutes.audioData.uploadCenter.queue")

    func initUploaderCheck(userId: String) {
        MinutesLogger.upload.info("initUploaderCheck")
        self.userId = userId
        if self.userId.isEmpty == true {
            MinutesLogger.upload.error("load uploader list with empty userId")
            return
        }
        spaceAPI = MinutesSapceAPI()
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.loadTask()
            // 由于是异步调用，上传播放过程中可能会被删除
            //self.cleanAudioFilesIfNeeded()
        }
    }

    // 强制停止上传
    public func stop() {
        self.uploaders.removeAll()
    }

    private func loadTask() {
        loadUploaderList(with: uploaderListKey)
        // 兼容6.1 key版本
        loadUploaderList(with: uploaderListKeyCompatible)
    }

    // 用户id为key，用户待上传的妙记token为value
    private func saveUploaderList() {
        let list = Array(uploaders.keys)
        cache.set(object: list as NSArray, forKey: self.uploaderListKey)
    }

    // 清空6.1版本兼容存储的上传任务
    private func saveUploaderListCompatible() {
        let object: NSCoding? = cache.object(forKey: self.uploaderListKeyCompatible)
        if object != nil {
            let list = Array(uploaders.keys)
            cache.set(object: list as NSArray, forKey: self.uploaderListKeyCompatible)
        }
    }

    // 获取保存的历史上传任务
    private func loadUploaderList(with uploaderListKey: String) {
        // 获取该用户下所有待上传的妙记token
        let object: NSCoding? = cache.object(forKey: uploaderListKey)
        if let cached: NSCoding = object,
           let cachedUploaderTokenList = cached as? [String] {
            MinutesLogger.upload.info("load uploader list for \(uploaderListKey) with count: \(cachedUploaderTokenList.count)")
            if self.recordFinishOptimize {
                if uploaderListKey == self.uploaderListKey {
                    if cachedUploaderTokenList.isEmpty == false  {
                        MinutesLogger.upload.info("cached uploader token list is not empty")
                        cachedUploaderTokenList.forEach { token in
                            if stoppedHandle.checkMinutesIsStopped(with: token) == false {
                                MinutesLogger.upload.info("tracker record finish for \(token.suffix(6))")
                                trackerRecordFinished(with: token)
                            }
                        }
                    } else {
                        stoppedHandle.cleanStoppedMinutes()
                    }
                }
            }
            // 遍历token列表
            for token in cachedUploaderTokenList {
                // 一篇妙记对应一个uploader
                if uploaders[token] == nil {
                    MinutesLogger.upload.info("start handle local fragment upload with new uploader")
                    // 该篇妙记不存在uploader，构造新的，构造之后直接开始分片上传
                    let uploader = MinutesAudioDataUploader(token, uploaderListKey: uploaderListKey, container: containerView)
                    // 同时注册到uploaders map中并保存到本地
                    register(uploader: uploader)
                    // 历史上传任务完成工作
                    uploader.markComplete()
                } else {
                    MinutesLogger.upload.info("start handle local fragment upload with existed uploaders")
                    // 获取已有的uploader进行上传
                    uploaders[token]?.uploadNextIfNeeded()
                }
            }
        } else {
            MinutesLogger.upload.info("load uploader list for \(uploaderListKey) empty.")
        }
    }
}

/// query api
extension MinutesAudioDataUploadCenter {

    func cleanAudioFilesIfNeeded() {
        let path = cache.iso.rootPath
        do {
            let filePaths = try path.contentsOfDirectory()
            let audioFileTokens = filePaths.compactMap { path -> String? in
                let pathStr = path.absoluteString
                guard pathStr.hasSuffix("m4a") else { return nil }
                let lastPathComponent = (pathStr as NSString).lastPathComponent
                return (lastPathComponent as NSString).deletingPathExtension
            }
            guard !audioFileTokens.isEmpty else {
                MinutesLogger.upload.warn("no loacal audio files to delete.")
                return
            }
            spaceAPI.fetchSpaceFeedListBatchStatus(catchError: false, objectToken: audioFileTokens) { [weak self] result in
                switch result {
                case .success(let list):
                    let tokens = list.status
                        .filter { MinutesInfoStatus.status(from: $0.objectStatus) != .processing }
                        .filter { MinutesInfoStatus.status(from: $0.objectStatus) != .transcoding }
                        .filter { MinutesInfoStatus.status(from: $0.objectStatus) != .audioRecording }
                        .map { $0.objectToken }
                    MinutesLogger.upload.info("Fetching \(list.status.count) status, and trying to deleting \(tokens.count)")
                    self?.cleanAudioFiles(tokens)
                case .failure(_):
                    MinutesLogger.upload.warn("fetchSpaceFeedListBatchStatus error")
                }
            }
        } catch {
            MinutesLogger.upload.error("load audio files failed.")
        }
    }

    func cleanAudioFiles(_ tokens: [String]) {
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            tokens.forEach { key in
                self.cache.removeFile(forKey: "\(key).m4a")
                MinutesLogger.upload.info("Removed cache file \(key.suffix(6)).m4a")
            }
        }
    }
}

extension MinutesAudioDataUploadCenter: MinutesAudioDataUploaderDelegate {
    // disable-lint: magic number
    func uploadDidFinish(objectToken: String, uploaderListKey: String?, recordfileURL: URL) {
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.listeners.invokeListeners { listener in
                listener.audioDataUploadComplete(data: objectToken)
            }
            // 上传完成，清除对应妙记的上传任务
            self.uploaders[objectToken] = nil
            self.cachedTaskCount[objectToken] = nil
            MinutesLogger.upload.info("notice upload finish for \(objectToken.suffix(6)), uploaderListKey: \(String(describing: uploaderListKey))")
            // 更新文件中存储的上传队列
            self.saveUploaderList()
            if uploaderListKey == self.uploaderListKeyCompatible {
                MinutesLogger.upload.info("notice upload finish for \(objectToken.suffix(6)), uploaderListKey: \(String(describing: uploaderListKey))")
                self.saveUploaderListCompatible()
            }
        }

        let uploader = self.uploaders[objectToken]
        _ = uploader?.statistics.analyze()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            let audioAsset = AVAsset(url: recordfileURL)
            audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
                var error: NSError? = nil
                let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                switch status {
                case .loaded:
                    let duration = audioAsset.duration
                    let durationInMillSeconds = CMTimeGetSeconds(duration) * 1000
                    MinutesLogger.upload.info("local m4a file duration: \(durationInMillSeconds), token: \(objectToken.suffix(6))")
                    self.trackerUploadFinished(with: objectToken, duration: durationInMillSeconds)
                case .failed:
                    MinutesLogger.upload.info("local m4a file duration error: \(error), objectToken: \(objectToken.suffix(6))")
                    // 失败仅仅是读取时长失败，避免缺失上传完成点
                    self.trackerUploadFinished(with: objectToken, duration: 0)
                case .cancelled:
                    MinutesLogger.upload.info("local m4a file duration cancelled: \(error), objectToken: \(objectToken.suffix(6))")
                    self.trackerUploadFinished(with: objectToken, duration: 0)
                default: break
                }
            }
        })
    }

    func trackerUploadFinished(with objectToken: String, duration: Float64) {
        self.bizTracker.tracker(name: .minutesDev, params: ["action_name": "audio_record_complete", "audio_expected_duration": duration, "audio_bitrate": MinutesAudioRecorder.shared.codecType == "aac" ? 32 : 18, "minutes_token": objectToken, "minutes_type": "audio_record", "audio_codec_type": MinutesAudioRecorder.shared.codecType])
    }

    func trackerRecordFinished(with objectToken: String) {
        self.bizTracker.tracker(name: .minutesDev, params: ["action_name": "recording_click", "click": "stop_recording", "target": "none", "minutes_token": objectToken, "minutes_type": "audio_record", "audio_codec_type": MinutesAudioRecorder.shared.codecType])
    }
    // enable-lint: magic number

    func taskListCountChanged(objectToken: String, count: Int) {
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.cachedTaskCount[objectToken] = count
            let total = self.cachedTaskCount.reduce(0) { $0 + $1.value }
            self.workloadStatus = .workload(for: total)
        }
    }

    func register(uploader: MinutesAudioDataUploader) {
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            let token = uploader.objectToken
            guard self.uploaders[token] == nil else {
                MinutesLogger.upload.warn("duplicate register uploader for \(token)")
                return
            }
            uploader.delegate = self
            // 将上传任务注册到map中
            self.uploaders[token] = uploader
            // 保存任务到本地
            self.saveUploaderList()
        }
    }
}
