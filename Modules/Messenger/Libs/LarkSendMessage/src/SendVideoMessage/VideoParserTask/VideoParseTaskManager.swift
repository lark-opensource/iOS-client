//
//  VideoParseTaskManager.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/11/23.
//

import UIKit
import Foundation
import RxSwift // AnyObserver
import RxCocoa // BehaviorRelay
import LKCommonsTracker // Tracker
import LKCommonsLogging // Logger
import ThreadSafeDataStructure // SafeArray
import LarkFeatureGating // @FeatureGating
import LarkContainer
import LarkSDKInterface // PathWrapper

private typealias Path = LarkSDKInterface.PathWrapper

// 支持视频解析重试逻辑, 保证队列串行执行
final class VideoParseTaskManager {

    struct VideoParseTaskWrapper {
        var task: VideoParseTask
        var observer: AnyObserver<VideoParseTask.VideoInfo>
    }

    static let logger = Logger.log(VideoParseTaskManager.self, category: "LarkMessageCore.Chat.Video,VideoParseTaskManager")

    /// 转码任务队列
    private var parseTasks: SafeArray<VideoParseTaskWrapper> = [] + .semaphore

    private var inParsingKey: SafeAtomic<String> = "" + .readWriteLock

    /// 解析结果缓存
    private var parseCache = SafeLRUDictionary<String, VideoParseTask.VideoInfo>(capacity: 10)

    // 当前 app 是否处于后台
    private var isInBackground: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    private var disposeBag = DisposeBag()

    private var backgroundDisposeBag = DisposeBag()

    init() {
        // 监听 app 前后台切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func enterBackground() {
        self.isInBackground.accept(true)
    }

    @objc
    private func enterForeground() {
        self.isInBackground.accept(false)
    }

    /// 添加一个解析任务
    func add(task: VideoParseTask, immediately: Bool) -> Observable<VideoParseTask.VideoInfo> {
        let resourceID = task.resourceID()
        if let result = checkCache(for: resourceID) {
            SendVideoLogger.info("get cache resourceID: \(resourceID)", .parseInfo,
                                 pid: task.taskID, cid: task.contentID)
            return .just(result)
        }
        return Observable<VideoParseTask.VideoInfo>.create({ [weak self] (observer) -> Disposable in
            let wrapper = VideoParseTaskWrapper(task: task, observer: observer)
            if immediately {
                self?.parseTasks.insert(wrapper, at: 0)
                // TODO: 添加 cancel 逻辑，如果当前不是相同任务，取消当前任务
            } else {
                self?.parseTasks.append(wrapper)
            }
            SendVideoLogger.info("add task to queue resourceID: \(resourceID) immediately: \(immediately)", .parseInfo,
                                 pid: task.taskID, cid: task.contentID)
            self?.checkNextTask()
            return Disposables.create()
        })
    }

    /// 检查下一个任务
    private func checkNextTask() {
        guard inParsingKey.value.isEmpty, !self.parseTasks.isEmpty else { return }
        let wrapper = self.parseTasks.remove(at: 0)
        self.inParsingKey.value = wrapper.task.taskID

        // 开始解析之前再检查一次是否有结果了
        if let result = checkCache(for: wrapper.task.resourceID()) {
            SendVideoLogger.info("get result from cache before begin", .parseInfo,
                                 pid: wrapper.task.taskID, cid: wrapper.task.contentID)
            wrapper.observer.onNext(result)
            wrapper.observer.onCompleted()
            self.inParsingKey.value = ""
            self.checkNextTask()
            return
        }

        SendVideoLogger.info("task begin", .parseInfo,
                             pid: wrapper.task.taskID, cid: wrapper.task.contentID)
        // 真正的触发解析
        observable(task: wrapper.task)
            .do(onNext: { (info) in
                Self.postInterceptTracker(info: info)
                self.parseCache[wrapper.task.resourceID()] = info
                SendVideoLogger.debug("save result to cache", .parseInfo,
                                      pid: wrapper.task.taskID, cid: wrapper.task.contentID)
            })
            .do(onDispose: { [weak self] in
                SendVideoLogger.info("task finish", .parseInfo,
                                     pid: wrapper.task.taskID, cid: wrapper.task.contentID)
                self?.inParsingKey.value = ""
                self?.checkNextTask()
            })
            .subscribe(wrapper.observer)
    }

    // 执行转码任务
    private func observable(task: VideoParseTask) -> Observable<VideoParseTask.VideoInfo> {
        return Observable<VideoParseTask.VideoInfo>.create({ [weak self] (observer) -> Disposable in
            self?.innerParse(task: task, currentTime: 0, completion: { result in
                switch result {
                case .success(let info):
                    VideoMessageSend.logger.info("video parse success \(task.taskID)")
                    observer.onNext(info)
                    observer.onCompleted()
                case .failure(let error):
                    VideoMessageSend.logger.error("video parse failed \(task.taskID) error \(error)")
                    observer.onError(error)
                }
            })
            return Disposables.create()
        })
    }

    // 内部解析任务 支持重试
    private func innerParse(
        task: VideoParseTask,
        currentTime: Int,
        completion: @escaping (Result<VideoParseTask.VideoInfo, Error>) -> Void
    ) {
        VideoMessageSend.logger.info("video parse start \(task.taskID) times \(currentTime)")
        var observable: Observable<VideoParseTask.VideoInfo>
        switch task.data {
        case .asset(let asset):
            observable = task.parser.parserVideo(with: asset)
        case .fileURL(let url):
            observable = task.parser.parserVideo(with: url)
        }
        observable.subscribe(onNext: { videoInfo in
            completion(.success(videoInfo))
        }, onError: { [weak self] error in
            guard let self = self else { return }
            // 不重试的错误 list
            if let parseError = error as? VideoParseError {
                switch parseError {
                case .userCancel, .canelProcessTask, .fileReachMax, .videoTrackUnavailable, .getAVCompositionUrlError:
                    // 返回解析错误
                    completion(.failure(error))
                    return
                default: break
                }
            }
            /// 最大重试次数
            let maxRetryTimes = 3
            /// 如果出现失败则进行重试
            if currentTime < maxRetryTimes {
                VideoMessageSend.logger.error("video parse failed \(error) times \(currentTime)")
                // 如果转码出错结束时处于后台 则等待回到前台时再进行下一次重试
                if self.isInBackground.value {
                    self.isInBackground
                        .distinctUntilChanged()
                        .filter { $0 == false }
                        .take(1)
                        .subscribe(onNext: { [weak self] (_) in
                            VideoMessageSend.logger.error("video parse when enter foreground")
                            self?.innerParse(task: task, currentTime: currentTime + 1, completion: completion)
                            self?.backgroundDisposeBag = DisposeBag()
                        }).disposed(by: self.backgroundDisposeBag)
                } else {
                    // 直接进行下一次重试
                    self.innerParse(task: task, currentTime: currentTime + 1, completion: completion)
                }
            } else {
                // 返回解析错误
                completion(.failure(error))
            }
        }).disposed(by: self.disposeBag)
    }

    private func checkCache(for resourceID: String) -> VideoParseTask.VideoInfo? {
        if let result = self.parseCache[resourceID], Path(result.exportPath).exists {
            return result
        }
        return nil
    }

    /// 添加拦截埋点
    private static func postInterceptTracker(info: VideoParseTask.VideoInfo) {
        var interceptResult: Int = 1
        var interceptType: String?
        switch info.status {
            /// 分辨率
        case .reachMaxResolution:
            interceptType = "resolution"
            /// 帧率
        case .reachMaxFrameRate:
            interceptType = "fps"
            /// 码率
        case .reachMaxBitrate:
            interceptType = "bitrate"
            /// 大小
        case .reachMaxSize:
            interceptType = "size"
            /// 时长
        case .reachMaxDuration:
            interceptType = "duration"
        case .empty, .videoTrackEmpty:
            interceptType = "no_support"
        case .fillBaseInfo:
            interceptResult = 0
        }
        Tracker.post(TeaEvent("video_intercept_event_dev", params: [
            "intercept_result": interceptResult,
            "intercept_type": interceptType,
            "video_duration": info.duration,
            "video_file_size": info.filesize / 1024 / 1024
        ]))
    }
}
