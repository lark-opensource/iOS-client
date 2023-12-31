//
//  Loadable+Objc.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/5.
//

import Foundation
import LKLoadable

@objc
final public class LarkStorageLoadable: NSObject {
    @objc(startByKey:)
    public class func startOnlyOnce(byKey key: String) {
        LKLoadable.SwiftLoadable.startOnlyOnce(key: key)
    }
}
