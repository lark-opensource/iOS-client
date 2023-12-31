//
//  URL+Utils.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/4/18.
//

import Foundation

// MARK: - CCM URL
extension URL {
    // swiftlint:disable line_length
    private static let regexPattern =
        #"^https?://.*(\.(sg|va))?\.(feishu\.cn|larksuite\.com)/(base|share/base|sheets|docs|docx|wiki|mindnotes|file)/"#
    // swiftlint:enable line_length
    /// 判断是否是 CCM 文档的链接，用于链接分享埋点。
    ///
    /// 目前只有一处这样的诉求，后续如果多起来了可以考虑抽象整理。
    func isCCMURL() -> Bool {
        return absoluteString.range(of: Self.regexPattern, options: .regularExpression) != nil
    }
}
