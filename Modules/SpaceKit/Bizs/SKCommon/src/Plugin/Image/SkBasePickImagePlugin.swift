//
//  BaseSelectImagePlugin.swift
//  SpaceKit
//
//  Created by Webster on 2019/6/4.
// swiftlint:disable line_length

import SKFoundation
import SpaceInterface

public struct SkBasePickImagePluginConfig {
    let cache: SKCacheService
    public init(_ cache: SKCacheService) {
        self.cache = cache
    }
}

public protocol SkBasePickImagePluginProtocol: SKExecJSFuncService {
    //完成了js图片的插入
    func pickImagePluginFinishJsInsert(plugin: SkBasePickImagePlugin)
    func callBackAfterPickImage(params: [String: Any])
}

public final class SkBasePickImagePlugin: JSServiceHandler {
    public static let imagesInfoKey = "PickImages"
    public static let OriginalInfoKey = "isOriginal"
    public var config: SkBasePickImagePluginConfig
    public weak var pluginProtocol: SkBasePickImagePluginProtocol?
    public var objToken: String?
    private let queue = DispatchQueue(label: "com.docs.jsinsertImage")
    public init(_ config: SkBasePickImagePluginConfig) {
        self.config = config
    }

    public var handleServices: [DocsJSService] = [.simulateFinishPickingImage]

    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .simulateFinishPickingImage:
            if let images = params[SkBasePickImagePlugin.imagesInfoKey] as? [SkPickImagePreInfo] {
                DocsLogger.info("SkBasePickImagePlugin, simulateFinishPickingImage, images.count=\(images.count)", component: LogComponents.pickImage)
                let original = (params[SkBasePickImagePlugin.OriginalInfoKey] as? Bool) ?? false
                let pencilKitToken = (params["pencilKitToken"] as? String) ?? ""
                jsInsertImages(images,
                               isOriginal: original,
                               pencilKitToken: pencilKitToken)
            } else {
                DocsLogger.info("SkBasePickImagePlugin, simulateFinishPickingImage, err", component: LogComponents.pickImage)
            }
        default:
            ()
        }

    }

    /// call front end's js to upload images
    ///
    /// - Parameter images: images to uplaod
    private func jsInsertImages(_ images: [SkPickImagePreInfo], isOriginal: Bool, pencilKitToken: String? = nil) {
        var imageInfos: [String] = []
        queue.async {
            let transformImageInfos = SKPickImageUtil.getTransformImageInfo(images, isOriginal: isOriginal)
            guard transformImageInfos.count > 0 else {
                DocsLogger.info("jsInsertImages, 上传图片信息为空", component: LogComponents.pickImage)
                return
            }
            transformImageInfos.forEach { (transformInfo) in
                self.config.cache.storeImage(transformInfo.resultData, token: self.objToken, forKey: transformInfo.cacheKey, needSync: true)
                let assetInfo = SKAssetInfo(objToken: self.objToken, uuid: transformInfo.uuid, cacheKey: transformInfo.cacheKey, fileSize: transformInfo.dataSize, assetType: SKPickContentType.image.rawValue)
                self.config.cache.updateAsset(assetInfo)
                var infoString = self.makeImageInfoParas(transformInfo)
                if  let token = pencilKitToken,
                    !token.isEmpty {
                    infoString.updateValue(token, forKey: "pencilKitToken")
                }
                let infoJsonString = infoString.jsonString
                _ = infoJsonString.map { imageInfos.append($0) }
            }

            DispatchQueue.main.async {
                if let paramDic = self.makeResJson(images: imageInfos, code: 0) {
                    DocsLogger.info("SkBasePickImagePlugin, callBackInfo=\(imageInfos), count=\(imageInfos.count)", component: LogComponents.pickImage)
                    self.pluginProtocol?.callBackAfterPickImage(params: paramDic)
                }
                self.pluginProtocol?.pickImagePluginFinishJsInsert(plugin: self)
            }
        }
    }

    private func makeImageInfoParas(_ transformInfo: SkPickImageTransformInfo) -> [String: Any] {
        let res = ["uuid": transformInfo.uuid,
                   "contentType": transformInfo.contentType ?? "",
                   "src": transformInfo.srcUrl,
                   "width": "\(transformInfo.width)px",
                   "height": "\(transformInfo.height)px"] as [String: Any]
        return res
    }


    private func makeResJson(images imageArr: [String], code: Int) -> [String: Any]? {
        return ["code": code,
                "thumbs": imageArr] as [String: Any]
    }

}
