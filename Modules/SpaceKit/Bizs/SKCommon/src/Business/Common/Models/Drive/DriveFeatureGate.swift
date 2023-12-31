//
//  DriveFeatureGate.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/8/13.
//

import UIKit
import LarkAppConfig
import SKFoundation
import LarkKAFeatureSwitch
import LarkSetting
import LarkReleaseConfig
import SKInfra

public struct DriveFeatureGate {

    // 是否启用 Drive 功能
    // 目前某些 KA 上会禁用 Drive 功能
    public static var driveEnabled: Bool {
        let enabled = FeatureSwitch.share.bool(for: .suiteFileDownload)
        DocsLogger.info("suiteFileDownloadEnabled: \(enabled)")
        return enabled
    }

    public static var manualOfflineEnabled: Bool {
        return ManualOfflineConfig.enableFileType(.file)
    }

    @RealTimeFeatureGatingProvider(key: "spacekit.mobile.wps_enable")
    public static var driveWPSEnabled: Bool
    
    @RealTimeFeatureGatingProvider(key: "spacekit.mobile.drive_wps_edit_enable")
    public static var driveWPSEditEnable: Bool
}

extension DriveFeatureGate {

    // 文本文件预览阈值，单位为 Byte
    public static var textPreviewMaxSize: UInt64 {
        guard let sizeLimit = SettingConfig.drivePreviewConfigKey?.textPreviewMaxSize else {
            return 5 * 1024 * 1024 // 5MB
        }
        return sizeLimit * 1024 // FG 下发单位为 KB
    }

    // webp文件预览阈值，单位为 Byte
    public static var webpPreviewMaxSize: UInt64 {
        guard let sizeLimit = SettingConfig.drivePreviewConfigKey?.webpMaxSize else {
            return 10 * 1024 * 1024 // 10MB
        }
        return sizeLimit * 1024 // FG 下发单位为 KB
    }

    // 代码文件高亮处理阈值，单位为 Byte
    public static var codeHighlightMaxSize: UInt64 {
        guard let sizeLimit = SettingConfig.drivePreviewConfigKey?.highLightMaxSize else {
            return 1 * 1024 * 1024 // 1MB
        }
        return sizeLimit * 1024 // FG 下发单位为 KB
    }
    
    // excel文件使用 html预览阈值，单位为 Byte
    public static var excelHtmlTabPreviewMaxSize: UInt64 {
        guard let sizeLimit = SettingConfig.drivePreviewConfigKey?.excelTabDataMaxSize else {
            return 10 * 1024 * 1024 // 20MB
        }
        
        // html tab 数据会使用 base 64 编码
        return sizeLimit * 1024 / 4 * 3 // FG 下发单位为 KB
    }

    /// 本地预览压缩文件最大值，单位 Byte
    public static var localArchivePreviewMaxSize: UInt64 {
        if let sizeLimit = SettingConfig.drivePreviewConfigKey?.localArchiveMaxSize {
            // AppSetting 下发单位为 KB
            return sizeLimit * 1024
        } else {
            // 默认 512M
            return 512 * 1024 * 1024
        }
    }
    
    public static var orientationBugSystems: [String] {
        return SettingConfig.drivePreviewConfigKey?.orientationBugSystems ?? []
    }
    
    public static var wpsRenderTerminateRetryCount: UInt64 {
        return SettingConfig.drivePreviewConfigKey?.wpsRenderTerminateRetryCount ?? 3
    }
    
    public static var wpsTemplateTimeout: UInt64 {
        return SettingConfig.drivePreviewConfigKey?.wpsTemplateTimeout ?? 3
    }

    public static var ttVideoOutletThreadOptimizeEnable: Bool {
        return SettingConfig.drivePreviewConfigKey?.ttVideoOutletThreadOptimizeEnable ?? true
    }

    public static var markdownRenderMaxSize: UInt64 {
        return Self.codeHighlightMaxSize
    }

    public static var richTextRenderMaxSize: UInt64 {
        return Self.codeHighlightMaxSize
    }
    
    public static var downloadMaxSizeLimit: UInt64 {
        guard let downloadSizeLimit = SettingConfig.drivePreviewConfigKey?.downloadOriginFileMaxSize else {
            return 4 * 1024 * 1024 * 1024  // 4G
        }
        return downloadSizeLimit * 1024  // FG 下发单位为 KB
    }
    // pdfkit支持渲染的单页最大限制，
    // 比如pdf文件100M，一共10页，那么平均每页大小为10M, 通过pdfkit渲染可能会oom
    // 所以需要限制单页最大限制
    public static var pdfkitMaxSizePerPage: UInt64 {
        guard let sizeLimit = SettingConfig.drivePreviewConfigKey?.pdfkitMaxSizePerPage else {
            return 8 * 1024 * 1024  // 8M
        }
        DocsLogger.info("pdfkitMaxSizePerPage: \(sizeLimit)")
        return sizeLimit * 1024  // FG 下发单位为 KB
    }

    /// 转码中小视频降级预览的阈值20M，单位 Byte
    public static var downloadVideoSizeWhenTranscoding: UInt64 {
        if let sizeLimit = SettingConfig.drivePreviewConfigKey?.smallVideoSize {
            // AppSetting 下发单位为 KB
            return sizeLimit * 1024
        } else {
            // 默认 20M
            return 20 * 1024 * 1024
        }
    }

    /// 转码中原视频在线播放的码率阈值，单位bps
    public static var littleBitRate: UInt64 {
        if let bitRate = SettingConfig.drivePreviewConfigKey?.littleBitRate {
            return bitRate
        } else {
            // 默认1200Kbps
            return 1200 * 1024 * 8
        }
    }
    
    /// 转码中原视频在线播放的码率阈值，单位bps
    public static var suppportSourcePreviewTypes: [String] {
        if let suppportSourcePreviewTypes = SettingConfig.drivePreviewConfigKey?.videoSupportSourcePreviewTypes {
            return suppportSourcePreviewTypes
        } else {
            return ["h264", "h265", "hevc"]
        }
    }
    
    /// PDF 文件缩放最大倍数
    public static var pdfMaxScale: Float {
        guard let pdfMaxSacle = SettingConfig.drivePreviewConfigKey?.pdfMaxScale else {
            return 6
        }
        return pdfMaxSacle
    }

    /// PDF 文件缩放最小倍数
    public static var pdfMinScale: Float {
        guard let pdfMinScale = SettingConfig.drivePreviewConfigKey?.pdfMinScale else {
            return 0.5
        }
        return pdfMinScale
    }

    // 缩略图预览流程配置
    public static func maxFileSize(for type: String) -> UInt64 {
        guard let config = SettingConfig.thumbImageConfig else {
            return 0
        }
        return config.typesConfig[type.uppercased()] ?? 0
    }
    
    public static func checkIfSupport(appID: String) -> Bool {
        guard let config = SettingConfig.thumbImageConfig else {
            return false
        }
        return config.suppotedApps.contains(appID)
    }
    
    public static var minSizeForThumbnailPreview: UInt64 {
        guard let config = SettingConfig.thumbImageConfig else {
            return 1 * 1024 * 1024
        }
        return config.minSize
    }
    
    public static var thumbnailPreviewEnable: Bool {
        guard let config = SettingConfig.thumbImageConfig else {
            return false
        }
        return config.enable
    }
}

extension DriveFeatureGate {

    public static var defaultPreloadConfig: DrivePreloadConfig {
        guard let config = SettingConfig.drivePreloadConfig else {
            DocsLogger.error("Drive failed to parse preload config")
            return DrivePreloadConfig(recentLimit: 10,
                                      pinLimit: 10,
                                      favouriteLimit: 6,
                                      sizeLimit: 20 * 1024 * 1024,
                                      videoCacheSizeLimit: 800 * 1024)
        }
        return DrivePreloadConfig(recentLimit: config.recent,
                                  pinLimit: config.pin,
                                  favouriteLimit: config.favorite,
                                  sizeLimit: UInt64(config.filemaxsize),
                                  videoCacheSizeLimit: UInt64(config.cachevideosize))
    }
    
    public static var defaultDriveRustConfig: StructDriveRustConfig {
        guard let config = SettingConfig.driveRustConfig else {
            return StructDriveRustConfig(disableCdnDownload: false,
                                         newCdnDomainSelect: true,
                                         multiTask: true,
                                         useRangeInPart: true,
                                         weakOptimize: true,
                                         smartClearDB: true,
                                         maxThreadSize: 3,
                                         maxDownloadPartSize: 3 * 1024 * 1024,
                                         smallUploadFileSize: 20 * 1024 * 1024)
        }
        return config
    }
    
    public static var wpsEnable: Bool {
        if !DomainConfig.envInfo.isFeishuPackage {
            // Lark 包使用 WPS FG 控制预览
            return DriveFeatureGate.driveWPSEnabled
        } else if (DomainConfig.envInfo.isFeishuBrand == false) || ReleaseConfig.isPrivateKA {
            // 海外租户或者 KA 租户通过 FG 判断 WPS 是否启用
            return DriveFeatureGate.driveWPSEnabled
        } else {
            // 国内租户，默认开启
            return true
        }
    }
}
