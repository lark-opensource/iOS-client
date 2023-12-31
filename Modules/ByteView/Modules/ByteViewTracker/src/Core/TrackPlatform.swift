//
//  TrackPlatform.swift
//  ByteViewTracker
//
//  Created by kiri on 2021/8/16.
//

import Foundation

public enum TrackPlatform: Int, Hashable {
    case tea
    case plane
    case slardar
}

extension TrackPlatform: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .tea:
            return "tea"
        case .plane:
            return "plane"
        case .slardar:
            return "slardar"
        }
    }
}

extension TrackPlatform {
    @inline(__always)
    func setFactory(_ factory: (() -> TrackHandler)?) {
        switch self {
        case .tea:
            TeaHandler.factory = factory
        case .plane:
            PlaneHandler.factory = factory
        case .slardar:
            SlardarHandler.factory = factory
        }
    }

    @inline(__always)
    var factory: (() -> TrackHandler)? {
        switch self {
        case .tea:
            return TeaHandler.factory
        case .plane:
            return PlaneHandler.factory
        case .slardar:
            return SlardarHandler.factory
        }
    }
}

private struct TeaHandler {
    static var factory: (() -> TrackHandler)? = { TeaTracker.shared }
}

private struct SlardarHandler {
    static var factory: (() -> TrackHandler)? = { SlardarTracker.shared }
}

private struct PlaneHandler {
    static var factory: (() -> TrackHandler)?
}
