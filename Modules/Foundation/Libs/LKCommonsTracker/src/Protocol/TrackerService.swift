//
//  TrackerService.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation
import ThreadSafeDataStructure

public protocol TrackerService: AnyObject {
    func post(event: Event)
}

final class TrackServiceWrapper: TrackerService {
    var services: SafeArray<TrackerService> = [] + .readWriteLock

    func post(event: Event) { services.getImmutableCopy().forEach { $0.post(event: event) } }
}
