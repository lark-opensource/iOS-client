//
//  DefaultTrackDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/7/3.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteWebImage
#if canImport(Heimdallr)
import Heimdallr
#endif

final class TrackDependencyImpl: TrackDependency {
    func trackUserException(_ exceptionType: String) {
        #if LarkMod && canImport(Heimdallr)
        HMDUserExceptionTracker.shared().trackAllThreadsLogExceptionType(exceptionType, skippedDepth: 0, customParams: nil, filters: nil, callback: { _ in })
        #else
        Logger.monitor.info("trackUserException: \(exceptionType)")
        #endif
    }

    func trackAvatar() {
        let memorySize = LarkImageService.shared.originCache.memoryCache.totalCost
        // nolint-next-line: magic number
        let reportSize = Float(memorySize) / 1048576
        VCTracker.post(name: .vc_meeting_avatar_memory_size_dev, params: ["memory_size": reportSize])
    }

    func getCurrentMemoryUsage() -> MemoryUsage? {
        #if canImport(Heimdallr)
        let bytes = hmd_getMemoryBytes()
        return MemoryUsage(appUsageBytes: bytes.appMemory, systemUsageBytes: bytes.usedMemory, availableUsageBytes: bytes.availabelMemory)
        #else
        return nil
        #endif
    }

    func dumpMemoryGraph() {
        #if canImport(Heimdallr)
        if #available(iOS 12.0, *) {
            HMDMemoryGraphGenerator.shared().manualGenerateImmediateUpload(true, finish: nil)
        }
        #endif
    }
}
