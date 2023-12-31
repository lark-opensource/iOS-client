//
//  MultiResolutionConfig.swift
//  ByteView
//
//  Created by liujianlong on 2022/3/30.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

public struct MultiResPublishResolution: Codable {
    public var res: Int
    public var fps: Int
    public var maxBitrate: Int
    public var maxBitrate1To1: Int

    public init(res: Int, fps: Int, maxBitrate: Int, maxBitrate1To1: Int) {
        self.res = res
        self.fps = fps
        self.maxBitrate = maxBitrate
        self.maxBitrate1To1 = maxBitrate1To1
    }
}

extension MultiResPublishResolution: CustomStringConvertible {
    public var description: String {
        "res: \(self.res), fps: \(self.fps), bitrate: \(self.maxBitrate1To1)"
    }
}

public struct MultiResSubscribeResolution: Equatable, Decodable {
    public var res: Int
    public var fps: Int
    @DefaultDecodable.IntMinus1
    public var goodRes: Int
    @DefaultDecodable.IntMinus1
    public var goodFps: Int
    @DefaultDecodable.IntMinus1
    public var badRes: Int
    @DefaultDecodable.IntMinus1
    public var badFps: Int

    public init(res: Int, fps: Int, goodRes: Int, goodFps: Int, badRes: Int, badFps: Int) {
        self.res = res
        self.fps = fps
        self.goodRes = goodRes
        self.goodFps = goodFps
        self.badRes = badRes
        self.badFps = badFps
    }
}

extension MultiResSubscribeResolution: CustomStringConvertible {
    public var description: String {
        "\(self.res)@\(self.fps), good: \(self.goodRes)@\(self.goodFps), bad: \(self.badRes)@\(self.badFps)"
    }
}

public struct MultiResPadGallerySubscribeRule: Decodable {
    public var max: Int
    public var conf: MultiResSubscribeResolution
    @DefaultDecodable.Int0
    public var roomOrSip: Int
}

public struct MultiResPublishConfig: Decodable {
    public var channel: [MultiResPublishResolution]
    public var main: [MultiResPublishResolution]
    public var channelHigh: [MultiResPublishResolution]?
    public var mainHigh: [MultiResPublishResolution]?
}

public struct MultiResPhoneSubscribeConfig: Decodable {
    public var stageGuest: [MultiResPadGallerySubscribeRule]
    // 舞台模式横屏共享场景下，嘉宾订阅规则
    public var stageShareGuest: [MultiResPadGallerySubscribeRule]

    public var gridFull: MultiResSubscribeResolution
    public var gridHalf: MultiResSubscribeResolution
    public var gridHalfSip: MultiResSubscribeResolution
    public var gridQuarter: MultiResSubscribeResolution
    public var gridQuarterSip: MultiResSubscribeResolution
    public var gridFloat: MultiResSubscribeResolution
    public var gridFloatSip: MultiResSubscribeResolution

    public var gridShareScreen: MultiResSubscribeResolution
    public var gridShareRow: MultiResSubscribeResolution
    public var gridShareRowSip: MultiResSubscribeResolution

    public var newGridFull: MultiResSubscribeResolution
    public var newGridHalf: MultiResSubscribeResolution
    public var newGridHalfSip: MultiResSubscribeResolution
    public var newGrid6: MultiResSubscribeResolution
    public var newGrid6Sip: MultiResSubscribeResolution

    enum CodingKeys: String, CodingKey, CaseIterable {
        case stageGuest
        case stageShareGuest
        case gridFull
        case gridHalf
        case gridHalfSip
        case gridQuarter
        case gridQuarterSip
        case gridFloat
        case gridFloatSip

        case gridShareScreen
        case gridShareRow
        case gridShareRowSip

        case newGridFull
        case newGridHalf
        case newGridHalfSip
        case newGrid6
        case newGrid6Sip
    }

    static let `default` = MultiResolutionConfig.default.phone.subscribe
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stageGuest = (try? container.decode([MultiResPadGallerySubscribeRule].self, forKey: .stageGuest)) ?? Self.default.stageGuest
        self.stageShareGuest = (try? container.decode([MultiResPadGallerySubscribeRule].self, forKey: .stageShareGuest)) ?? Self.default.stageShareGuest

        self.gridFull = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFull)) ?? Self.default.gridFull
        self.gridHalf = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridHalf)) ?? Self.default.gridHalf
        self.gridHalfSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridHalfSip)) ?? Self.default.gridHalfSip
        self.gridQuarter = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridQuarter)) ?? Self.default.gridQuarter
        self.gridQuarterSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridQuarterSip)) ?? Self.default.gridQuarterSip
        self.gridFloat = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFloat)) ?? Self.default.gridFloat
        self.gridFloatSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFloatSip)) ?? Self.default.gridFloatSip
        self.gridShareScreen = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareScreen)) ?? Self.default.gridShareScreen
        self.gridShareRow = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareRow)) ?? Self.default.gridShareRow
        self.gridShareRowSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareRowSip)) ?? Self.default.gridShareRowSip

        self.newGridFull = (try? container.decode(MultiResSubscribeResolution.self, forKey: .newGridFull)) ?? Self.default.newGridFull
        self.newGridHalf = (try? container.decode(MultiResSubscribeResolution.self, forKey: .newGridHalf)) ?? Self.default.newGridHalf
        self.newGridHalfSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .newGridHalfSip)) ?? Self.default.newGridHalfSip
        self.newGrid6 = (try? container.decode(MultiResSubscribeResolution.self, forKey: .newGrid6)) ?? Self.default.newGrid6
        self.newGrid6Sip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .newGrid6Sip)) ?? Self.default.newGrid6Sip

        let missingKeys = CodingKeys.allCases.filter({ !container.allKeys.contains($0) })
        if !missingKeys.isEmpty {
            Logger.network.error("MultiResConfig MissingKeys: \(missingKeys)")
        }
    }
}

public struct MultiResPadSubscribeConfig: Decodable {
    public var stageGuest: [MultiResPadGallerySubscribeRule]
    // 舞台模式共享场景下，嘉宾订阅规则
    public var stageShareGuest: [MultiResPadGallerySubscribeRule]

    // Pad 宫格模式订阅规则
    public var gallery: [MultiResPadGallerySubscribeRule]

    public var gridFull: MultiResSubscribeResolution
    public var gridHalf: MultiResSubscribeResolution
    public var gridHalfSip: MultiResSubscribeResolution
    public var gridQuarter: MultiResSubscribeResolution
    public var gridQuarterSip: MultiResSubscribeResolution
    public var gridFloat: MultiResSubscribeResolution
    public var gridFloatSip: MultiResSubscribeResolution

    public var gridShareScreen: MultiResSubscribeResolution
    public var gridShareRow: MultiResSubscribeResolution
    public var gridShareRowSip: MultiResSubscribeResolution

    enum CodingKeys: String, CodingKey, CaseIterable {
        case stageGuest
        case stageShareGuest
        case gallery
        case gridFull
        case gridHalf
        case gridHalfSip
        case gridQuarter
        case gridQuarterSip
        case gridFloat
        case gridFloatSip
        case gridShareScreen
        case gridShareRow
        case gridShareRowSip
    }

    static let `default` = MultiResolutionConfig.default.pad.subscribe
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stageGuest = (try? container.decode([MultiResPadGallerySubscribeRule].self, forKey: .stageGuest)) ?? Self.default.stageGuest
        self.stageShareGuest = (try? container.decode([MultiResPadGallerySubscribeRule].self, forKey: .stageShareGuest)) ?? Self.default.stageShareGuest
        self.gallery = (try? container.decode([MultiResPadGallerySubscribeRule].self, forKey: .gallery)) ?? Self.default.gallery
        self.gridFull = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFull)) ?? Self.default.gridFull
        self.gridHalf = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridHalf)) ?? Self.default.gridHalf
        self.gridHalfSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridHalfSip)) ?? Self.default.gridHalfSip
        self.gridQuarter = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridQuarter)) ?? Self.default.gridQuarter
        self.gridQuarterSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridQuarterSip)) ?? Self.default.gridQuarterSip
        self.gridFloat = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFloat)) ?? Self.default.gridFloat
        self.gridFloatSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridFloatSip)) ?? Self.default.gridFloatSip
        self.gridShareScreen = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareScreen)) ?? Self.default.gridShareScreen
        self.gridShareRow = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareRow)) ?? Self.default.gridShareRow
        self.gridShareRowSip = (try? container.decode(MultiResSubscribeResolution.self, forKey: .gridShareRowSip)) ?? Self.default.gridShareRowSip
        let missingKeys = CodingKeys.allCases.filter({ !container.allKeys.contains($0) })
        if !missingKeys.isEmpty {
            Logger.network.error("MultiResConfig MissingKeys: \(missingKeys)")
        }
    }
}

public struct DeprecatedSimulcastConfig: Decodable {
    public var phone: MultiResPhoneSubscribeConfig
    public var pad: MultiResPadSubscribeConfig
}

public struct MultiResolutionConfig: Decodable {
    public var phone: MultiResolutionPhoneConfig
    public var pad: MultiResolutionPadConfig
    public var viewSizeDebounce: TimeInterval

    @DefaultDecodable.Float1
    public var viewSizeScale: Float

    // swiftlint:disable force_try
    static let defaultHighEnd: MultiResolutionConfig = {
        let url = Bundle.settingResources.url(forResource: "simulcast_high_end", withExtension: "json")!
        // lint:disable:next lark_storage_check
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(MultiResolutionConfig.self, from: data)
    }()

    static let defaultMidEnd: MultiResolutionConfig = {
        let url = Bundle.settingResources.url(forResource: "simulcast_mid_end", withExtension: "json")!
        // lint:disable:next lark_storage_check
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(MultiResolutionConfig.self, from: data)
    }()

    static let defaultLowEnd: MultiResolutionConfig = {
        let url = Bundle.settingResources.url(forResource: "simulcast_low_end", withExtension: "json")!
        // lint:disable:next lark_storage_check
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(MultiResolutionConfig.self, from: data)
    }()
    // swiftlint:enable force_try

    static var `default`: MultiResolutionConfig = {
        if Display.pad {
            if DeviceUtil.modelNumber >= DeviceModelNumber(major: 8, minor: 1) {
                return .defaultHighEnd
            } else if DeviceUtil.modelNumber >= DeviceModelNumber(major: 7, minor: 1) {
                return .defaultMidEnd
            } else {
                return .defaultLowEnd
            }
        } else {
            // nolint-next-line: magic number
            if DeviceUtil.modelNumber >= DeviceModelNumber(major: 12, minor: 1) {
                return .defaultHighEnd
            } else if DeviceUtil.modelNumber >= DeviceModelNumber(major: 10, minor: 1) {
                return .defaultMidEnd
            } else {
                return .defaultLowEnd
            }
        }
    }()
}

extension MultiResolutionConfig {
    var isHighEndDevice: Bool {
        if Display.pad {
            return pad.publish.channelHigh != nil
        } else {
            return phone.publish.channelHigh != nil
        }
    }
}

public struct EffectFrameRateConfig: Decodable {
    public var virtualBackgroundFps: Int
    public var animojiFps: Int
    public var filterFps: Int
    public var beautyFps: Int
    public var mixFilterBeautyFps: Int
    public var mixOtherFps: Int
}

public struct MultiResolutionPhoneConfig: Decodable {
    public var publish: MultiResPublishConfig
    public var subscribe: MultiResPhoneSubscribeConfig
    public var effectFps: EffectFrameRateConfig
}

public struct MultiResolutionPadConfig: Decodable {
    public var publish: MultiResPublishConfig
    public var subscribe: MultiResPadSubscribeConfig
    public var effectFps: EffectFrameRateConfig
}
