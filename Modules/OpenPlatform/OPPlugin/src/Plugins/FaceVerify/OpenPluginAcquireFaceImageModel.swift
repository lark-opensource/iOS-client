//
//  OpenPluginAcquireFaceImageModel.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 30298
//
//  类型声明默认为internal, 如需被外部Module引用, 请在上行添加
//  /** anycode-lint-ignore */
//  public
//  /** anycode-lint-ignore */

import Foundation
import LarkOpenAPIModel


// MARK: - OpenPluginAcquireFaceImageRequest
final class OpenPluginAcquireFaceImageRequest: OpenAPIBaseParams {
    
    /// description: 采集时使用的摄像头
    /// cameraDevice = front 使用前置摄像头
    /// cameraDevice = back 使用后置摄像头
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "cameraDevice",
            defaultValue: .front)
    var cameraDevice: CameraDeviceEnum
    
    /// description: 采集俯仰角度限制
    @OpenAPIOptionalParam(
            jsonKey: "pitchAngle")
    var pitchAngle: Double?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_cameraDevice, _pitchAngle]
    }

    // MARK: CameraDeviceEnum
    enum CameraDeviceEnum: String, OpenAPIEnum {

        /// description: 使用前置摄像头
        case front = "front"

        /// description: 使用后置摄像头
        case back = "back"

    }
}

// MARK: - OpenPluginAcquireFaceImageResponse
final class OpenPluginAcquireFaceImageResponse: OpenAPIBaseResult {
    
    /// description: 采集到的人脸图片路径
    let tempFilePath: String
    
    init(tempFilePath: String) {
        self.tempFilePath = tempFilePath
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        var result: [AnyHashable : Any] = [:]
        result["tempFilePath"] = tempFilePath
        return result
    }
}
