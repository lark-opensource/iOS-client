//
//  MinutesPodcastServiceImp.swift
//  Minutes
//
//  Created by yangyao on 2021/4/7.
//

import Foundation
import MinutesInterface
import Minutes

public final class MinutesPodcastServiceImp: MinutesPodcastService {
    /// 初始化方法
    public init() { }

    /// 当前是否正在播客模式
    public var isPodcast: Bool {
        return MinutesPodcast.shared.isInPodcast
    }

    /// 停止播客
    public func stopPodcast() {
        DispatchQueue.main.async {
            if MinutesPodcastSuspendable.isExistPodcastSuspendable() {
                MinutesPodcast.shared.stopPodcast()
            } else {
                MinutesPodcast.shared.pausePodcast()
            }
        }
    }
    
    public func stopPodcastImmediately() {
        MinutesPodcastSuspendable.removePodcastSuspendable()
        MinutesPodcast.shared.stopPodcast()
    }
}
