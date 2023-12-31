//
//  MinutesAudioWaveView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/3/11.
//

import UIKit
import MinutesFoundation

protocol MinutesAudioWaveViewModelDelegate: AnyObject {
    func audioPointsDidUpdate()
    func audioPointsDidAdd(_ index: Int)
}

final class MinutesAudioWaveViewModel {

    weak var delegate: MinutesAudioWaveViewModelDelegate?
    var audioDecibelData: MinutesAudioDecibel

    init() {
        audioDecibelData = MinutesAudioRecorder.shared.decibelData
        audioDecibelData.delegate = self
    }

    func clearDecibelData() {
        audioDecibelData.clearDecibelData()
        audioDecibelData.delegate = nil
    }
}

extension MinutesAudioWaveViewModel: MinutesAudioDecibelDelegate {
    func addDecibelData(index: Int) {
        self.delegate?.audioPointsDidAdd(index)
    }
    
    func reloadDecibelData() {
        self.delegate?.audioPointsDidUpdate()
    }
}
