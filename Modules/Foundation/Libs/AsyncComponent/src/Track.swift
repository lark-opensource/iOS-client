//
//  Track.swift
//  AsyncComponent
//
//  Created by zhaodong on 2019/11/15.
//

import Foundation
import os.signpost

struct Track {
    private static let osLogger = OSLog(subsystem: "Lark", category: "Renderer")

    enum TrackKey: String {
        case layout
        case update_rootComponent
        case rootComponent_render
        case vnode_layout
        case renderTreeSnapshot
        case renderView

        var staticString: StaticString {
            switch self {
            case .layout:
                return "layout"
            case .update_rootComponent:
                return "update_rootComponent"
            case .rootComponent_render:
                return "rootComponent_render"
            case .vnode_layout:
                return "vnode_layout"
            case .renderTreeSnapshot:
                return "renderTreeSnapshot"
            case .renderView:
                return "renderView"
            }
        }
    }
    static func start(_ key: TrackKey) {
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: Track.osLogger, name: key.staticString)
        }
        #endif
    }
    static func end(_ key: TrackKey) {
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_signpost(.end, log: Track.osLogger, name: key.staticString)
        }
        #endif
    }
}
