//
//  URLResponse+Mail.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2022/6/6.
//

import Foundation
import ByteWebImage
import WebKit

extension URLResponse: MailExtensionCompatible {}
extension MailExtension where BaseType == URLResponse {
    static func customImageResponse(urlSchemeTask: WKURLSchemeTask, originUrl: URL, data: Data) -> URLResponse {
        let mimetype = data.mail.mimeTypeWith(request: urlSchemeTask.request)
        MailLogger.info("MailImage createResponseForWeb mimeType \(mimetype)")
        let defaultResponse = URLResponse(url: originUrl, mimeType: mimetype, expectedContentLength: data.count, textEncodingName: nil)
        return defaultResponse
    }
}
