//
//  MinutesDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/26.
//

import Foundation

/// MM相关依赖
public protocol MinutesDependency {
    /// 当前是否正在录音
    var isAudioRecording: Bool { get }
    /// 当前是否正在播客模式
    var isPodcastMode: Bool { get }
    /// 停止录音
    func stopAudioRecording()
    /// 停止博客模式
    func stopPodcast()
}
