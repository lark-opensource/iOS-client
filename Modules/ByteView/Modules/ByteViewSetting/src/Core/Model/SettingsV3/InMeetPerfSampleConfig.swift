//
//  InMeetPerfSampleConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/20.
//

// 忽略魔法数检查
// nolint: magic number
import Foundation

/// 会中性能埋点配置：线程 CPU 、各核心 CPU、电池
// disable-lint: magic number
public struct InMeetPerfSampleConfig {
    /// 线程 CPU 采样配置
    public struct ThreadCPU: Decodable {
        public var enabled: Bool
        public var topN: Int = 0
        // 采集时间间隔，单位秒
        public var period: Int64
        public var threshold: Float = 0.0
        public var enableBizHook: Bool = false

        #if DEBUG
        static let `default` = ThreadCPU(enabled: true, topN: 5, period: 10, threshold: 0.01)
        #else
        static let `default` = ThreadCPU(enabled: false, topN: 5, period: 10, threshold: 0.01)
        #endif
    }

    /// 通用采样配置
    public struct General: Decodable {
        public var enabled: Bool
        // 采集时间间隔，单位秒
        public var period: Int64

        static let `default` = General(enabled: false, period: 10)
        static let battery = General(enabled: true, period: 60)
        static let coreCPU = General(enabled: true, period: 2)
    }

    public struct PeakConfig: Decodable {
        /// 开启采集
        public var enabled: Bool
        /// 高负载 CPU 值，计算所有核心的平均使用率
        public var value: Float
        #if DEBUG
        static let `default` = PeakConfig(enabled: true, value: 0.4)
        #else
        static let `default` = PeakConfig(enabled: false, value: 0)
        #endif
    }

    public struct PrelongConfig: Decodable {
        /// 开启采集
        public var enabled: Bool
        // 采集 TopN 线程时间间隔，单位秒
        public var period: Int64
        /// 高负载 CPU 值，计算所有相同核心的平均使用率
        public var value: Float
        /// 持续时间，单位秒
        public var threshold: Int64

        #if DEBUG
        static let `default` = PrelongConfig(enabled: true, period: 2, value: 0.4, threshold: 10)
        #else
        static let `default` = PrelongConfig(enabled: false, period: 2, value: 0, threshold: 60)
        #endif

        /// 是否有效配置
        public var isValid: Bool {
            return enabled && period > 0 && value > 0 && threshold > 0
        }
    }

    /// 各核高负载配置
    public struct CoreHighLoad: Decodable {
        /// 峰值
        public var peak: PeakConfig
        /// 持久
        public var prolong: PrelongConfig

        static let `default` = CoreHighLoad(peak: .default, prolong: .default)
    }

    /// 高负载模式
    public struct HighLoad: Decodable {
        /// p core 起始位置，负数、0 或大于当前核数，均无效
        public var perfCoreStartIdx: Int
        public var pCore: CoreHighLoad
        public var eCore: CoreHighLoad

        #if DEBUG
        static let `default` = HighLoad(perfCoreStartIdx: 4, pCore: .default, eCore: .default)
        #else
        static let `default` = HighLoad(perfCoreStartIdx: 0, pCore: .default, eCore: .default)
        #endif
        init(perfCoreStartIdx: Int, pCore: CoreHighLoad, eCore: CoreHighLoad) {
            self.perfCoreStartIdx = perfCoreStartIdx
            self.pCore = pCore
            self.eCore = eCore
        }

        enum CodingKeys: String, CodingKey {
            case perfCoreStartIdx
            case pCore
            case eCore
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            do {
                perfCoreStartIdx = try values.decode(Int.self, forKey: .perfCoreStartIdx)
            } catch {
                perfCoreStartIdx = 0
            }

            do {
                pCore = try values.decode(CoreHighLoad.self, forKey: .pCore)
            } catch {
                pCore = .default
            }

            do {
                eCore = try values.decode(CoreHighLoad.self, forKey: .eCore)
            } catch {
                eCore = .default
            }
        }
    }

    public var threadCPU: ThreadCPU
    public var coreCPU: General
    /// 新 core cpu 采集，直接上报原始数据
    public var rawCoreCPU: General
    public var battery: General
    /// 采样上报周期，单位秒
    public var reportPeriod: Int64
    public var enabled: Bool
    /// 高负载
    public var highLoad: HighLoad

    public var isThreadBizMonitorEnabled: Bool {
        self.threadCPU.enabled && self.threadCPU.enableBizHook
    }

    init(enabled: Bool,
         threadCPU: ThreadCPU,
         coreCPU: General,
         rawCoreCPU: General,
         battery: General,
         reportPeriod: Int64,
         highLoad: HighLoad)
    {
        self.enabled = enabled
        self.threadCPU = threadCPU
        self.coreCPU = coreCPU
        self.rawCoreCPU = rawCoreCPU
        self.battery = battery
        self.reportPeriod = reportPeriod
        self.highLoad = highLoad
    }

#if DEBUG
    static let `default` = InMeetPerfSampleConfig(
        enabled: true,
        threadCPU: .default,
        coreCPU: .coreCPU,
        rawCoreCPU: .coreCPU,
        battery: .battery,
        reportPeriod: 60,
        highLoad: .default
    )
#else
    static let `default` = InMeetPerfSampleConfig(
        enabled: false,
        threadCPU: .default,
        coreCPU: .coreCPU,
        rawCoreCPU: .coreCPU,
        battery: .battery,
        reportPeriod: 60,
        highLoad: .default
    )
#endif
}

extension InMeetPerfSampleConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case enabled
        case threadCpu
        case coreCpu
        case rawCoreCpu
        case battery
        case reportPeriod
        case highLoad
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        threadCPU = try values.decode(ThreadCPU.self, forKey: .threadCpu)
        coreCPU = try values.decode(General.self, forKey: .coreCpu)
        battery = try values.decode(General.self, forKey: .battery)
        reportPeriod = try values.decode(Int64.self, forKey: .reportPeriod)
        do {
            rawCoreCPU = try values.decode(General.self, forKey: .rawCoreCpu)
        } catch {
            rawCoreCPU = .coreCPU
        }
        do {
            highLoad = try values.decode(HighLoad.self, forKey: .highLoad)
        } catch {
            highLoad = .default
        }
    }
}
