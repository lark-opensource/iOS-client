//
//  AggregateDefine.swift
//  ByteViewTracker
//
//  Created by shin on 2023/4/10.
//

import Foundation

/// 聚合埋点事件
public struct AggSceneEvent {
    /// 相同场景处理方式
    public enum OptMode {
        /// 互斥，结束上一个未结束的场景（也可手动结束）
        case froze
        /// 计数（需主动结束场景）
        case count
        /// 共存（需主动的结束场景）
        case coexist
    }

    /// 场景原始采样数据
    public struct SampleMeta {
        /// 触发采集的配置
        public let config: [String: Any]
        /// 采集到的原始数值
        public let value: Float

        public init(config: [String: Any], value: Float) {
            self.config = config
            self.value = value
        }
    }

    /// 开关状态
    public enum SwitchState: String {
        /// 开
        case on
        /// 关
        case off
    }

    /// 增量的聚合埋点场景
    /// 开关类使用 Bool 类型，埋点值为 on/off，
    /// 非开关类使用 String 类型，埋点值为对应的 value
    public enum Scene: Hashable {
        /// app 状态，foreground/background
        case appState(String)
        /// 窗口状态：mini/full
        case windowState(String)
        /// 温度，nominal/fair/serious/critical
        case thermal(String)
        /// 低电量模式，on/off
        case lowPowerMode(SwitchState)
        /// 麦克风，on/off
        case microphone(SwitchState)
        /// 摄像头，on: front/back；off: off
        case camera(SwitchState, String?)
        /// 字幕，on/off
        case subtitle(SwitchState)
        /// 画中画，on/off
        case pip(SwitchState)
        /// 节能模式，on/off
        case ecoMode(SwitchState)
        /// 特效，face/virtual_bkg/filter/emoji
        case effect(String)
        /// 语音模式，on/off
        case voiceMode(SwitchState)
        /// 白板，on/off
        case whiteboard(SwitchState)
        /// 妙享，on/off
        case magicShare(SwitchState)
        /// magic 跟随细分场景，none/sharing/following/free;
        /// 区分于 magicShare 是开关维度的，跟随是更细的内部场景。
        /// 先独立于 ms 开关场景，作为一个维度的参考。
        case magicShareFollow(String)
        /// 他人共享屏幕，on/off
        case sharedScreen(SwitchState)
        /// 自己共享屏幕，on/off
        case selfShareScreen(SwitchState)
        /// 投屏转妙享，on/off
        case shareScreenToFollow(SwitchState)
        /// 面试空间，on/off
        case webSpace(SwitchState)
        /// 纪要，on/off
        case notes(SwitchState)
        /// 网络类型，4g/wifi...
        case networkType(String)
        /// 网络质量，bad/good...
        case networkQuality(String)
        /// 蜂窝网络基站切换次数，number
        case cellularSwitch
        /// 设备压力状态，nominal/fair/serious/critical/shutdown.
        /// https://developer.apple.com/documentation/avfoundation/avcapturedevice/systempressurestate
        case systemPressure(String)
        /// 高负载模式
        case highLoad(String)

        var stateAndExtra: (String, String?) {
            var state: String
            var extra: String?
            switch self {
            case .appState(let v), .windowState(let v),
                 .thermal(let v), .effect(let v),
                 .networkType(let v), .networkQuality(let v),
                 .systemPressure(let v), .highLoad(let v),
                 .magicShareFollow(let v):
                state = v
            case .lowPowerMode(let v), .microphone(let v),
                 .subtitle(let v), .pip(let v),
                 .ecoMode(let v), .voiceMode(let v),
                 .magicShare(let v), .whiteboard(let v),
                 .sharedScreen(let v), .selfShareScreen(let v),
                 .shareScreenToFollow(let v), .webSpace(let v),
                 .notes(let v):
                state = v.rawValue
            case .camera(let v, let e):
                state = v.rawValue
                extra = e
            case .cellularSwitch:
                state = ""
            }

            return (state, extra)
        }

        /// scene_events 字段场景 key
        var eventKey: String {
            switch self {
            case .appState: return "appState"
            case .windowState: return "windowState"
            case .thermal: return "thermal"
            case .lowPowerMode: return "lowPowerMode"
            case .microphone: return "microphone"
            case .camera: return "camera"
            case .subtitle: return "subtitle"
            case .pip: return "pip"
            case .ecoMode: return "ecoMode"
            case .effect: return "effect"
            case .voiceMode: return "voiceMode"
            case .whiteboard: return "whiteboard"
            case .magicShare: return "magicShare"
            case .magicShareFollow: return "magicShareFollow"
            case .sharedScreen: return "sharedScreen"
            case .selfShareScreen: return "selfShareScreen"
            case .shareScreenToFollow: return "shareScreenToFollow"
            case .webSpace: return "webSpace"
            case .notes: return "notes"
            case .networkType: return "networkType"
            case .networkQuality: return "networkQuality"
            case .cellularSwitch: return "cellularSwitch"
            case .systemPressure: return "systemPressure"
            case .highLoad: return "highLoad"
            }
        }

        var optMode: OptMode {
            var mode: OptMode
            switch self {
            case .effect:
                mode = .coexist
            case .cellularSwitch:
                mode = .count
            default:
                mode = .froze
            }
            return mode
        }

        /// agg_scenes 字段场景 key
        var aggKey: String {
            let aggkey: String
            let eventKey = self.eventKey
            let (state, extra) = self.stateAndExtra
            switch self {
            // String 类型的值
            case .appState, .windowState,
                 .effect, .thermal,
                 .systemPressure, .networkType,
                 .networkQuality, .highLoad,
                 .magicShareFollow:
                aggkey = "\(eventKey)_\(state)"
            // 摄像头（SwitchMode，String?）
            case .camera:
                aggkey = "\(eventKey)_\(extra ?? SwitchState.off.rawValue)"
            // 电池
            case .cellularSwitch:
                aggkey = eventKey
            // Bool 类型的值
            case .lowPowerMode, .webSpace,
                 .microphone, .subtitle,
                 .pip, .ecoMode,
                 .voiceMode, .whiteboard,
                 .magicShare, .sharedScreen,
                 .selfShareScreen, .shareScreenToFollow,
                 .notes:
                aggkey = "\(eventKey)_\(state)"
            }
            return aggkey
        }
    }

    /// 场景
    let scene: Scene
    /// 进入场景时间，ms
    private(set) var entryTs: Int64
    /// 采样原始数据
    let sampleMeta: SampleMeta?
    /// 持续时长，ms
    private(set) var duration: Int64 = 0
    /// 触发次数
    private(set) var counter: Int = 0
    /// 场景已经结束
    private(set) var frozen = false
    /// 上报次数
    private(set) var reportedCnt: Int = 0
    /// 处理方式
    let optMode: OptMode

    public init(scene: AggSceneEvent.Scene, entryTs: Int64, sampleMeta: SampleMeta? = nil) {
        self.scene = scene
        self.entryTs = entryTs
        self.sampleMeta = sampleMeta
        self.counter = 1
        self.optMode = scene.optMode
    }

    /// 更新事件
    public mutating func update(at ts: Int64) {
        guard !frozen, ts > entryTs else { return }
        self.duration = ts - entryTs
    }

    /// 事件结束被冻结
    public mutating func froze(at ts: Int64) {
        guard !frozen, ts > entryTs else { return }
        self.duration = ts - entryTs
        self.frozen = true
        // 结束时，如果上报过的，计数置为 1，因为结束时改变了
        if reportedCnt >= 1, counter == 0 {
            self.counter = 1
        }
    }

    /// 触发计数加 1
    public mutating func increase() {
        guard !frozen else { return }
        self.counter += 1
    }

    /// 上报事件完成
    public mutating func reportFinished(at ts: Int64) {
        guard !frozen else { return }
        // 每次上报埋点时，重置 entryTs，方便下次继续计算 duration
        self.entryTs = ts
        // 上报后计数清零，后续如果没有再次触发，表示未改变
        if reportedCnt > 0 {
            self.counter = 0
        }
        self.reportedCnt += 1
    }

    public var trackKV: [String: Any] {
        let (state, extra) = scene.stateAndExtra
        let reportState: String
        switch optMode {
        case .count:
            reportState = "\(counter)"
        default:
            reportState = state
        }

        var ret: [String: Any] = [:]
        ret["scene"] = scene.eventKey
        ret["state"] = reportState
        ret["ts"] = entryTs
        ret["dur"] = duration
        if let extra {
            ret["extra"] = extra
        }
        if let sampleMeta, !sampleMeta.config.isEmpty {
            var meta = sampleMeta.config
            meta["avg"] = sampleMeta.value
            ret["meta"] = AggSceneEvent.dictToString(meta)
        }
        return ret
    }
}

extension AggSceneEvent: Hashable {
    public static func == (lhs: AggSceneEvent, rhs: AggSceneEvent) -> Bool {
        return lhs.scene == rhs.scene && lhs.entryTs == rhs.entryTs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(scene)
        hasher.combine(entryTs)
    }
}

extension AggSceneEvent {
    public static func dictToString(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return str
    }
}

public struct AggSceneEventChange {
    public var count: Int = 0
    public var duration: Int64 = 0
    public var config: [String: Any]?
    public var values: [Float]?

    public mutating func appendValue(_ value: Float) {
        if values == nil {
            values = [value]
        } else {
            values?.append(value)
        }
    }

    public var trackKV: [String: Any] {
        var kv: [String: Any] = [
            "cnt": count,
            "dur": duration
        ]
        if let config, let values, !values.isEmpty {
            var meta = config
            let values_ = values.sorted()
            let sum = values_.reduce(0.0) { $0 + $1 }
            meta["max"] = values_.last ?? 0.0
            meta["avg"] = sum / Float(values_.count)
            kv["meta"] = AggSceneEvent.dictToString(meta)
        }
        return kv
    }
}

/// 聚合埋点事件名
public enum AggregateEventName: String, Hashable {
    /// CPU 采集
    case vc_perf_cpu_state_mobile_dev
    /// CPU 核心采集
    case vc_perf_cpu_cores_state_dev
    /// 电量
    case vc_power_remain_one_minute_dev
}

/// 聚合埋点子事件
public struct AggregateSubEvent {
    let name: AggregateEventName
    let params: TrackParams
    let ntpTime: Int64

    public init(name: AggregateEventName,
                params: TrackParams = .init(),
                time: Int64? = nil)
    {
        self.name = name
        self.params = params
        if let time = time {
            self.ntpTime = time
        } else {
            self.ntpTime = TrackCommonParams.clientNtpTime
        }
    }
}

/// cpu 各核心的连续采样值
public struct CPUCoreRecord {
    /// core index
    let index: Int
    /// 采样值
    let values: [Float]
    /// 是否是 P 核
    let isPCore: Bool

    public init(index: Int, values: [Float], isPCore: Bool) {
        self.index = index
        self.values = values
        self.isPCore = isPCore
    }
}

/// cpu 不同类型核心的聚合采样值
public struct CpuCoresAggRecord {
    let coreCount: Int
    /// 采样值数量
    let sampleCount: Int
    let avg: Float
    let max: Float
    let min: Float
    let p50: Float
    let p75: Float
    let p95: Float

    public init(coreCount: Int, sampleCount: Int, avg: Float, max: Float, min: Float, p50: Float, p75: Float, p95: Float) {
        self.coreCount = coreCount
        self.sampleCount = sampleCount
        self.avg = avg
        self.max = max
        self.min = min
        self.p50 = p50
        self.p75 = p75
        self.p95 = p95
    }

    var trackKV: [String: Any] {
        var kv = [String: Any]()
        kv["cnt"] = sampleCount
        kv["core_cnt"] = coreCount
        kv["avg"] = avg
        kv["max"] = max
        kv["min"] = min
        kv["p50"] = p50
        kv["p75"] = p75
        kv["p95"] = p95
        return kv
    }
}

public struct AggregateCoreCPUEvent {
    /// 采样开始时间
    let sampleTs: Int64
    /// 采样周期
    let period: Int64
    /// p core 起始顺序
    let pCoreStartIdx: Int
    /// 采样值
    let records: [CPUCoreRecord]
    /// P 核的聚合数据
    let pcores: CpuCoresAggRecord
    /// E 核的聚合数据
    let ecores: CpuCoresAggRecord

    var trackKV: [String: Any] {
        var kv: [String: Any] = [:]
        kv["ts"] = sampleTs
        kv["period"] = period
        kv["pcore_idx"] = pCoreStartIdx
        var values: [String: Any] = [:]
        for record in records {
            let k = "\(record.index)"
            values[k] = record.values
        }
        kv["values"] = values
        kv["pcores"] = pcores.trackKV
        kv["ecores"] = ecores.trackKV
        return kv
    }

    public init(sampleTs: Int64,
                period: Int64,
                pCoreStartIdx: Int,
                records: [CPUCoreRecord],
                pcores: CpuCoresAggRecord,
                ecores: CpuCoresAggRecord)
    {
        self.sampleTs = sampleTs
        self.period = period
        self.pCoreStartIdx = pCoreStartIdx
        self.records = records
        self.pcores = pcores
        self.ecores = ecores
    }
}

public struct AggregateEvent {
    let ntpTime: Int64
    let sampleSeq: Int
    let coreCPUs: [AggregateSubEvent]
    let rawCoreCPUs: AggregateCoreCPUEvent?
    let threadCPUs: [AggregateSubEvent]
    let battery: TrackParams

    public init(ntpTime: Int64,
                sampleSeq: Int,
                coreCPUs: [AggregateSubEvent],
                rawCoreCPUs: AggregateCoreCPUEvent?,
                threadCPUs: [AggregateSubEvent],
                battery: TrackParams)
    {
        self.ntpTime = ntpTime
        self.sampleSeq = sampleSeq
        self.coreCPUs = coreCPUs
        self.rawCoreCPUs = rawCoreCPUs
        self.threadCPUs = threadCPUs
        self.battery = battery
    }

    var params: [String: Any] {
        let coreCPUKey: AggregateEventName = .vc_perf_cpu_cores_state_dev
        let threadCPUKey: AggregateEventName = .vc_perf_cpu_state_mobile_dev
        let batteryKey: AggregateEventName = .vc_power_remain_one_minute_dev
        let rawCoreCPUsParam = rawCoreCPUs?.trackKV ?? [:]
        return [
            "ntp_time": ntpTime,
            "sample_seq": sampleSeq,
            coreCPUKey.rawValue: [
                "cores": coreCPUs.map { $0.params.rawValue },
                "raw": rawCoreCPUsParam
            ] as [String: Any],
            threadCPUKey.rawValue: [
                "raw": threadCPUs.map { $0.params.rawValue }
            ],
            batteryKey.rawValue: battery.rawValue
        ]
    }
}
