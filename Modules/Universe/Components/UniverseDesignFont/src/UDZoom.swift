//
//  UDZoom.swift
//  UniverseDesignFont
//
//  Created by Hayden on 2021/4/29.
//

import Foundation
import UIKit

// MARK: - Zoom level definition

public enum UDZoom: Int, CaseIterable, Codable {

    case small1 = -1
    case normal = 0
    case large1 = 1
    case large2 = 2
    case large3 = 3
    case large4 = 4

    /// The avarage scale factor of each zoom level.
    /// Scalable UI elements that not specially defined will use this coefficient to scale up or down.
    public var scale: CGFloat {
        switch self {
        case .small1:   return 0.92
        case .normal:   return 1.00
        case .large1:   return 1.08
        case .large2:   return 1.17
        case .large3:   return 1.28
        case .large4:   return 1.38
        }
    }

    /// Semantic name of zoom level.
    public var name: String {
        switch self {
        case .small1:   return "S"
        case .normal:   return "M"
        case .large1:   return "L"
        case .large2:   return "XL"
        case .large3:   return "2XL"
        case .large4:   return "3XL"
        }
    }
}

// MARK: - Data persistence

public extension UDZoom {

    // lint:disable lark_storage_check

    /// Posted when the app’s content zoom level changes.
    static let didChangeNotification = Notification.Name("ZoomDidChange")
    /// Posted when the app’s content zoom level initialized, posted only once.
    static let didInitializeNotification = Notification.Name("ZoomDidInitialize")

    // KeyValue storage helper
    private static let storageKey = "CurrentZoomKey"
    
    private static var kvStore: UserDefaults { UserDefaults.standard }

    /// The FG switch of zoom feature.
    @available(*, deprecated, message: "The feature is already GA, this variable always return 'true'")
    private(set) static var isZoomEnabled: Bool = true

    /// The app should restart or not after changing zoom level.
    @available(*, deprecated, message: "The feature is already GA, this variable always return 'false'")
    private(set) static var isRestartRequired: Bool = false

    /// Whether use cache when returning UIFont instance.
    private(set) static var isCacheEnabled: Bool = {
        return false
    }()

    /// Indicate whether the zoom is loaded from user default or system setting after app launching.
    private(set) static var isZoomInitialized: Bool = false
    static var isZoomInitReported: Bool = false

    /// The current zoom level (get only).
    private(set) static var currentZoom: UDZoom = getCurrentZoom()

    /// Save new zoom level to UserDefault.
    static func setZoom(_ newZoom: UDZoom) {
        kvStore.set(newZoom.rawValue, forKey: storageKey)
        currentZoom = newZoom
        NotificationCenter.default.post(name: didChangeNotification, object: newZoom)
    }

    /// Get saved zoom level from UserDefault.
    private static func getCurrentZoom() -> UDZoom {
        var initZoom: UDZoom = .normal
        if let value = kvStore.object(forKey: storageKey),
           let intValue = value as? Int,
           let storedZoom = UDZoom(rawValue: intValue) {
            initZoom = storedZoom
        } else {
            initZoom = getDefaultZoomForOnce()
        }
        isZoomInitialized = true
        NotificationCenter.default.post(name: didInitializeNotification, object: initZoom)
        return initZoom
    }

    /// Get the nearest zoom level compared with system setting.
    private static func getDefaultZoomForOnce() -> UDZoom {
        // Get the current system zoom scale for 'body' font.
        let systemScale: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize / 17
        // Find nearest zoom level.
        var nearestZoom: UDZoom = .normal
        var nearestScaleDifference: CGFloat = CGFloat.greatestFiniteMagnitude
        for currentZoom in UDZoom.allCases {
            let scaleDifference = abs(systemScale - currentZoom.scale)
            if scaleDifference < nearestScaleDifference {
                nearestZoom = currentZoom
                nearestScaleDifference = scaleDifference
            }
        }
        kvStore.set(nearestZoom.rawValue, forKey: storageKey)
        return nearestZoom
    }
    
    // lint:enable lark_storage_check
}

// MARK: - Zoom system transformation

public extension UDZoom {

    /// Some compact UI elements are hard to adopt default 6-gear zoom level system,
    /// use transformer to downgrage current zoom level to other zoom level system.
    enum Transformer {
        /// Non-dynamic zoom system which always return font at normal level.
        case fixed
        /// Compact Zoom system for doc\vc\calendar, which map current 6-gear zoom system to 4-gear.
        case s4
        /// Default zoom system, which use 6-gear system.
        case s6

        /// Zoom level transformer that convert a zoom level into another.
        public var mapper: (UDZoom) -> UDZoom {
            switch self {
            case .fixed:    return Transformer.fixedMapper(_:)
            case .s4:       return Transformer.sixToFourMapper(_:)
            case .s6:       return Transformer.defaultMapper(_:)
            }
        }

        private static func sixToFourMapper(_ zoom: UDZoom) -> UDZoom {
            switch zoom {
            case .small1:           return .small1
            case .normal:           return .normal
            case .large1, .large2:  return .large1
            case .large3, .large4:  return .large2
            }
        }

        private static func defaultMapper(_ zoom: UDZoom) -> UDZoom {
            return zoom
        }

        private static func fixedMapper(_ zoom: UDZoom) -> UDZoom {
            return .normal
        }
    }
}
