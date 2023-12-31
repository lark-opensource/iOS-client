//
//  MailImageInfo.swift
//  MailSDK
//
//  Created by Ryan on 2020/5/7.
//

import UIKit

// 图片信息
struct MailImageInfo: Hashable, Equatable {
    let uuid: String
    // 考虑设cid的src为默认值?
    var src: String
    var name: String
    var width: String
    var height: String
    var token: String?
    var dataSize: Int64 = 0
    var driveKey: String? // 这又是啥
    var status: MailImageUploadStatus = .uploading
    var isIllegal: Bool = false

    init(uuid: String, src: String, width: String, height: String, isGif: Bool = false) {
        self.uuid = uuid
        self.src = src
        self.width = width
        self.height = height
        let type = isGif ? ".gif" : ".jpeg"
        self.name = uuid + type
    }

    func getCacheKey(userToken: String?, tenantID: String?) -> String {
        let cacheStr = MailCustomScheme.cid.rawValue + ":\(uuid)" + MailImageInfo.cacheKeySuffix(userToken: userToken, tenantID: tenantID)
        return cacheStr.toBase64()
    }

    static func getImageUrlCacheKey(urlString: String, userToken: String?, tenantID: String?) -> String {
        let cacheKey = urlString + cacheKeySuffix(userToken: userToken, tenantID: tenantID)
        return cacheKey.toBase64()
    }

    static func cacheKeySuffix(userToken: String?, tenantID: String?) -> String {
        guard let token = userToken, let tenantId = tenantID else {
            mailAssertionFailure("missing param"); return ""
        }
        return "_\(token)_\(tenantId)"
    }

    static func convertFromPBModel(_ image: MailClientDraftImage) -> MailImageInfo {
        MailLogger.debug("vvImage | cidMD5:\(image.cid.md5()) tokenMD5:\(image.fileToken.md5()) size:\(image.imageSize)")
        var info = MailImageInfo(uuid: image.cid, src: "", width: "\(image.imageWidth)", height: "\(image.imageHeight)", isGif: image.imageName.mail.isGif)
//        if Store.settingData.mailClient, info.src.isEmpty {
//            info.src = "cid_\(image.cid)fileToken_\(image.fileToken)"
//        }
        info.token = image.fileToken
        info.dataSize = image.imageSize
        if !image.fileToken.isEmpty {
            info.status = .complete
        }
        info.isIllegal = image.isIllegal
        return info
    }

    static func convertFromJSON(param: [String: Any]) -> MailImageInfo {
        let token = param["token"] as? String ?? ""
        let cid = param["cid"] as? String ?? ""
        let fileSizeStr = param["size"] as? String ?? ""
        let fileSizeNumber = param["size"] as? Int64 ?? 0
        let isIllegal = param["isIllegal"] as? Bool ?? false
        let width = param["width"] as? String ?? ""
        let height = param["height"] as? String ?? ""
        let name = param["name"] as? String ?? ""
        var info = MailImageInfo(uuid: cid, src: "", width: width, height: height, isGif: name.mail.isGif)
        if fileSizeNumber > 0 {
            info.dataSize = fileSizeNumber
        } else {
            info.dataSize = Int64(fileSizeStr) ?? 0
        }
        info.token = token
        if !token.isEmpty {
            info.status = .complete
        }
        info.isIllegal = isIllegal
        return info
    }

    func toJSONDic() -> [String: Any] {
        guard let token = token else { mailAssertionFailure("token empty"); return [:] }
        return ["name": name,
                "token": token,
                "cid": uuid,
                "size": dataSize,
                "isIllegal": isIllegal,
                "path": "cid:" + uuid,
                "width": width,
                "height": height]
    }

    func toPBModel() -> MailClientDraftImage {
        guard let token = token else { mailAssertionFailure("must have token"); return MailClientDraftImage() }
        var clientDraftImage = MailClientDraftImage()
        clientDraftImage.imageName = name
        clientDraftImage.fileToken = token
        clientDraftImage.cid = uuid
        clientDraftImage.imageSize = dataSize
        clientDraftImage.imageWidth = Int32(width) ?? 0
        clientDraftImage.imageHeight = Int32(height) ?? 0
        clientDraftImage.isIllegal = isIllegal
        return clientDraftImage
    }
}

// 图片上传状态
enum MailImageUploadStatus: Int {
    typealias RawValue = Int
    case uploading = 0
    case complete = 1
    case error = 2
}
