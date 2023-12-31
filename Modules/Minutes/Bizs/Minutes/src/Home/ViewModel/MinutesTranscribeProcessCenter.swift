//
//  MinutesTranscribeProcessCenter.swift
//  Minutes
//
//  Created by sihuahao on 2021/8/5.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

class MinutesTranscribeProcessCenter {

    private var transcribeTimer: Timer?
    var localMinutesTranscribDict: [String: TranscribeData] = [:]
    var completedMinutesToken: [String] = []

    init() {}

    func startTranscribe() {
        stopTranscribeTimer()
        transcribeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }
            self.minutesTranscribeProcess()
        })
        if let transcribeTimer = transcribeTimer {
            RunLoop.current.add(transcribeTimer, forMode: .common)
        }
     }

    func stopTranscribeTimer() {
        transcribeTimer?.invalidate()
        transcribeTimer = nil
     }

    func minutesTranscribeProcess() {
        for item in localMinutesTranscribDict {
            let current = item.value.current
            let rate = item.value.rate
            localMinutesTranscribDict[item.key]?.current += rate
        }
        NotificationCenter.default.post(name: NSNotification.Name.SpaceList.minutesTranscribing, object: nil,
                                        userInfo: ["localMinutesTranscribDict": localMinutesTranscribDict])
     }

    func updateTranscribeStatus(status: [MinutesFeedListItemStatus]) {
        var hasProcessingMinutes: Bool = false
        for item in status {
            let current = Double(item.transcriptProgress.current)
            let rate = Double(item.transcriptProgress.rate)
            let localCurrent = localMinutesTranscribDict[item.objectToken]?.current ?? 0.0
            let localRate = localMinutesTranscribDict[item.objectToken]?.rate ?? 1.0

            localMinutesTranscribDict[item.objectToken] = TranscribeData(current: max(current ?? 0.0, localCurrent),
                                                                         rate: rate ?? localRate)

            if item.objectStatus == .waitASR || item.objectStatus.minutesIsProcessing() {
                hasProcessingMinutes = true
            } else if item.objectStatus == .complete {
                localMinutesTranscribDict[item.objectToken] = nil
            }
        }
        if hasProcessingMinutes {
            startTranscribe()
        }
    }
}

struct TranscribeData {
    var current: Double
    var rate: Double
}
