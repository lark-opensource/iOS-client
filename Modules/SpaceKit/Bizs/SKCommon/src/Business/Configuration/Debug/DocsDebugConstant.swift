//
//  DebugConstant.swift
//  Docs
//
//  Created by nine on 2018/11/7.
//  Copyright © 2018 Bytedance. All rights reserved.
//  swiftlint:disable operator_usage_whitespace

import SKFoundation
import SKInfra

public struct DocsDebugConstant {

    public static var isCustomOfflineResourceEnable: Bool {
        return GeckoPackageManager.shared.isUsingSpecial(.webInfo)
    }
    
    public static var isUseSimplePackage: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.isUseSimplePackage)
    }
#if BETA || ALPHA || DEBUG
    public static var isVconsoleEnable = false

    public static var isProtocolEnable: Bool {
        return OpenAPI.offlineConfig.protocolEnable
    }

    public static var isGeckoApplyDisable: Bool {
        return OpenAPI.offlineConfig.geckoFetchEnable
    }

    public static var isPreReleaseEnbale: Bool {
        return OpenAPI.DocsDebugEnv.current == .preRelease
    }

    public static var isEnableStatisticsEncryption: Bool {
        return OpenAPI.enableStatisticsEncryption
    }

    public static var isAgentToFrontend: Bool {
        return OpenAPI.docs.isSetAgentToFrontend
    }
    
    public static var isAgentRepeatModule: Bool {
        return OpenAPI.docs.isAgentRepeatModule
    }
    
    public static var shouldShowFileOpenBasicInfo: Bool {
        return OpenAPI.docs.shouldShowFileOpenBasicInfo
    }

    public static var useRemoteRNResource: Bool {
        return OpenAPI.docs.remoteRN
    }

    public static var driveVideoSDKLogEnabled: Bool {
        return OpenAPI.docs.driveVideoLogEnable
    }

    public static var driveVideoPlayOriginEnable: Bool {
        return OpenAPI.docs.driveVideoPlayOriginEnable
    }

    public static var remoteRNAddress: Bool {
        return OpenAPI.docs.remoteRNAddress
    }

    public static var verifiesAllOnboardings: Bool {
        return OpenAPI.docs.verifiesAllOnboardings
    }

    public static var commentCardUserDebug: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentCardUseDebugSetting)
    }

    public static var commentCardDebugValue: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentCardUIDebugValue)
    }
    
    public static var commentDebugValue: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentDebugValue)
    }
    
    public static var localFileValue: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.localFileValue)
    }
    
    public static var isUseThirdPartyJavascriptEnable: Bool {
        return CCMKeyValue.globalUserDefault.bool(forKey: "UseThirdPartyJavascript")
    }
    
    /// 强制允许截图(打开后即忽略防截图功能，方便QA截屏和录屏)
    public static var screenCaptureForceAllowed = false
#endif
    /// 以后新增的，首位数字作为大的分组tag，在对应分组下面，修改后几位，不要随意发挥了
    public enum SwitchButtonTag: Int {
#if BETA || ALPHA || DEBUG
        case flex                              = 1000
        case testDev                           = 2000
        case protocolEnable                    = 3000   // 使用离线资源包
        case bitableEnabled                    = 4000   // 独立 bitable 开关
        case geckoEnable                       = 5000   // 启用 Gecko 资源
        case disableEditorReuse                = 7000   // 启用 Gecko 资源
        //case disableLarkWebView                = 7001   // 禁用LarkWebView
        case vconsoleEnable                    = 8000
        case preReleaseEnv                     = 9000
        case enableStatisticsEnctyption        = 9001   // 上报是否加密
        case fpsEnable                         = 10_000
#endif
        case enableCustomOfflineResourceEnable = 11_000  // 开启指定离线资源包
#if BETA || ALPHA || DEBUG
        case enableCustomThirdPartyJavascriptEnable = 11001  // 开启指定google docs js
        case isSetAgentToFrontend              = 13000  // 代理到前端
        case isAgentRepeatModule               = 16000  // 代理模式复用模版
        case showFileOpenBasicInfo             = 14000  // 文档打开时的基本信息，比如打开方式等
        case useRemoteRNResource               = 15000  // 远端RN
        case bitableTest                       = 20000
        case remoteRNAddress                   = 40000
 //       case editorPoolMinPolicy               = 60000 废弃
        case useSingleWebview                  = 80000
        case isForQA                           = 80001
        case driveVideoSDKLogEnable            = 81000  // 开启视频SDK日志
        case driveVideoPlayOriginEnable        = 81001  // 开启视频原地址播放
        case verifiesAllOnboardings            = 100000 // 全局调试引导开关
//        case spaceManualOfflineEnable          = 100002 // Space 手动离线引导是否显示
        case driveTest                         = 110_000
        case commentCardUseDebugSetting        = 120_000 // 是否使用debug设置值
        case commentCardUserNew                = 120_001 // 使用新版本评论UI
        case ipadCommentUserOld                = 120_002 //iPad评论使用旧版评论
        case commentDebugEnable                = 120_003 // comment debug
#endif
        case useSimpleFEPackage                = 130_000 // 是否强制使用本地精简包
#if BETA || ALPHA || DEBUG
        case isQMAccount                       = 140_001 // 是QM账号
        case uploadImgByDocRequest             = 150_001 // 上传图片走docs后台接口
        case disableRustRequest                = 150_002 // 网络请求不走rust
        case configRustProxy                   = 150_003 // 配置抓包代理
        case enableEtTest                      = 150_004 //前端ETTest开关
        case disableFilterBOMChar              = 150_005
        case nativeEditorUseDebugSetting       = 150_006 //native编辑器使用调试设置
        case docxUseNativeEditorInDebug        = 150_007 //docx使用native编辑器打开
        case allowScreenCaptureInDebug         = 150_008 //强制允许截图
        case localFile                         = 150_009
        case enableCustomLynxPkg               = 160_001 //指定lynx资源包
        case enableSSRCahceToast               = 160_002 // 调试打开ssr和clientvar命中缓存toast
        case keepSSRWebViewAlive               = 160_003 // SSRWebView不自动隐藏
 #endif
    }
}
