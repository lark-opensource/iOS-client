//
//  Decibel.swift
//  LarkChat
//
//  Created by 李晨 on 2019/2/27.
//

import Foundation
import LKCommonsLogging

/// 分贝模型
public struct Decibel {
    /// 最大分贝
    public var maxValue: Double
    /// 最小分贝
    public var minValue: Double
    /// 平均分贝
    public var avgValue: Double
}

/// 根据 pcm 格式音频获取当前分贝
public extension Decibel {

    static let logger = Logger.log(Decibel.self, category: "Module.Audio")

    /// amplitude = 20 * log10(abs(sample) / 32767) dBFS
    static func getDecibel(data: Data, channel: Int16, bitsPerSample: Int16) -> Decibel {
        var sumVolume: Double = 0
        var avgVolume: Double = 0
        var maxVolume: Double = 0
        var minVolume: Double = 100

        let bytes: [UInt8] = Array(data)

        let valumeLength = Int(Double(channel * bitsPerSample) / Double(Data.Element.bitWidth))

        let volumeBlock: ([UInt8]) -> Double = { bytes in
            var volumes: [Double] = []
            // pcm 格式数据使用 Little Endian
            for i in 0..<(bytes.count / valumeLength) {
                //暂时只取一个声道
                let index = i * valumeLength
                if bitsPerSample == 16 {
                    volumes.append(
                        Double(abs(Int32(Int8(bitPattern: bytes[index])) +
                            (Int32(Int8(bitPattern: bytes[index + 1])) << 8))
                        )
                    )
                } else {
                    volumes.append(Double(abs(Double(Int8(bitPattern: bytes[index])))))
                }
            }
            if !volumes.isEmpty {
                return volumes.reduce(0, +) / Double(volumes.count)
            } else {
                return 0
            }
        }

        let frameCount = bytes.count / valumeLength
        for i in 0..<frameCount {
            let from = i * valumeLength
            let to = from + valumeLength
            let volumeBytes = Array(bytes[from..<to])
            let volume = volumeBlock(volumeBytes)
            maxVolume = max(volume, maxVolume)
            minVolume = max(min(volume, minVolume), 0)
            sumVolume += volume
        }
        avgVolume = sumVolume / Double(frameCount)

        let avgValue = 20 * log10(max(avgVolume, 1))
        let maxValue = 20 * log10(max(maxVolume, 1))
        let minValue = 20 * log10(max(minVolume, 1))

        // 存在计算出分贝数值不合法
        // 由于无法控制外部传入参数, 所以在这里添加判断
        // 添加日志与 assert 帮助开发定位问题
        let checkIsValid: (Double) -> Double = { value in
            if !value.isFinite {
                Decibel.logger.error(
                    "get decibel failed",
                    additionalData: [
                        "data": "\(data.count)",
                        "channel": "\(channel)",
                        "bitsPerSample": "\(bitsPerSample)",
                        "avgVolume": "\(avgVolume)",
                        "maxVolume": "\(maxVolume)",
                        "minVolume": "\(minVolume)"
                    ]
                )
                assertionFailure()
                return 0
            }

            // 添加范围检测
            if value < 0 { return 0 }
            if value > 100 { return 100 }
            return value
        }

        return Decibel(
            maxValue: checkIsValid(maxValue),
            minValue: checkIsValid(minValue),
            avgValue: checkIsValid(avgValue)
        )
    }
}
