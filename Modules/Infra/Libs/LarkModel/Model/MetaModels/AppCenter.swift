//
//  AppCenter.swift
//  LarkModel
//
//  Created by qihongye on 2019/5/20.
//

import Foundation
import RustPB

public struct ShareOptions: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let None = ShareOptions([])
    public static let IOS = ShareOptions(rawValue: 1 << 0)
    public static let Android = ShareOptions(rawValue: 1 << 1)
    public static let PC = ShareOptions(rawValue: 1 << 2)
}

// appShare
public enum ShareAppCardType {
    case unknown
    case app(appID: String, url: String)
    case appPage(
        appID: String,
        title: String,
        iconToken: String?,
        url: String,
        appLinkHref: String?,
        options: ShareOptions
    )
    case h5(appID: String?, title: String, iconToken: String?, desc: String, url: String)
}
