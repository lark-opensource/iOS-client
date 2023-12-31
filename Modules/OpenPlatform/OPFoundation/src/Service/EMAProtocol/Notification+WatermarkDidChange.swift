//
//  Notification+WatermarkDidChange.swift
//  OPFoundation
//
//  Created by baojianjun on 2023/5/29.
//

import Foundation

public extension Notification.Name {
    static let WatermarkDidChange = Notification.Name("WatermarkDidChangeNotification")
}

public extension Notification {
    enum Watermark {
        public static let Key = "hasWatermark"
    }
}
