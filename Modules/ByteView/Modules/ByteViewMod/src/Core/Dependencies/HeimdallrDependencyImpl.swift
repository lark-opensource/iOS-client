//
//  HeimdallrDependencyImpl.swift
//  ByteViewMod
//
//  Created by Tobb Huang on 2023/7/10.
//

import Foundation
import ByteView
import Heimdallr

final class HeimdallrDependencyImpl: HeimdallrDependency {
    func setCustomContextValue(_ value: Any?, forKey key: String?) {
        HMDInjectedInfo.default().setCustomContextValue(value, forKey: key)
    }

    func setCustomFilterValue(_ value: Any?, forKey key: String?) {
        HMDInjectedInfo.default().setCustomFilterValue(value, forKey: key)
    }

    func removeCustomContextKey(_ key: String?) {
        HMDInjectedInfo.default().removeCustomContextKey(key)
    }

    func removeCustomFilterKey(_ key: String?) {
        HMDInjectedInfo.default().removeCustomFilterKey(key)
    }
}
