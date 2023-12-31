//
//  MinutesAudioDataUploader.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/17.
//

import Foundation
import LarkLocalizations
import MinutesFoundation
import AVFoundation
import LarkCache
import LarkStorage
import AudioToolbox
import AppReciableSDK
import LarkContainer
import EENavigator
import LarkSetting
import MinutesNetwork

enum DropReason: Int {
    case retryFailed = 0
    case fragmentNotFound = 1
}

extension DropReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .retryFailed: return "\(rawValue) retry failed"
        case .fragmentNotFound: return "\(rawValue) fragment not found"
        }
    }
}

protocol MinutesAudioDataUploaderDelegate: AnyObject {
    func uploadDidFinish(objectToken: String, uploaderListKey: String?, recordfileURL: URL)
    func taskListCountChanged(objectToken: String, count: Int)
}

class MinutesAudioDataUploader {
    static let bytesPerSecond = 88200
    static let capacity = 102400

    lazy var slardarTracker: SlardarTracker = {
        let tracker = SlardarTracker()
        return tracker
    }()

    lazy var teaTracker: BusinessTracker = {
        let tracker = BusinessTracker()
        return tracker
    }()

    var elseCodeShouldRetry: Bool {
        if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "vc_minutes_upload_retry_strategy")) {
            if let enabled = settings["retry"] as? Bool {
                MinutesLogger.upload.info("get upload retry enabled: \(enabled)")
                return enabled
            } else {
                MinutesLogger.upload.info("get upload retry key failed")
            }
        } else {
            MinutesLogger.upload.info("get upload retry config failed")
        }
        return false
    }

    let retryManager = AudioUploaderRetryManager()
    let statistics = AudioUploaderFragmentStatistics()
    let objectToken: String
    var language: String = LanguageManager.currentLanguage.identifier
    var uploadedTime: TimeInterval = 0.0
    var nextSegID: Int = 1
    // 内层cache,根据token获取一篇妙记里待上传的分片
    lazy var cache = makeMinutesCache()
    ///全量audio data， 这样在音频没有上传成功之前， 也可以进行播放
    lazy var filename: String = "\(objectToken).m4a"
    // 录制文件的path，key以token命名，m4a会往这个路径上写
    lazy var recordfilePath: IsoPath = {
        let path = cache.iso.filePath(forKey: filename)
        return path
    }()
    // 用于写入pcm数据到文件
    lazy var writer: MinutesAudioFileWriter = MinutesAudioFileWriter(recordfilePath.url)

    ///上传分片data， 每个分片会保存为aac文件， 然后上传服务端

    var cacheData: Data = Data(capacity: capacity)
    var sliceLength: Int {
        return cacheData.count
    }

    weak var delegate: MinutesAudioDataUploaderDelegate?
    // 不同妙记分配到不同队列上传
    lazy var workqueue = DispatchQueue(label: "minutes(\(objectToken.suffix(6))) audio data uploader.", qos: .background)
    // 分片上传队列key，根据该key获取一篇妙记里待上传的分片
    lazy var taskListKey: String = "\(objectToken)-TaskList"
    var isUploading: Bool = false
    var isStopping: Bool = false
    var isHangUp: Bool = false
    var api = MinutesAPI.clone()
    var taskList: [String] = []
    lazy var tracker = MinutesAudioDataReciableTracker.load(from: objectToken)
    let containerView: UIView?
    let uploaderListKey: String?

    var process: Int = 0 {
        didSet {
            guard oldValue != process else { return }
            postProcess()
        }
    }

    init(_ token: String, uploaderListKey: String?, taskList: [String]? = nil, container: UIView?) {
        objectToken = token
        containerView = container
        // 兼容，用来标记是哪个uploaderListKey的任务
        self.uploaderListKey = uploaderListKey
        if let list = taskList {
            self.taskList = list
        } else {
            loadTask()
        }
        MinutesLogger.upload.info("created for \(token.suffix(6)) with: \(taskList?.count)")
        uploadNextIfNeeded()
    }

    deinit {
        retryManager.clean()
        statistics.clean(with: objectToken)
        MinutesLogger.upload.info("deinit for \(objectToken.suffix(6)) with: \(taskList.count)")
    }

    func appendAudioData(_ data: Data) {
        workqueue.async { [weak self] in
            guard data.count > 0, let `self` = self else {
                MinutesLogger.recordFile.debug("appendAudioData count is zero")
                return
            }
            // 拼接m4a
            self.writer.appendMedia(data)
            self.cache.saveFileName(self.filename)
            // 添加数据，之后会进行分割
            self.cacheData.append(data)
            // 当大于指定大小时候进行分片
            if self.sliceLength >= MinutesAudioDataUploader.bytesPerSecond {
                MinutesLogger.uploadData.assertDebug(self.sliceLength == MinutesAudioDataUploader.bytesPerSecond, "\(self.objectToken) meet unexpect buffer length: \(self.sliceLength)")
                self.flushAudioData()
            }
        }
    }

    func flushAudioData(hasNext: Bool = true) {
        if isStopping {
            MinutesLogger.upload.debug("Uploading will stop soon, return!")
            return
        }
        // 音频时长
        let duration = Double(sliceLength) / Double(MinutesAudioDataUploader.bytesPerSecond)
        if Int(duration * 1000) < 100 {
            // 小于100ms，直接清除
            self.cacheData.removeAll(keepingCapacity: true)
            uploadNextIfNeeded()
            MinutesLogger.uploadData.debug("invalid audio data: \(objectToken.suffix(6))-\(nextSegID)-next")
            return
        }
        let startTime = Int(uploadedTime * 1000)
        // 分片名
        let filename = "\(objectToken)-\(nextSegID).aac"
        // 获取/构造分片文件路径
        let path = cache.iso.filePath(forKey: filename)
        do {
            MinutesLogger.uploadData.info("writer flush to: \(path.url)")
            // 将分片写入文件
            try writer.flush(to: path)

            let payload = cacheData
            // 构造上传任务
            let task = MinutesAudioDataUploadTask(objectToken: objectToken,
                                                  language: language,
                                                  startTime: "\(startTime)",
                                                  duration: Int(duration * 1000),
                                                  segID: nextSegID,
                                                  payload: payload,
                                                  originSize: sliceLength)
            // 更新序列号
            self.nextSegID += 1
            self.uploadedTime += duration
            MinutesLogger.upload.debug("upload task: \(task.objectToken.suffix(6))-\(task.segID)")
            // 添加上传任务并上传
            upload(task: .upload(task))
            if hasNext {
                // 清除数据，等待下一个分片数据
                self.cacheData.removeAll(keepingCapacity: true)
            }
        } catch {
            // 写入分片到文件异常
            MinutesLogger.uploadData.debug("upload task disk failed \(error)")
            self.isStopping = true
            self.workqueue.async {
                // 一片写入异常则终止所有任务
                self.removeAllTask()
                MinutesAudioRecorder.shared.stop()
                MinutesLogger.uploadData.debug("upload complete for failed")
                // 上传完成
                self.api.uploadComplete(for: self.objectToken) { _ in
                    self.delegate?.uploadDidFinish(objectToken: self.objectToken, uploaderListKey: self.uploaderListKey, recordfileURL: self.recordfilePath.url)
                }
                // 上传完成，标记为false
                self.isUploading = false

                DispatchQueue.main.async {
                    let targetView = self.containerView
                    MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_M_Record_InsufficientStorageRecordingStopped_Toast, targetView: targetView)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        MinutesLogger.uploadData.debug("upload faild and Vibrate")
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    }
                }
            }
        }
    }

    func createSliceWriter() -> MinutesAudioFileWriter {
        let filename = "\(objectToken)-\(nextSegID).aac"
        let path = cache.filePath(forKey: filename)
        let fileURL = URL(fileURLWithPath: path)
        return MinutesAudioFileWriter(fileURL)
    }

    // 结束录音
    func endAudioData() {
        workqueue.async { [weak self] in
            guard let `self` = self else { return }
            // 结束aac数据转换
            self.writer.endEncode()
            self.flushAudioData(hasNext: false)
            // 保存录音文件
            self.cache.saveFileName(self.filename)
            MinutesLogger.upload.debug("\(self.objectToken.suffix(6)) upload end task")
            self.upload(task: .complete(self.objectToken))
            self.tracker.markAsComplete()
        }
    }

    // 历史上传任务完成工作
    func markComplete() {
        workqueue.async { [weak self] in
            guard let `self` = self else { return }
            if self.taskList.last != self.objectToken {
                MinutesLogger.upload.debug("\(self.objectToken.suffix(6)) mark complete.")
                // 自动调用录制完成api
                self.api.recordComplete(for: self.objectToken)
                // 添加上传完成任务
                self.upload(task: .complete(self.objectToken))
                self.tracker.markAsComplete()
            }
        }
    }
}

extension MinutesAudioDataUploader {

    private func appendTask(_ task: MinutesPerfromTask) {
        guard taskList.last != task.cacheKey else { return }
        // 添加任务到上传队列
        taskList.append(task.cacheKey)
        // 存储上传队列，按照分片顺序存储
        cache.set(object: taskList as NSArray, forKey: taskListKey)
        switch task {
        case .complete(let token):
            cache.set(object: Data(), forKey: token, extendedData: nil)
        case .upload(let task):
            // 存储该分片的路径到磁盘，内部会先check对应路径下的文件是否存在
            task.save(to: cache)
        }
        self.delegate?.taskListCountChanged(objectToken: objectToken, count: taskList.count)
    }

    // 完成上传一个分片，进行移除操作
    private func removeFirstTask() {
        guard taskList.count > 0 else { return }
        // 清除一个分片上传任务
        let first = taskList.removeFirst()
        // 移除缓存文件
        cache.removeObject(forKey: first)

        // 更新分片上传任务到缓存
        cache.set(object: taskList as NSArray, forKey: taskListKey)
    }

    private func removeAllTask() {
        MinutesLogger.upload.info("removeAllTask for token: \(objectToken.suffix(6))")
        for key in taskList {
            // 移除缓存文件
            cache.removeObject(forKey: key)
        }
        // 清空任务列表
        taskList.removeAll()
        // 清除分片上传任务
        cache.removeObject(forKey: taskListKey)
    }

    private func loadTask() {
        var list: [String] = []
        // 获取该录音妙记的所有待上传的分片列表，按照分片顺序
        if let cached: NSCoding = cache.object(forKey: taskListKey),
           let cachedTaskList = cached as? [String] {
            MinutesLogger.upload.info("load upload task for minutes: \(objectToken.suffix(6)) count: \(cachedTaskList.count)")
            list = cachedTaskList
        } else {
            MinutesLogger.upload.info("load upload task for \(objectToken.suffix(6)) list empty.")
        }

        taskList = list
    }
}

extension MinutesAudioDataUploader {
    // 添加上传任务并上传
    func upload(task: MinutesPerfromTask) {
        workqueue.async {
            MinutesLogger.upload.info("Add task \(task.description)")
            self.appendTask(task)
            self.uploadNextIfNeeded()
        }
    }

    func startRetry(with retryType: AudioUploaderRetryRequest.RetryType, task: MinutesAudioDataUploadTask) {
        let token = task.objectToken

        let reqID = token + "-" + "\(task.segID)"
        let retryReq = AudioUploaderRetryRequest(reqID: reqID, type: retryType)
        let retryRes = self.retryManager.query(with: retryReq)
        if retryRes.shouldRetry, let interval = retryRes.retryInterval {
            // 重试上传
            self.workqueue.asyncAfter(deadline: .now() + interval, flags: .barrier) {
                MinutesLogger.uploadRetry.info("start retry \(task.objectToken.suffix(6))-\(task.segID), retryType: \(retryType), interval: \(interval), rawInterval: \(retryRes.rawRetryInterval)")
                // 重试上传，标记为false
                self.isUploading = false
                self.uploadNextIfNeeded()
            }
        } else {
            if retryType == .network { return } // 网络问题不丢弃
            MinutesLogger.uploadRetry.info("retry \(task.objectToken.suffix(6))-\(task.segID) failed, reached max retry count, drop, start upload next")
            // 重试失败，丢弃该分片，进行下一个分片的上传
            self.removeFirstAndStartUploadNext(isSuccess: false, task: task)
        }
    }

    // 进行分片上传
    fileprivate func uploadNext(task: MinutesAudioDataUploadTask) {
        MinutesLogger.upload.info("perform upload task \(task.objectToken.suffix(6))-\(task.segID)")

        let token = task.objectToken
        let startTime = CFAbsoluteTimeGetCurrent()
        let size = task.payload.count

        statistics.appendFragment(with: "\(task.objectToken)")

        api.upload(task) { [weak self] result in
            guard let self = self else { return }
            let cost = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            switch result {
            case .failure(let error):
                let extra = Extra(isNeedNet: true, category: ["object_token": token])
                MinutesReciableTracker.shared.error(scene: .MinutesRecorder,
                                                    event: .minutes_upload_audio_data_error,
                                                    error: error,
                                                    extra: extra)

                guard let err = error as? UploadResponseError else { return }
                if case let .error(resError, data, statusCode, logId) = err {
                    if let resError = resError as? ResponseError {
                        var resCode: Int = -1
                        if let result = data as? Result<MinutesAudioDataUploadTask.ResponseType, Error> {
                            if case let .success(response) = result {
                                resCode = response.code
                            }
                        }

                        let bizCode: UploadBizCode? = UploadBizCode(rawValue: resCode)

                        MinutesLogger.uploadFailed.warn("upload audio data \(task.objectToken.suffix(6))-\(task.segID) failed, resError: \(resError), bizCode: \(bizCode), rawCode: \(resCode), statusCode: \(statusCode), logId: \(logId)")
                        if let bizCode = bizCode {
                            self.tracker(statusCode: statusCode, bizCode: bizCode.rawValue, logId: logId, description: bizCode.description)
                        } else {
                            self.tracker(statusCode: statusCode, bizCode: resCode, logId: logId, description: bizCode?.description ?? "")
                        }

                        switch resError {
                        case .requestError: // 400
                            if self.elseCodeShouldRetry {
                                if bizCode == UploadBizCode.notRecordMinutes {
                                    // 结束上传，不删除分片
                                    self.hangupUpload()
                                } else {
                                    // 线性重试
                                    self.startRetry(with: .network, task: task)
                                }
                            } else {
                                // 结束上传，不删除分片
                                self.hangupUpload()
                            }
                        case .uploadCompleted: // 406
                            if self.elseCodeShouldRetry {
                                if bizCode == UploadBizCode.uploadCompleted || bizCode == UploadBizCode.durationTimeout {
                                    // 结束上传，删除本地所有分片
                                    self.completeTaskWhenError(with: token)
                                } else {
                                    // 线性重试
                                    self.startRetry(with: .network, task: task)
                                }
                            } else {
                                // 结束上传，删除本地所有分片
                                self.completeTaskWhenError(with: token)
                            }
                        case .inRecording:
                            // 改到200
                            // 结束录音，分片继续上传
                            self.continueUpload(with: task)
                            self.tracker.cunsume(size: size, cost: cost)
                            // 退出录制并弹框，提示已经结束
                            self.stopRecordAndShowToast(with: token)
                        case .serverError:
                            if bizCode == UploadBizCode.keyDeleted { //  租户密钥已经删除 1000130042
                                // 结束录制，停止上传，不删除分片
//                                self.stopRecordAndShowToast(with: token)
//                                self.hangupUpload()
                                // 密钥删除场景下直接流转妙记状态为失败，继续上传也没必要
                                self.completeTaskWhenError(with: token)
                            } else {
                                // 指数重试
                                self.startRetry(with: .common, task: task)
                            }
                        case .uploadTimeout: // 不存在，跳过
                            break
                        case .authFailed, .noPermission:
                            // 结束上传，不删除分片
                            self.hangupUpload()
                        case .pathNotFound:
                            if self.elseCodeShouldRetry {
                                // 线性重试
                                self.startRetry(with: .network, task: task)
                            } else {
                                // 结束上传，不删除分片
                                self.hangupUpload()
                            }
                        case .resourceDeleted: // 妙记被删除，410
                            // 结束上传，删除本地所有分片
                            self.completeTaskWhenError(with: token)
                        case .noInternet:
                            // 线性重试
                            self.startRetry(with: .network, task: task)
                        default:
                            // invalidJSONObject, invalidData, invalidURL
                            MinutesLogger.uploadFailed.warn("encounter other error: \(resError), hangup task")
                            // 客户端处理model错误，挂起
                            self.hangupUpload()
                        }
                    } else {
                        // 未知code，执行线性重试
                        MinutesLogger.uploadFailed.warn("upload audio data \(task.objectToken.suffix(6))-\(task.segID) failed, resError: \(resError), data: \(data)")
                        // 线性重试
                        self.startRetry(with: .network, task: task)
                    }
                }
                self.tracker.cunsume(size: 0, cost: cost)
            case .success(let response):
                self.statistics.markFragmentComplete(with: "\(task.objectToken)")

                let bizCode: UploadBizCode = UploadBizCode(rawValue: response.code) ?? .unknown
                if bizCode == UploadBizCode.deviceGrabbed { // 1000130048
                    // 退出录制并弹框，提示已经结束
                    self.stopRecordAndShowToast(with: token)
                }

                MinutesLogger.uploadSuccess.info("upload audio data success: \(task.objectToken.suffix(6))-\(task.segID), bizCode: \(bizCode), rawCode: \(response.code)")
                self.continueUpload(with: task)
                self.tracker.cunsume(size: size, cost: cost)
            }
        }
    }
    // 退出录音；结束上传，删除本地所有分片
    func completeTaskWhenError(with token: String) {
        MinutesLogger.upload.info("complete upload task with token: \(token.suffix(6))")
        self.workqueue.async {
            // 删除所有分片任务和分片文件
            self.removeAllTask()
            // 发送上传完成通知
            self.api.uploadComplete(for: token) { _ in
                self.delegate?.uploadDidFinish(objectToken: token, uploaderListKey: self.uploaderListKey, recordfileURL: self.recordfilePath.url)
            }
            // 标记为false
            self.isUploading = false
            // 进行下一个分片的上传
            self.uploadNextIfNeeded()
            // 提示录制已完成
            self.stopRecordAndShowToast(with: token)
        }
    }

    // 继续下个分片的上传
    private func continueUpload(with task: MinutesAudioDataUploadTask) {
        // disable-lint: magic number
        let process = (task.segID * 100) / self.nextSegID
        self.process = min(process, 99)
        // enable-lint: magic number
        MinutesLogger.upload.info("continue upload next fragment, token: \(task.objectToken.suffix(6)), process: \(self.process)")
        self.workqueue.async {
            // 上传成功，移除刚才成功的分片，进行下一个分片的上传
            self.removeFirstAndStartUploadNext()
        }
    }
    
    private func removeFirstAndStartUploadNext(isSuccess: Bool = true, task: MinutesAudioDataUploadTask? = nil, taskKey: String? = nil) {
        // 移除刚才成功的分片，进行下一个分片的上传
        self.removeFirstTask()
        if !isSuccess {
            if let task = task {
                MinutesLogger.upload.info("drop fragment ID: \(task.objectToken.suffix(6))-\(task.segID), token: \(task.objectToken.suffix(6)), reason: \(DropReason.retryFailed)")
            } else if let taskKey = taskKey {
                MinutesLogger.upload.info("drop fragment ID: nil, token: \(taskKey.suffix(6)), reason: \(DropReason.fragmentNotFound)")
            }
        }
        // uploadNextIfNeeded里逻辑：false才会继续上传
        self.isUploading = false
        // 进行下一个分片的上传
        self.uploadNextIfNeeded()
    }

    private func hangupUpload() {
        // do nothing, isUploading is true
        MinutesLogger.upload.info("hangup upload")
    }

    private func stopRecordAndShowToast(with token: String) {
        DispatchQueue.main.async {
            let targetView = self.containerView
            if MinutesAudioRecorder.shared.minutes?.objectToken == token,
               MinutesAudioRecorder.shared.status != .idle {

                NotificationCenter.default.post(name: Notification.minutesAudioRecordingVCDismiss,
                                                object: nil,
                                                userInfo: [Notification.Key.minutesAudioRecordIsStop: true])
                MinutesAudioRecorder.shared.stop()
                if let error = MinutesCommonErrorToastManger.message(forKey: MinutesAPIPath.upload), error.code == noKeyCode {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_RecordingStopped, targetView: targetView)
                    }
                } else {
                    MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_RecordingStopped, targetView: targetView)
                }
            }
        }
    }

    public func uploadNextIfNeeded() {
        workqueue.async {
            // 如果已经在上传了，则return
            guard self.isUploading == false else {
                return
            }
            // 取出第一个分片
            if let taskKey = self.taskList.first {
                self.isUploading = true
                // 去缓存中查找对应的分片路径，如果对应path没有文件，则返回nil
                if let cachedData: (String, Data?) = self.cache.filePathAndExtendedData(forKey: taskKey), let extendInfo = cachedData.1 {
                    // 根据路径获取分片数据，构造上传任务
                    if let task = MinutesAudioDataUploadTask.load(from: self.cache, key: taskKey, extendInfo: extendInfo, encodedData: true) {
                        if task.payload.count == 0 { MinutesLogger.upload.info("upload task payload length is 0!")
                        }
                        self.uploadNext(task: task)
                    } else {
                        MinutesLogger.upload.error("load task \(taskKey.suffix(6)) failed.")
                        // 找不到分片，进行下一个分片上传
                        self.removeFirstAndStartUploadNext(isSuccess: false, task: nil, taskKey: taskKey)
                    }
                } else {
                    // 如果分片被删除，则会走这里，原逻辑：找不到对应的数据，表示上传完成，因此，如果有一个分片被删除，会导致直接上传完成
                    // 找不到分片，删除当前分片
                    self.removeFirstTask()
                    self.isUploading = false
                
                    let token = self.objectToken
                    
                    // 上传完成校验优：判断后续任务是否为空，为空则结束，否则继续剩余分片的上传
                    if self.taskList.isEmpty == false {
                        MinutesLogger.upload.info("could not find fragment: \(token.suffix(6)), taskKey: \(taskKey), drop and start next, remained fragments: \(self.taskList.count)")
                        self.uploadNextIfNeeded()
                        return
                    } else {
                        MinutesLogger.upload.info("all aac data has uploaded, start send complete, \(self.taskList.count), token: \(token.suffix(6))")
                    }
                    
                    MinutesLogger.upload.info("perform complete task \(token.suffix(6))")
                    self.completeRequest(with: token)
                }
            }
        }
    }

    func completeRequest(with token: String) {
        self.api.uploadComplete(for: token) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.tracker.trackUploadFinishEvent()
                self.removeAllTask()
                self.delegate?.uploadDidFinish(objectToken: token, uploaderListKey: self.uploaderListKey, recordfileURL: self.recordfilePath.url)
            } else {
                MinutesLogger.upload.warn("perform complete task \(token.suffix(6)) failed.")

                // 状态接口失败也要指数重试
                let reqID = "\(token) + complete"
                let retryReq = AudioUploaderRetryRequest(reqID: reqID, type: .common)
                let retryRes = self.retryManager.query(with: retryReq)
                if retryRes.shouldRetry, let interval = retryRes.retryInterval {
                    // 重试上传
                    self.workqueue.asyncAfter(deadline: .now() + interval, flags: .barrier) {
                        MinutesLogger.uploadRetry.info("start retry upload status, interval: \(interval)")
                        // 重试上传，标记为false
                        self.completeRequest(with: token)
                    }
                } else {
                    MinutesLogger.uploadRetry.info("upload status retry failed, reached max retry count, do nothing")
                }
            }
        }
    }

    private func postProcess() {
        let userInfo: [String: Any] = ["process": process,
                                       "objectToken": objectToken]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .MinutesAudioDataUploadProcessNotification, object: nil, userInfo: userInfo)
        }
    }
}

extension NSNotification.Name {
    static let MinutesAudioDataUploadProcessNotification = NSNotification.Name("MinutesAudioDataUploadProcessNotification")
}

extension MinutesAudioDataUploader {
    public func tracker(statusCode: Int, bizCode: Int, logId: String, description: String) {
        // metrics需要，确保logID不为空
        var logID = logId.isEmpty == false ? logId : "unknown"
        let params: [String : Any] = ["status_code": statusCode, "biz_code": bizCode, "mm_log_id": logID, "description": description, "path": MinutesAPIPath.upload]
        slardarTracker.tracker(service: BusinessTrackerName.requestError.rawValue, metric: params, category: ["type": "result"])
        teaTracker.tracker(name: .requestError, params: params)
    }
}

