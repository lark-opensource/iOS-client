//
//  MinutesPodcastService.swift
//  MinutesInterface
//
//  Created by yangyao on 2021/4/7.
//

import Foundation

public protocol MinutesPodcastService: AnyObject {

    /// 当前是否正在播客模式
    var isPodcast: Bool { get }

    /// 停止播客
    func stopPodcast()
    
    ///立刻停止播客
    func stopPodcastImmediately()
}
