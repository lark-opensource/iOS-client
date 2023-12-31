//
//  MinutesSubtitlesViewController+Player.swift
//  Minutes
//
//  Created by yangyao on 2022/11/17.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

extension MinutesSubtitlesViewController: MinutesVideoDelegate {
    func didSavePlayTime() {
        savePlayInfo()
    }
    
    func didRemovePlayTime() {}
    
    func savePlayInfo(_ needUpdate: Bool = true) {
        let playTime = currentPVM?.playTime
        let paragraphID = currentPVM?.paragraph.id
        let pIndex = currentPVM?.pIndex
        
        guard let paragraphID = paragraphID,
                let pIndex = pIndex,
                let playTime = playTime else {
            return
        }
        // 保证一致性，根据token来存储，issue: 片段加载和正常的历史纪录一致了
//        guard let playtimeKey = player?.playURL?.absoluteString else { return }
        let key = viewModel.minutes.data.objectToken

        var playtimeDict: [String: Double] = [:]
        var pidDict: [String: String] = [:]
        var pidxDict: [String: NSInteger] = [:]

        if let dictionary: [String: Double] = store.value(forKey: NewPlaytimeKey) {
            playtimeDict = dictionary
        }

        // 转成秒来保存
        let playTimeValue = playTime / 1000
        // 单位：秒
        playtimeDict[key] = playTimeValue

        if needUpdate {
            // 下拉刷新由于lastplaytime存在变量里，需要update用于更新lastplaytime
            player?.updateLastPlayTime(playTimeValue)
        }

        if let dictionary: [String: String] = store.value(forKey: NewPidKey) {
            pidDict = dictionary
        }
        pidDict[key] = paragraphID

        if let dictionary: [String: NSInteger] = store.value(forKey: NewPidxKey) {
            pidxDict = dictionary
        }
        pidxDict[key] = pIndex

        guard pidDict.keys.count == pidxDict.keys.count, pidDict.keys.count == playtimeDict.keys.count else {
            assertionFailure("paragraphID and pIndex data error, \(pidDict.keys.count), \(pidxDict.keys.count)")
            
            // 个数不一致，出现了问题，为了保证一致性，移除
            store.removeValue(forKey: NewPlaytimeKey)
            store.removeValue(forKey: NewPidKey)
            store.removeValue(forKey: NewPidxKey)
            store.synchronize()
            
            return
        }

        store.set(playtimeDict, forKey: NewPlaytimeKey)
        store.set(pidDict, forKey: NewPidKey)
        store.set(pidxDict, forKey: NewPidxKey)
        store.synchronize()
    }
    // disable-lint: magic number
    func syncTimeToPlayer(_ startTime: String, manualOffset: NSInteger = 0, didTappedRow: NSInteger? = nil) {
        if let msSeconds = Double(startTime) {
            let playbackTime = msSeconds * 0.001
            // 变成秒
            player?.seekVideoPlaybackTime(playbackTime, manualOffset: manualOffset, didTappedRow: didTappedRow)
        }
    }
    // enable-lint: magic number
    
}



extension MinutesSubtitlesViewController: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        if status.videoPlayerStatus == .playing {
            self.isDragged = false
        }
    }

    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        // 手动更新offset
        let manualOffset = time.payload[.manualOffset]
        guard manualOffset == 0 else {
            return
        }
        // 0表示自动播放
        // 不为0表示点击了快进/快退/拖动进度条/点击进度条，点击文字
        let resetDragging = time.payload[.resetDragging]
        // row不为空表示点击了文字
        let row = time.payload[.didTappedRow]

        // 点击了快进/快退/拖动进度条/点击进度条需要触发自动滚动
        // 点击文字不会触发自动滚动逻辑
        if row == nil, let resetDragging = resetDragging, resetDragging != 0 {
            self.isDragged = false
        }
        // 主动触发的
        let manualTrigger: Bool = (resetDragging != 0)
        if time.time >= 0 {
            let tmpShow = time.time.autoFormat()
            // 变成毫秒
            self.updateSubtitleOffset(time.millisecondString,
                                      index: row,
                                      manualTrigger: manualTrigger, didCompleted: nil)
        }
    }
}
