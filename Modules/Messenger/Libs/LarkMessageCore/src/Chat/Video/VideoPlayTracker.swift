//
//  VideoPlayTracker.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2021/9/16.
//

import UIKit
import Foundation
import TTVideoEngine
import AppReciableSDK
import LKCommonsLogging

final class VideoPlayTracker {

    enum ErrorType {
        case leave
        case error(Int)
    }

    static let logger = Logger.log(VideoPlayTracker.self, category: "Module.VideoPlayTracker")

    /// 播放开始时间
    var startTime: TimeInterval = 0
    /// 本次播放是否是 seek 触发
    var isSeek: Bool = false
    /// 本视频是否存在缓存
    var hasVideoCache: Bool = false

    // 标记本次播放开始时间
    func startPlay() {
        Self.logger.info("start to play video")
        self.startTime = CACurrentMediaTime()
    }

    // 暂停播放
    func pause() {
        Self.logger.info("pause play video")
        self.reset()
    }

    // 停止播放，finish 代表主动停止还是播放结束
    func stop(finish: Bool) {
        Self.logger.info("stop play video finish \(finish)")

        guard self.startTime != 0, !finish else {
            self.reset()
            return
        }
        // 如果是主动停止，且本次播放还没有真正开始，则代表用户主动退出了当前视频，报错
        self.sendErorr(error: .leave)
        self.reset()
    }

    func failed(error: Error) {
        if let nsError = error as? NSError {
            self.sendErorr(error: .error(nsError.code))
        } else {
            Self.logger.error("failed error with \(error)")
            self.sendErorr(error: .error(-999))
        }
    }

    func failed(errorCode: Int) {
        self.sendErorr(error: .error(errorCode))
    }

    /// 更新当前视频状态
    func update(
        playbackState: TTVideoEnginePlaybackState,
        loadState: TTVideoEngineLoadState
    ) {
        guard self.startTime != 0 else {
            return
        }
        /// 状态变为播放时 发送事件
        if playbackState == .playing,
           loadState == .playable {
            self.sendEvent()
        }
    }

    private func sendErorr(error: ErrorType) {
        let endTime = CACurrentMediaTime()
        var category: [String: Any] = [:]
        category["has_video_cache"] = hasVideoCache
        category["is_seek"] = isSeek
        var errorCode: Int = 2
        if case .error(let code) = error {
            category["video_engine_error"] = code
            errorCode = 1
        }
        let extra = Extra(category: category)
        let errorParams = ErrorParams(
            biz: .Messenger,
            scene: .Chat,
            event: .videoPlay,
            errorType: .Other,
            errorLevel: .Fatal,
            errorCode: errorCode,
            userAction: nil,
            page: nil,
            errorMessage: nil,
            extra: extra
        )
        Self.logger.error("sendErorr \(errorParams)")
        AppReciableSDK.shared.error(params: errorParams)
        reset()
    }

    private func sendEvent() {
        let endTime = CACurrentMediaTime()
        let params = TimeCostParams(
            biz: .Messenger,
            scene: .Chat,
            event: .videoPlay,
            cost: Int((endTime - self.startTime) * 1000),
            page: nil,
            extra: Extra(
                category: [
                    "has_video_cache": self.isSeek,
                    "is_seek": self.isSeek
                ]
            )
        )
        AppReciableSDK.shared.timeCost(params: params)
        Self.logger.info("sendEvent \(params)")
        reset()
    }

    // 重置数据
    private func reset() {
        self.startTime = 0
        self.isSeek = false
    }
}
