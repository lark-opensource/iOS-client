//
//  AudioLevel.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/4/29.
//

import UIKit
import Foundation
import LarkAudioView

public typealias AudioView = LarkAudioView.AudioView
public typealias AudioProcessWave = LarkAudioView.AudioProcessWave
public typealias AudioProcessView = LarkAudioView.AudioProcessView
public typealias AudioRecognizeLoadingView = LarkAudioView.AudioRecognizeLoadingView

//不同长度语音对应不同的长度 目前分为7个等级
public enum AudioLevel: TimeInterval {
    case level1 = 10    // 10 s 以下
    case level2 = 20    // 20 s 以下
    case level3 = 30    // 30 s 以下
    case level4 = 40    // 40 s 以下
    case level5 = 50    // 50 s 以下
    case level6 = 60    // 60 s 以下
    case level7 = 70    // 60 s 以上

    static public func level(time: TimeInterval) -> AudioLevel {
        switch time {
        case 0...AudioLevel.level1.rawValue:
            return .level1
        case AudioLevel.level1.rawValue...AudioLevel.level2.rawValue:
            return .level2
        case AudioLevel.level2.rawValue...AudioLevel.level3.rawValue:
            return .level3
        case AudioLevel.level3.rawValue...AudioLevel.level4.rawValue:
            return .level4
        case AudioLevel.level4.rawValue...AudioLevel.level5.rawValue:
            return .level5
        case AudioLevel.level5.rawValue...AudioLevel.level6.rawValue:
            return .level6
        default:
            return .level7
        }
    }

    public func levelValue() -> Int {
        return Int(self.rawValue / 10)
    }

    static public func levelCount() -> Int {
        return 7
    }

    public func minLenght() -> CGFloat {
        switch self {
        case .level1: return 150
        case .level2: return 170
        case .level3: return 190
        case .level4: return 210
        case .level5: return 230
        case .level6: return 250
        case .level7: return 270
        }
    }
}
