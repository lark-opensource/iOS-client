//
//  BasePickH5ImagePlugin.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/11/15.
//

import Foundation
import SKCommon
import SKFoundation
import Kingfisher

public struct BasePickH5ImagePluginConfig {
    let cache: SKCacheService
    init(_ cache: SKCacheService) {
        self.cache = cache
    }
}

public protocol BasePickH5ImagePluginProtocol: SKExecJSFuncService {
    func pickImagePluginFinishJsInsert(plugin: BasePickH5ImagePlugin)
}

/*
 * 存储由前端选择的图片
 *
 */
public final class BasePickH5ImagePlugin: JSServiceHandler {

    static let imagesInfoKey = "PickImages"

    static let OriginalInfoKey = "isOriginal"

    public var config: BasePickH5ImagePluginConfig

    public weak var pluginProtocol: BasePickH5ImagePluginProtocol?

    public var objToken: String?

    private var jsCallback: String = ""

    public init(_ config: BasePickH5ImagePluginConfig) {
        self.config = config
    }

    public var handleServices: [DocsJSService] = [
        .pickH5Image
    ]

    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .pickH5Image:
            handlePickImage(params)
        default: ()
        }
    }

    private func handlePickImage(_ params: [String: Any]) {
        if let callback = params["callback"] as? String,
            let base64Arr = params["data"] as? [String] {
            jsCallback = callback
            let imageArr = base64Arr.compactMap({ base64 -> UIImage? in
                if let image = UIImage.docs.image(base64: base64) {
                    return image
                }
                DocsLogger.error("Pick H5 image err: decode base64 failed", extraInfo: ["jsCallback": callback])
                return nil
            })
            jsInsertImages(imageArr)
        } else {
            let extraInfo = ["hasCallback": params["callback"] != nil, "hasData": params["data"] != nil]
            DocsLogger.error("Pick H5 image err: required params not found", extraInfo: extraInfo)
        }
    }

    private func jsInsertImages(_ images: [UIImage]) {
        var imageInfos: [String] = []
        let queue = DispatchQueue(label: "com.docs.pickh5image")
        images.forEach { (image) in
            queue.async {
                let uuid = self.makeUniqueId()
                let imageKey = self.makeImageCacheKey(with: uuid)
                guard let data = image.data(quality: 1, limitSize: UInt.max) as NSCoding? else { return }
                self.config.cache.storeImage(data, token: self.objToken, forKey: imageKey, needSync: true)
                if let info = self.makeImageInfoParas(uuid: uuid, image: image, imageType: .unknown) {
                    imageInfos.append(info)
                }
            }
        }
        queue.async {
            DispatchQueue.main.async {
                if let paramDic = self.makeResJson(images: imageInfos, code: 0) {
                    self.pluginProtocol?.callFunction(DocsJSCallBack(self.jsCallback), params: paramDic, completion: nil)
                }
                self.pluginProtocol?.pickImagePluginFinishJsInsert(plugin: self)
            }
        }
    }

    private func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private func makeImageInfoParas(uuid: String, image: UIImage, imageType: ImageFormat) -> String? {
        var contentType: String = ""
        switch imageType {
        case .GIF:
            contentType = "image/gif"
        case .PNG:
            contentType = "image/png"
        case .JPEG:
            contentType = "image/jpeg"
        default:
            contentType = ""
        }
        let res = ["uuid": uuid,
                   "contentType": contentType,
                   "src": DocSourceURLProtocolService.scheme + "://com.bytedance.net/file/f/" + uuid,
                   "width": "\(image.size.width * image.scale)px",
                   "height": "\(image.size.height * image.scale)px"] as [String: Any]
        return res.jsonString
    }

    private func makeImageCacheKey(with uuid: String) -> String {
        return "/file/f/" + uuid
    }

    private func makeResJson(images imageArr: [String], code: Int) -> [String: Any]? {
        return ["code": code,
                "thumbs": imageArr] as [String: Any]
    }

}
