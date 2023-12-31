//
//  OPMemoryInfoAllocatorRegister.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/10.
//

import Foundation

/// 负责将所有声明在EEMicroAppSDK中的Allocator注册到OPLeakUploader中
/// 由于某些信息的采集依赖TTMicroAppSDK，所以这些allocator只能在EMA中声明，再在启动时统一注入到OPSDK中
@objcMembers
public final class OPMemoryInfoAllocatorRegister: NSObject {

    /// 是否已经进行过了注册(仅能注册一次)
    static var allocatorRegistered = false

    public static func registerAllocators() {
        guard !allocatorRegistered else {
            allocatorRegistered = true
            return
        }
        OPMemoryInfoUploader.registerForAllEvent(allocator: OPGadgetContextAllocator())
        OPMemoryInfoUploader.registerForAllEvent(allocator: OPPerformanceInfoAllocator())
        OPMemoryInfoUploader.registerForAllEvent(allocator: OPExtraGadgetContextAllocator())
        OPMemoryInfoUploader.registerForAllEvent(allocator: OPSpecifiedObjectInfoAllocator())
    }

}
