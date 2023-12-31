//
//  SMBGuideBody.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/11.
//

import Foundation
import EENavigator

public struct SMBGuideBody: PlainBody {
    public static let pattern = "//client/contact/SMBGuide"
    public var url: URL
    public var isFullScreen: Bool
    public init(url: URL, isFullScreen: Bool = true) {
        self.url = url
        self.isFullScreen = isFullScreen
    }
}
