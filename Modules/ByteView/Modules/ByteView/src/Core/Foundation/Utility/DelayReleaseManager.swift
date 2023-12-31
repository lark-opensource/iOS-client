//
//  DelayReleaseManager.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/2/10.
//

import Foundation

final class DelayReleaseManager {

    private static var objects: [String: Any] = [:]

    static func append(_ object: Any, delaySeconds: TimeInterval) {
        let identifier = "delay_release_\(Date().timeIntervalSince1970)"
        objects[identifier] = object
        Logger.base.info("start delay release \(identifier), for \(delaySeconds) seconds")
        DispatchQueue.global().asyncAfter(deadline: .now() + delaySeconds) {
            DelayReleaseManager.objects.removeValue(forKey: identifier)
            Logger.base.info("delay release \(identifier)")
        }
    }
}
