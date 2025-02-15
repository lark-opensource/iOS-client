//
//  OpenPluginEditorFilePathConvertModel.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 29208
//
//  类型声明默认为internal, 如需被外部Module引用, 请在上行添加
//  /** anycode-lint-ignore */
//  public
//  /** anycode-lint-ignore */

import Foundation
import LarkOpenAPIModel


// MARK: - OpenPluginEditorFilePathConvertRequest
final class OpenPluginEditorFilePathConvertRequest: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "images")
    var images: [String]
    
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "maxHeight")
    var maxHeight: Int
    
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "maxWidth")
    var maxWidth: Int
    
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "maxSize")
    var maxSize: Int
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_images, _maxHeight, _maxWidth, _maxSize]
    }
}

// MARK: - OpenPluginEditorFilePathConvertResponse
final class OpenPluginEditorFilePathConvertResponse: OpenAPIBaseResult {
    
    let images: [ImagesItem]
    
    init(images: [ImagesItem]) {
        self.images = images
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        var result: [AnyHashable : Any] = [:]
        result["images"] = images.map({ $0.toJSONDict() })
        return result
    }

    // MARK: ImagesItem
    final class ImagesItem: OpenAPIBaseResult {

        let filePath: String

        let width: Double

        let height: Double

        init(filePath: String, width: Double, height: Double) {
            self.filePath = filePath
            self.width = width
            self.height = height
            super.init()
        }

        override func toJSONDict() -> [AnyHashable : Any] {
            var result: [AnyHashable : Any] = [:]
            result["filePath"] = filePath
            result["width"] = width
            result["height"] = height
            return result
        }
    }
}