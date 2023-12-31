//
//  FontFaceHandler.swift
//  CalendarRichTextEditor
//
//  Created by JackZhao on 2023/4/14.
//

import UIKit
import WebKit
import LKCommonsLogging
import UniverseDesignFont

// 替换日程描述webview里的字体（替换为西文字体）Handler
final class FontFaceHandler: NSObject, WKURLSchemeHandler {
    static var scheme = "fontface"
    static let logger = LKCommonsLogging.Logger.log(FontFaceHandler.self, category: "CalendarRichTextEditor")
    // 不同的字体风格
    enum FontStyle: String {
        case regular = "regular"
        case semiBold = "semi"
        case bold = "bold"
        case medium = "medium"
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        Self.logger.info("start urlSchemeTask: \(Self.scheme)")
        guard let url = urlSchemeTask.request.url, url.scheme == Self.scheme else {
            assertionFailure("error scheme")
            Self.logger.info("error scheme")
            return
        }
        // 识别不同字体请求
        let style = FontStyle(rawValue: url.host ?? "")
        let regularFilePath: String
        switch style {
        case .regular:
            regularFilePath = UDFontAppearance.customFontInfo?.regularFilePath ?? ""
        case .semiBold:
            regularFilePath = UDFontAppearance.customFontInfo?.semiBoldFilePath ?? ""
        case .bold:
            regularFilePath = UDFontAppearance.customFontInfo?.boldFilePath ?? ""
        case .medium:
            regularFilePath = UDFontAppearance.customFontInfo?.mediumFilePath ?? ""
        default:
            // 兜底展示自定义的regular字体
            regularFilePath = UDFontAppearance.customFontInfo?.regularFilePath ?? ""
            assertionFailure("unknown style: \(url.pathComponents.first ?? "")")
            Self.logger.info("unknown style")
        }
        if regularFilePath.isEmpty {
            assertionFailure("regularFilePath is empty")
            Self.logger.info("regularFilePath is empty")
        }
        guard let resource = UDFontAppearance.customFontInfo?.bundle.path(forResource: regularFilePath, ofType: nil) else {
            Self.logger.info("get Resource is nil")
            return
        }
        guard let data = try? NSData.read(from: resource.asAbsPath()) else {
            Self.logger.info("get data from resource is nil")
            return
        }
        // 开始拦截字体请求
        let res = URLResponse(url: url,
                              mimeType: "application/x-font-truetype",
                              expectedContentLength: data.length,
                              textEncodingName: nil)
        urlSchemeTask.didReceive(res)
        urlSchemeTask.didReceive(data as Data)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        Self.logger.info("stop urlSchemeTask: \(Self.scheme)")
    }
}
