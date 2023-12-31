//
//  ImageDownSampleUtils.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/11/2.
//

import Foundation
import LarkSetting
import LKCommonsLogging

public struct ImageDownSampleUtils {
    static let logger = Logger.oplog(ImageDownSampleUtils.self, category: "ImageDownSampleUtils")

    public static func downsampleImage(image: UIImage) -> UIImage{
        let config = OPImageDownsampleConfig.settingsConfig()
        logger.info("imageDownsampleConfig:\(config)")
        guard config.imageDownSampleEnable else {
            return image
        }
        let targetSize = CGSize(width: CGFloat(config.targetWidth), height: CGFloat(config.targetHeight))
        return ImageDownSampleUtils.downsampleImage(image: image, targetSize: targetSize)
    }
    
    public static func downsampleImage(image: UIImage, targetSize: CGSize) -> UIImage{
        logger.info("downsampleImage targetSize:\(targetSize)")
        let originSize = image.size
        if originSize.width < targetSize.width || originSize.height < targetSize.height {
            return image
        }
        var newSize = originSize
        while (newSize.width / 2) >= targetSize.width && (newSize.height / 2) >= targetSize.height {
            newSize = CGSize(width: newSize.width / 2, height: newSize.height / 2)
        }
        logger.info("downsampleImage image origin size:\(originSize), new size:\(newSize)")
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let render = UIGraphicsImageRenderer(size: newSize, format: format)
        let newImage = render.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        logger.info("downsampleImage image after size:\(newImage.size)")
        return newImage
    }
}


struct OPImageDownsampleConfig {
    
    static func settingsConfig() -> OPImageDownSampleSettingConfig {
        var  settingsConfig = OPImageDownSampleSettingConfig.default
        do {
            let config: [String: Any] = try SettingManager.shared.setting(with: .make(userKeyLiteral: "openplatform_downsample_config"))
            if let imageDownSampleEnable = config["image_downsample_enable"] as? Bool,
                let targetWidth = config["target_width"] as? Int64,
                let targetHeight = config["target_height"] as? Int64 {
                settingsConfig = OPImageDownSampleSettingConfig(imageDownSampleEnable: imageDownSampleEnable, targetWidth: targetWidth, targetHeight: targetHeight)
            }
        } catch {}
        return settingsConfig
    }
}

struct OPImageDownSampleSettingConfig {

    /// 是否开启降采样
    var imageDownSampleEnable: Bool

    /// 降采样标准宽度
    var targetWidth: Int64

    /// 降采样标准高度
    var targetHeight: Int64

    /// 默认配置
    static let `default` = OPImageDownSampleSettingConfig(imageDownSampleEnable: true, targetWidth: 640, targetHeight: 480)
}
