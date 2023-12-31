//
//  SetAppCpuManagerStatusRequest.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2022/11/22.
//

import Foundation
import RustPB

/// 会中妙享，上报CPU使用率
/// - setAppCpuManagerStatus = 800107
/// - Tool_V1_SetAppCpuManagerStatusRequest
public struct SetAppCpuManagerStatusRequest {
    public static let command: NetworkCommand = .rust(.setAppCpuManagerStatus)

    public init(iosCpuUsage: iOSCpuUsage,
                logicCoreCount: Int32,
                isCharging: Bool,
                magicShareStatus: MagicShareStatus) {
        self.iosCpu = iosCpuUsage
        self.logicCoreCount = logicCoreCount
        self.isCharging = isCharging
        self.magicShareStatus = magicShareStatus
    }

    /// iOS-CPU使用率
    public var iosCpu: iOSCpuUsage

    /// CPU逻辑核数量
    public var logicCoreCount: Int32

    /// 是否在充电
    public var isCharging: Bool

    /// 便于以后扩展使用，可添加其他业务状态。
    public var magicShareStatus: MagicShareStatus

    // swiftlint:disable type_name
    /// nonunitary_cpu_usage = system_cpu_usage * logic_core_count
    public struct iOSCpuUsage {

        /// 归一化后的 AppCPU，为百分比乘100后取整，如20%则上报20
        public var appCpuUsage: Int32

        /// 归一化后的 SysCPU，单位转换规则同上
        public var systemCpuUsage: Int32

        public init(appCpuUsage: Int32, systemCpuUsage: Int32) {
            self.appCpuUsage = appCpuUsage
            self.systemCpuUsage = systemCpuUsage
        }
    }
    // swiftlint:enable type_name

    public enum MagicShareStatus: Int {
        case frontStartup = 1 // 前台启动
        case frontRoll // 预留，文档滚动中，5.28无此类型
        case frontStandBy // 前台加载完成，非小窗
        case smallWindows // 前台小窗
        case close // 关闭
    }
}

extension SetAppCpuManagerStatusRequest: RustRequest {
    typealias ProtobufType = Tool_V1_SetAppCpuManagerStatusRequest

    // 上报CPU使用率 https://bytedance.feishu.cn/docx/OLYNduHRGoJHC9xKjO5cgDuAnxO
    typealias PBiOSCpuUsage = Tool_V1_SetAppCpuManagerStatusRequest.iOSCpuUsage
    typealias PBMagicShareStatus = Tool_V1_SetAppCpuManagerStatusRequest.MagicShareStatus

    func toProtobuf() throws -> Tool_V1_SetAppCpuManagerStatusRequest {
        var iosCpuUsage = PBiOSCpuUsage()
        iosCpuUsage.systemCpuUsage = iosCpu.systemCpuUsage
        iosCpuUsage.appCpuUsage = iosCpu.appCpuUsage
        var request = ProtobufType()
        request.iosCpu = iosCpuUsage
        request.logicCoreCount = logicCoreCount
        request.isCharging = isCharging
        request.magicShareStatus = PBMagicShareStatus(rawValue: magicShareStatus.rawValue) ?? .close
        return request
    }
}
