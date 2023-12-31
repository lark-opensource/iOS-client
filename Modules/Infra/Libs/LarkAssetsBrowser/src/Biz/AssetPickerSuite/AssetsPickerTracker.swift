//
//  AssetsPickerTracker.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/8/16.
//

import Foundation
import AppReciableSDK
import ThreadSafeDataStructure

final class AssetsPickerTracker {

    struct TrackInfo {
        enum FromType: Int {
            case unknown = 0
            case keyboard = 1
            case gallery = 2
        }
        var fromtype: FromType = .gallery
    }

    private static let map: SafeDictionary<DisposedKey, (TimeInterval, TrackInfo)> = [:] + .readWriteLock

    static func start(fromMoent: Bool, from: TrackInfo.FromType) -> DisposedKey {
        var trackInfo = TrackInfo()
        trackInfo.fromtype = from
        let disposedKey = AppReciableSDK.shared.start(biz: .Core, scene: fromMoent ? .Moments : .Chat, event: .galleryLoad, page: nil)
        let start = Date().timeIntervalSince1970
        map[disposedKey] = (start, trackInfo)
        return disposedKey
    }

    static func end(key: DisposedKey) {
        guard let (start, trackInfo) = map[key] else { return }
        let detail: [String: Any] = [
            "data_load_cost": (Date().timeIntervalSince1970 - start) * 1_000
        ]
        let ext = Extra(isNeedNet: true,
                        latencyDetail: detail,
                        metric: nil,
                        category: [
                            "from_type": trackInfo.fromtype.rawValue
                        ],
                        extra: nil)
        AppReciableSDK.shared.end(key: key, extra: ext)
    }

    public static func clear() {
        map.removeAll()
    }
}
