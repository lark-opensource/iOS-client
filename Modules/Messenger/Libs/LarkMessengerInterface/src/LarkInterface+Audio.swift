//
//  LarkInterface+Audio.swift
//  LarkInterface
//
//  Created by lichen on 2018/6/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkAudioKit
import RustPB
import EENavigator

public typealias PlayerOutputType = LarkAudioKit.PlayerOutputType
public typealias AudioPlayingStatus = LarkAudioKit.AudioPlayingStatus
public typealias AudioProgress = LarkAudioKit.AudioProgress

public struct AudioKey: Equatable {

    public var key: String
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?
    public var info: [String: Any]

    public init(_ key: String, _ authToken: String?, _ info: [String: Any] = [:]) {
        self.key = key
        self.authToken = authToken
        self.info = info
    }

    public static func == (lhs: AudioKey, rhs: AudioKey) -> Bool {
        return lhs.key == rhs.key && lhs.authToken == rhs.authToken
    }
}

public enum AudioPlayMediatorStatus {
    case `default`(String?)
    case loading(String)
    case playing(AudioProgress)
    case pause(AudioProgress)
}

public protocol AudioPlayMediator {

    var outputType: PlayerOutputType { get set }

    var status: AudioPlayMediatorStatus { get }

    var volume: Float { get }

    func playAudioWith(keys: [AudioKey], downloadFileScene: RustPB.Media_V1_DownloadFileScene?, from: NavigatorFrom?)

    func isPlaying(key: String) -> Bool

    func stopPlayingAudio()

    func syncStopPlayingAudio()

    func pausePlayingAudio()

    func updateStatus(_ status: AudioPlayMediatorStatus)

    var isPlaying: Bool { get }

    var outputSignal: Observable<PlayerOutputType> { get }

    var statusSignal: Observable<AudioPlayMediatorStatus> { get }
}

public final class AudioResource {
    public let data: Data
    // duration 按照ms计算
    public let duration: Int32

    public init(data: Data, duration: Int32) {
        self.data = data
        self.duration = duration
    }
}

public protocol AudioResourceService {
    func fetch(key: String, authToken: String?, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, compliteHandler: @escaping (Error?, AudioResource?) -> Void)
    func store(key: String, oldKey: String, resource: AudioResource)
    func resourceDownloaded(key: String) -> Bool
}
