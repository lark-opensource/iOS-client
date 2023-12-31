//
//  Data+Mail.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2022/1/29.
//

import Foundation
import ByteWebImage
import PocketSVG

extension Data: MailExtensionCompatible {}
extension MailExtension where BaseType == Data {
    var imageType: ImageFileFormat {
        base.bt.imageFileFormat
    }
    
    var imagePreviewType: String {
        if let type = MailImageHandler.imageFormatFromImageData(data: self.base) {
            return type
        } else if let string = String(data: self.base, encoding: .utf8), SVGBezierPath.paths(fromSVGString: string).count > 0 {
            return "svg"
        } else {
            return "png"
        }
    }

    var isGIF: Bool {
        guard base.count >= 6 else { return false }
        let gif89Header = [UInt8]([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
        let gif87Header = [UInt8]([0x47, 0x49, 0x46, 0x38, 0x37, 0x61])
        let header = [UInt8](base[0..<6])
        return header == gif89Header || header == gif87Header
    }
    
    func mimeTypeWith(request: URLRequest) -> String {
        guard let originUrl = request.url else {
            return "text/html"
        }
        var mimeType: String?
        if originUrl.pathExtension == "js" {
            mimeType = "application/javascript"
        } else if originUrl.pathExtension == "css" {
            mimeType = "text/css"
        } else if originUrl.pathExtension == ".html" {
            mimeType = "text/html"
        } else if originUrl.pathExtension == ".svg" {
            mimeType = "image/svg+xml"
        } else if let acceptField = request.allHTTPHeaderFields?["Accept"] {
            if acceptField.contains("image") {
                mimeType = "image/png"
                // 解决图片 mimeType 不对，导致长按图片preview复制出错的问题
                // 图片类型
                let imageType = self.imageType
                if imageType == .unknown {
                    if let string = String(data: self.base, encoding: .utf8), SVGBezierPath.paths(fromSVGString: string).count > 0 {
                        mimeType = "image/svg+xml"
                    }
                } else {
                    mimeType = "image/\(imageType.description)"
                }
                MailLogger.info("MailImage imageMimeType \(mimeType ?? "")")
            } else {
                mimeType = acceptField.components(separatedBy: ",").first
            }
        } else {
         MailLogger.error("no mimetype", error: nil, component: nil)
        }
        return mimeType ?? "text/html"
    }
}
