//
//  MinutesAudioDecibel.swift
//  Minutes
//
//
//  Created by panzaofeng on 2021/3/23.
//

import Foundation
import MinutesFoundation

protocol MinutesAudioDecibelDelegate: AnyObject {
    func addDecibelData(index: Int)
    func reloadDecibelData()
}

public final class MinutesAudioDecibel {
    weak var delegate: MinutesAudioDecibelDelegate?
    
    var pointsArray: [CGFloat] = []

    // disable-lint: magic number
    func addDecibelPower(_ audioPower: Float32) {
        var point: CGFloat = 0.06
        let audioPowerAdjust: CGFloat = CGFloat(audioPower) - 80

        if audioPowerAdjust < -25 {
            point = 0.06
        } else if audioPowerAdjust < -20 {
            point = 0.1
        } else if audioPowerAdjust >= -3 {
            point = 1
        } else {
            point = (0.9 * audioPowerAdjust + 19.7) / 17
        }
        self.pointsArray.append(point)

        if pointsArray.count > 300 {
            pointsArray.removeFirst(60)
            self.delegate?.reloadDecibelData()
        } else {
            self.delegate?.addDecibelData(index: pointsArray.count - 1)
        }
    }
    // enable-lint: magic number

    func clearDecibelData() {
        self.pointsArray.removeAll()
    }
}
