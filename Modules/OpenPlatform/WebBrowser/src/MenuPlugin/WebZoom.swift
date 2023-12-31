//
//  WebZoom.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/6/16.
//

import Foundation
import UniverseDesignFont

public final class WebZoom {
    /// Posted when the web’s content zoom level changes.
    static let didChangeNotification = Notification.Name("WebZoomDidChange")
    
    private static let webAppStorageKey = "WebAppCurrentZoomKey"
    
    private static var kvStore: UserDefaults { UserDefaults.standard }
    
    /// The current web app zoom level (get only).
    private(set) static var currentZoom: UDZoom = getZoom()
    
    static func setZoom(_ newZoom: UDZoom) {
        // The app settings affect the web app, but web app settings do not affect the app
        // lint:disable:next lark_storage_check
        kvStore.set(newZoom.rawValue, forKey: webAppStorageKey)
        currentZoom = newZoom
        NotificationCenter.default.post(name: didChangeNotification, object: newZoom)
    }
    
    private static func getZoom() -> UDZoom {
        // lint:disable:next lark_storage_check
        if let value = kvStore.object(forKey: webAppStorageKey),
           let intValue = value as? Int,
           let zoom = UDZoom(rawValue: intValue) {
            return zoom
        }
        return UDZoom.currentZoom
    }
    
    public static func startNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appFontSizeDidUpdate), name: UDZoom.didChangeNotification, object: nil)
    }
    
    @objc private static func appFontSizeDidUpdate() {
        Self.setZoom(UDZoom.currentZoom)
    }
}
