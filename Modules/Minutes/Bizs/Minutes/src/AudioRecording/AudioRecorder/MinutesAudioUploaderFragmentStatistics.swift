//
//  MinutesAudioUploaderFragmentStatistics.swift
//  Minutes
//
//  Created by yangyao on 2023/4/19.
//

import Foundation
import MinutesFoundation

class AudioUploaderFragmentStatistics {
    struct Count {
        var uploadCount = 0
        var totalCount = 0
    }

    typealias Token = String
    var fragment: [Token: Count] = [:]

    let bizTracker = BusinessTracker()
    func clean(with token: String) {
        fragment.removeValue(forKey: token)
    }

    func appendFragment(with token: String) {
        if var cnt = fragment[token] {
            cnt.totalCount += 1
            fragment[token] = cnt
        } else {
            fragment[token] = Count(uploadCount: 0, totalCount: 1)
        }
    }

    func markFragmentComplete(with token: String) {
        if var cnt = fragment[token] {
            cnt.uploadCount += 1
            fragment[token] = cnt
        } else {
            assertionFailure("no fragment in container!")
        }
    }

    func analyze() -> (Int, Int)? {
        var result: (Int, Int)?
        for (key, value) in fragment {
            MinutesLogger.uploadStatistics.info("token: \(key), totalFragment: \(value.totalCount), successFragment: \(value.uploadCount)")

            bizTracker.tracker(name: .minutesDev, params: ["action_name": "fragments_complete", "total_count": value.totalCount, "success_count": value.uploadCount, "minutes_token": key, "minutes_type": "audio_record", "audio_codec_type": MinutesAudioRecorder.shared.codecType])

            result = (value.totalCount, value.uploadCount)
        }
        return result
    }
}
