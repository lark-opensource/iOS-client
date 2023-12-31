//
//  MinutesAudioDataInfo.swift
//  Minutes
//
//  Created by lvdaqian on 2021/5/17.
//

import Foundation
import LarkCache
import AppReciableSDK
import MinutesFoundation

class MinutesAudioDataReciableTracker: NSObject, NSCoding {

    static let timekey = "completeTime"
    static let sizekey = "retainSize"
    static let activekey = "activeTime"
    static let tokenKey = "objectToken"

    static let cache = makeMinutesCache()

    var completeTime: Double = 0
    var retainSize: Int64 = 0
    var activeTime: Int64 = 0
    let objectToken: String
    private let cacheQueue = DispatchQueue(label: "minutes.audioData.reciable.queue")

    var storeKey: String {
        return "\(objectToken)ReciableTracker"
    }

    var hasCompleted: Bool {
        return completeTime != 0
    }

    func encode(with coder: NSCoder) {
        coder.encode(completeTime, forKey: Self.timekey)
        coder.encode(retainSize, forKey: Self.sizekey)
        coder.encode(activeTime, forKey: Self.activekey)
        coder.encode(objectToken, forKey: Self.tokenKey)
    }

    required init?(coder: NSCoder) {
        completeTime = coder.decodeDouble(forKey: Self.timekey)
        retainSize = coder.decodeInt64(forKey: Self.sizekey)
        activeTime = coder.decodeInt64(forKey: Self.activekey)
        objectToken = coder.decodeObject(forKey: Self.tokenKey) as? String ?? ""
    }

    init(_ token: String) {
        objectToken = token
    }

    static func load(from objectToken: String) -> MinutesAudioDataReciableTracker {
        let key = "\(objectToken)ReciableTracker"
        if let data: NSCoding? = MinutesAudioDataReciableTracker.cache.object(forKey: key),
           let tracker = data as? MinutesAudioDataReciableTracker {
            return tracker
        } else {
            return MinutesAudioDataReciableTracker(objectToken)
        }
    }

    func cunsume(size: Int, cost: Int) {
        if hasCompleted {
            activeTime += Int64(cost)
            retainSize += Int64(size)
            save()
        }
    }

    func markAsComplete() {
        completeTime = CFAbsoluteTimeGetCurrent()
        MinutesLogger.recordTracker.info("mark \(objectToken.suffix(6)) as complete: \(completeTime)")
        save()
    }

    func save() {
        cacheQueue.async {
            MinutesAudioDataReciableTracker.cache.set(object: self, forKey: self.storeKey)
            MinutesLogger.recordTracker.info("save \(self.objectToken.suffix(6)) size: \(self.retainSize)B activeTime: \(self.activeTime)ms")
        }
    }

    func trackUploadFinishEvent() {
        guard hasCompleted else {
            MinutesLogger.recordTracker.warn("track an uncompleted minute")
            return
        }
        let cost = Int64((CFAbsoluteTimeGetCurrent() - completeTime) * 1000)
        let finalActiveTime = min(cost, activeTime)
        let finalSize = retainSize

        let extra = Extra(isNeedNet: true, latencyDetail: nil, metric: ["active_time": finalActiveTime, "size": finalSize], category: ["object_token": objectToken], extra: nil)
        let params = TimeCostParams(biz: .VideoConference, scene: .MinutesRecorder, event: .minutes_audio_finish_upload_time, cost: Int(cost), page: nil, extra: extra)
        AppReciableSDK.shared.timeCost(params: params)
        MinutesAudioDataReciableTracker.cache.removeObject(forKey: storeKey)
        MinutesLogger.recordTracker.info("upload finish cost: \(cost)ms size: \(finalSize)B active time: \(finalActiveTime)ms")
    }

}

class MinutesAudioDataTextDisplayedReciableTracker {

    var lastStopTime: Int = 0
    let objectToken: String

    init(_ token: String) {
        objectToken = token
    }

    func trackTextDisplayedEvent(_ stopTimeString: String?) {
        guard lastStopTime == 0,
              let timeString = stopTimeString,
              let stopTime = Int(timeString),
              stopTime > 0
        else {
            return
        }

        let currentTime = Int(MinutesAudioRecorder.shared.recordingTime * 1000)
        let cost = currentTime - stopTime

        let extra = Extra(isNeedNet: true, latencyDetail: nil, metric: nil, category: ["object_token": objectToken], extra: nil)
        let params = TimeCostParams(biz: .VideoConference, scene: .MinutesRecorder, event: .minutes_audio_text_displayed, cost: cost, page: nil, extra: extra)
        AppReciableSDK.shared.timeCost(params: params)
        MinutesLogger.recordTracker.debug("\(objectToken.suffix(6)) text displayed cost: \(cost)ms")

        lastStopTime = stopTime
    }
}
