//
//  MinutesLauncherDelegate.swift
//  MinutesMod
//
//  Created by ByteDance on 2023/3/15.
//

import Foundation
import LarkAccountInterface
import Minutes
import MinutesInterface
import LarkContainer

final class MinutesLauncherDelegate: LauncherDelegate {
    var name: String = "MinutesLauncherDelegate"
    @Provider var podcastService: MinutesPodcastService
    @Provider var audioRecordService: MinutesAudioRecordService
    
    func beforeLogout() {
        stopMinutesPodcast()
        stopAudioRecord()
    }

    func beforeSwitchAccout() {
        stopMinutesPodcast()
        stopAudioRecord()
    }
    
    //结束播客小窗
    private func stopMinutesPodcast() {
        podcastService.stopPodcastImmediately()
    }
    
    //结束录音小窗
    private func stopAudioRecord() {
        audioRecordService.stopRecording()
    }
}

