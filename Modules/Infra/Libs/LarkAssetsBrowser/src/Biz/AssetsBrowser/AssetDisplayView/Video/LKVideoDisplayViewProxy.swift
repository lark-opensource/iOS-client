//
//  LKVideoDisplayViewProxy.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/14.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RustPB

public typealias VideoPlayProxyFactory = () throws -> LKVideoDisplayViewProxy

public enum LKVideoPlaybackState {
    case stopped
    case playing
    case paused
    case error
}

public enum LKVideoLoadState {
    case playable
    case stalled
}

public enum LKVideoConnection {
    case none
    case cellular
    case wifi
}

public enum LKVideoState {
    case valid
    case invalid(Media_V1_GetFileStateResponse.State?)
    case error(Error)
    case fetchFail(Error) // 视频获取失败
}

// LKVideoDisplayViewProxy调用，通过视频本身设置view的变化
public protocol LKVideoDisplayViewProxyDelegate: AnyObject {
    var connection: LKVideoConnection { get set }

    var currentAsset: LKDisplayAsset? { get }

    func set(currentPlaybackTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval)

    func videoReadyToPlay()

    func videoPlaybackStateDidChanged(_ playbackState: LKVideoPlaybackState)

    func videoLoadStateDidChanged(_ loadState: LKVideoLoadState)

    func videoDidStop()

    func videoPlayDidFinish(state: LKVideoState)

    func retryPlay()

    func showAlert(with state: Media_V1_GetFileStateResponse.State)
}

// 外部对View的控制
public protocol LKVideoDisplayViewProtocol: AnyObject {
    // 展示/隐藏/设置进度
    func showProgressView()
    func configProgressView(_ progress: Float)
    func hideProgressView()

    // 暂停/播放视频
    func pause()
    func play()
}

// Note: 将具体的视频播放器和 AssetsBrowser 解耦，使 AssetsBrowser 不依赖于具体的视频播放器
public protocol LKVideoDisplayViewProxy: AnyObject {
    var delegate: LKVideoDisplayViewProxyDelegate? { get set }

    var playerView: UIView { get }

    func setLocalURL(_ localUrl: String)

    func setDirectPlayURL(_ directPlayUrl: String)

    /**
     It's used to play video. You can use it to start or resume the player.
     */
    func play(_ isMuted: Bool)

    /**
     It's used to pause the video playing.
     */
    func pause()

    /**
     It's used to stop the video and it will reset the internal player.
     */
    func stop()

    /**
     It's used to seek to a given time.
     @param process the video press to seek, 0~1
     @param finised the completion handler
     */
    func seekVideoProcess(_ process: Float, complete: @escaping (Bool) -> Void)

    func retryFetchVideo()
}

extension LKVideoDisplayViewProxyDelegate {
    public func showAlert(with state: Media_V1_GetFileStateResponse.State) {}
}
