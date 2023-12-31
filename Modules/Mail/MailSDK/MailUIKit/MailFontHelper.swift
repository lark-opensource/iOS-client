//
//  MailFontHelper.swift
//  MailSDK
//
//  Created by Ender on 2023/5/5.
//

import Foundation
import UniverseDesignFont
import LarkStorage

public func getLarkCircularFontBase64String() -> (String, String) {
    // 加载字体文件，转换成 base64String，提供给 WebView 使用
    // WebView 只有两个字重: Normal 和 Bold
    // 对应 Native 的 Regular 和 SemiBold
    var tempFontNormalBase64: String?
    var tempFontBoldBase64: String?
    if let customFontInfo = UDFontAppearance.customFontInfo {
        if let normalFilePath = customFontInfo.bundle.path(forResource: customFontInfo.regularFilePath, ofType: nil) {
            do {
                let normalFontData = try Data.read(from: AbsPath(normalFilePath))
                tempFontNormalBase64 = normalFontData.base64EncodedString()
            } catch {
                MailLogger.error("Mail LoadNormalFont Error \(error)")
            }
        }
        if let boldFilePath = customFontInfo.bundle.path(forResource: customFontInfo.semiBoldFilePath, ofType: nil) {
            do {
                let boldFontData = try Data.read(from: AbsPath(boldFilePath))
                tempFontBoldBase64 = boldFontData.base64EncodedString()
            } catch {
                MailLogger.error("Mail LoadBoldFont Error \(error)")
            }
        }
    }
    return (tempFontNormalBase64 ?? "", tempFontBoldBase64 ?? "")
}
