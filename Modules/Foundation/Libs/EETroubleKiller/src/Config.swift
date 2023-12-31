//
//  Config.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/11/19.
//

import UIKit
import Foundation

extension TroubleKiller {
    public final class Config {
        public var enable: Bool = true

        public var recordLimit: Int = 30

        public var recordInterval: Int = 2

        public var treeDepth: Int = 20

        public var maxCaptureWindows: Int = 10

        public internal(set) var routerWhiteList: Set<String> = []

        public internal(set) var defaultWindows: Set<String> = []

        public init() {}
    }
}

extension TroubleKiller.Config {
    func checkInRouterWhiteList(_ name: String) -> Bool {
        return routerWhiteList.contains(where: { name.contains($0) })
    }

    func checkCaptureWindows() -> [UIWindow] {
        let allWindows = UIApplication.shared.windows
        guard maxCaptureWindows > 0 else { return allWindows }

        if allWindows.count <= maxCaptureWindows {
            return allWindows
        } else {
            var captureWindows: [UIWindow] = []
            var sortedWindows = allWindows.sorted(by: UIWindow.sortedVisibleAsce)

            // 1. top visiable window
            captureWindows.append(sortedWindows.removeFirst())

            // 2. default top windows
            var defaultSortedWindows = sortedWindows
                .filter({ defaultWindows.contains($0.captureName) })
            while !defaultSortedWindows.isEmpty && captureWindows.count < maxCaptureWindows {
                captureWindows.append(defaultSortedWindows.removeFirst())
            }

            // 3. other top windows
            var otherSortedWindows = sortedWindows
                .filter({ !defaultWindows.contains($0.captureName) })
            while !otherSortedWindows.isEmpty && captureWindows.count < maxCaptureWindows {
                captureWindows.append(otherSortedWindows.removeFirst())
            }

            return captureWindows
        }
    }
}
