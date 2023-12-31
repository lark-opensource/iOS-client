//
//  SwiftKVO.swift
//  LarkCrashSanitizer
//
//  Created by SolaWing on 2020/1/13.
//

import Foundation

@objc(WMFSwiftKVOCrashWorkaround)
public final class SwiftKVOCrashWorkaround: NSObject {
    @objc dynamic var observeMe: String = ""

    @objc
    public func performWorkaround() {
        let observation = observe(\SwiftKVOCrashWorkaround.observeMe, options: [.new]) { (observee, _) in
            fatalError("Shouldn't have changed: \(observee)")
        }
        observation.invalidate()
    }
}
