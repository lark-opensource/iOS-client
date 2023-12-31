//
//  PCMData.swift
//  Pods
//
//  Created by 李晨 on 2019/2/27.
//

import Foundation

/// PCM 音频数据结构
public struct PCMData {
    /// pcm data
    public let data: Data

    /// 声道数
    public let numChannels: Int16

    /// 采样频率
    public let sampleRate: Int32

    /// 采样位数
    public let bitsPerSample: Int16

    /// 码率
    public var byteRate: Int32 {
        return Int32(sampleRate * Int32(numChannels) * Int32(bitsPerSample) / Int32(Data.Element.bitWidth))
    }

    /// 采样位数
    public var blockAlign: Int16 {
        return Int16(numChannels * bitsPerSample / Int16(Data.Element.bitWidth))
    }

    /// byte = 采样频率Hz ×（采样位数/8）× 声道数 × 时间s
    public var during: Double {
        return Double(data.count) * Double(Data.Element.bitWidth) /
            Double(sampleRate) /
            Double(bitsPerSample) /
            Double(numChannels)
    }

    /// 一帧的长度, 这里的一帧为一次采样的数据长度 与音频帧的概念不同
    /// 音频帧数的概念如下：
    /// 对于AAC来说：一帧包含1024个采样点，那么一个帧的时间为datiouration
    /// datiouration= 1024*1000/samplerate:
    /// 音频fps   = 1/duration;
    public var frameLength: Int {
        return Int(Double(numChannels * bitsPerSample) / Double(Data.Element.bitWidth))
    }

    /// init 方法
    public init(data: Data, numChannels: Int16, sampleRate: Int32, bitsPerSample: Int16) {
        self.data = data
        self.numChannels = numChannels
        self.sampleRate = sampleRate
        self.bitsPerSample = bitsPerSample
    }
}
