//
//  UserDefaultKeys.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/15.
//

import SKFoundation
import SKInfra

// nolint: magic_number
extension UserDefaultKeys {

    // Rust 相关配置

    // MARK: 上面的写法过时了，请按照下面的格式写，每个版本之间空两行

    // MARK: - 0.3.1
    public static let deviceID = UserDefaultKeys.generateKeyFor(major: 0, minor: 3, patch: 1, keyIndex: 0)


    // MARK: - 0.6.0
    public static let appConfigForFrontEnd = UserDefaultKeys.generateKeyFor(major: 0, minor: 6, patch: 0, keyIndex: 1)
    public static let shouldShowOpenFileBasicInfo = UserDefaultKeys.generateKeyFor(major: 0, minor: 6, patch: 0, keyIndex: 2)


    // MARK: - 0.8.0
    public static let clientVarCacheMetaInfoKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 8, patch: 0, keyIndex: 3)


    // MARK: - 0.9.0
    public static let domainKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 1)  // 用户的域名
    public static let isNewDomainSystemKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 2)  // 是否启用了新域名
    public static let validURLMatchKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 3)  // 满足这个规则的url，可以被打开
    public static let validPathsKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 4)  // 合法的path。 url的path，如果起始是这些，需要被移除掉。然后加上第一个元素

    // MARK: - 1.2.0
    public static let featureIDKey = UserDefaultKeys.generateKeyFor(major: 1, minor: 2, patch: 0, keyIndex: 0)  // 用户的featureid
    public static let disableEditorReuseKey = UserDefaultKeys.generateKeyFor(major: 1, minor: 2, patch: 0, keyIndex: 1)  // 是否🈲️用editor复用逻辑
    public static let useSingleWebviewKey = UserDefaultKeys.generateKeyFor(major: 1, minor: 2, patch: 0, keyIndex: 2)  // 是否每次打开文档，都使用一个webview


    // MARK: - 1.4.0
    public static let enableRustHttp = UserDefaultKeys.generateKeyFor(major: 1, minor: 4, patch: 0, keyIndex: 0)  // 是否支持rustHttp 能力


    // MARK: - 2.6.0
    public static let renderCacheDelayMilliscond = UserDefaultKeys.generateKeyFor(major: 2, minor: 6, patch: 0, keyIndex: 2)  // render缓存html 以后，耗时多少调用render函数


    // MARK: - 2.7.0
    public static let globalWatermarkEnabled = UserDefaultKeys.generateKeyFor(major: 2, minor: 7, patch: 0, keyIndex: 3)
    public static let watermarkPolicy = UserDefaultKeys.generateKeyFor(major: 2, minor: 7, patch: 0, keyIndex: 4)
    public static let forceLogLevel = UserDefaultKeys.generateKeyFor(major: 2, minor: 7, patch: 0, keyIndex: 5)


    // MARK: - 2.8.0
    public static let isForQA = UserDefaultKeys.generateKeyFor(major: 2, minor: 8, patch: 0, keyIndex: 1)  // 是不是测试版本


    // MARK: - 2.10.0
    public static let voiceCommentLastLanguage = UserDefaultKeys.generateKeyFor(major: 2, minor: 10, patch: 0, keyIndex: 0)  // 语音评论记录最后选择语言
    public static let domainConfigPathMap = UserDefaultKeys.generateKeyFor(major: 2, minor: 10, patch: 0, keyIndex: 1)  // path 和对应跳转的目的对应关系
    public static let domainConfigTokenTypePattern = UserDefaultKeys.generateKeyFor(major: 2, minor: 10, patch: 0, keyIndex: 2)  // 根据path，正则匹配的到token和type
    public static let domainConfigPathGenerator = UserDefaultKeys.generateKeyFor(major: 2, minor: 10, patch: 0, keyIndex: 3)  // 根据token和type，得到path
    public static let domainConfigH5PathPrefix = UserDefaultKeys.generateKeyFor(major: 2, minor: 10, patch: 0, keyIndex: 4)  // 传给H5的pathPrefix


    // MARK: - 3.1.0
    public static let editorAddToViewTimeKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 1, patch: 0, keyIndex: 1)  // editor何时被加到视图层级上
    public static let recentSyncMetaInfoKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 1, patch: 0, keyIndex: 2)


    // MARK: - 3.2.0
    public static let pendingSyncObjTokenKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 2, patch: 0, keyIndex: 1)  // 需要同步的objtoken
    public static let needDelayDeallocWebview = UserDefaultKeys.generateKeyFor(major: 3, minor: 2, patch: 0, keyIndex: 2)  // 是否需要延时释放webview
    public static let personalFilesObjsSequence = UserDefaultKeys.generateKeyFor(major: 3, minor: 2, patch: 0, keyIndex: 3)  // PersonalFiles列表顺序存储
    public static let shareFolderObjsSequence = UserDefaultKeys.generateKeyFor(major: 3, minor: 2, patch: 0, keyIndex: 4)  // shareFolder列表顺序存储


    // MARK: - 3.3.0
    public static let recentReactions = UserDefaultKeys.generateKeyFor(major: 3, minor: 3, patch: 0, keyIndex: 0)  // 最近表情
    public static let moreVCNewFeature = UserDefaultKeys.generateKeyFor(major: 3, minor: 3, patch: 0, keyIndex: 2)  // moreViewController New的feature getting
    public static let hasClickMoreViewTranslateBtn = UserDefaultKeys.generateKeyFor(major: 3, minor: 3, patch: 0, keyIndex: 3)  // 是否使用过手动翻译
    public static let firstLanuchTimeKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 3, patch: 0, keyIndex: 6)


    // MARK: - 3.4
    public static let lastClickCommentReactionItem = UserDefaultKeys.generateKeyFor(major: 3, minor: 4, patch: 0, keyIndex: 2)
    public static let recentSyncMetaInfoKeyNew = UserDefaultKeys.generateKeyFor(major: 3, minor: 4, patch: 0, keyIndex: 3)


    // MARK: - 3.5
    public static let newCurrentFileDBVersionKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 5, patch: 0, keyIndex: 1)


    // MARK: - 3.7
    public static let preloadPictureWifiOnly = UserDefaultKeys.generateKeyFor(major: 3, minor: 7, patch: 0, keyIndex: 0)

    // MARK: - 3.8
    public static let manualOfflineEnable = UserDefaultKeys.generateKeyFor(major: 3, minor: 8, patch: 0, keyIndex: 2) + (User.current.basicInfo?.userID ?? "")
    public static let needSyncKeyMigrationComplete = UserDefaultKeys.generateKeyFor(major: 3, minor: 8, patch: 0, keyIndex: 4)


    // MARK: - 3.9
    public static let manualOfflineGuideHadClosed = UserDefaultKeys.generateKeyFor(major: 3, minor: 9, patch: 0, keyIndex: 4) + (User.current.info?.userID ?? "")  // 手动离线引导，是否点过关闭
    public static let cacheMigrationFinished = UserDefaultKeys.generateKeyFor(major: 3, minor: 9, patch: 0, keyIndex: 5)
    public static let missingDBMigrationHasBeenAmended = UserDefaultKeys.generateKeyFor(major: 3, minor: 9, patch: 0, keyIndex: 7)


    // MARK: - 3.10
    public static let h5UrlPathConfig = UserDefaultKeys.generateKeyFor(major: 3, minor: 10, patch: 0, keyIndex: 4)  // 打开文档的url path 匹配规则的动态配置
    public static let wikiHomePageDisabled = UserDefaultKeys.generateKeyFor(major: 3, minor: 10, patch: 0, keyIndex: 6)
    public static let wikiHomePageSpaceCoverDisabled = UserDefaultKeys.generateKeyFor(major: 3, minor: 10, patch: 0, keyIndex: 7)


    // MARK: 3.11
    public static let folderPermissionHelpConfig = UserDefaultKeys.generateKeyFor(major: 3, minor: 11, patch: 0, keyIndex: 3)  // 共享文件夹


    // MARK: - 3.12
    public static let shareFolderSpreadConfig = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 1)  // 共享文件夹收起展开+小红点逻辑
    public static let gridCellThumbnailConfig = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 2)
    public static let thumbnailEtagPreKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 3)
    public static let thumbnailRequetTimePreKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 4)
    public static let missingDBMigrationHasBeenAmendedV2 = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 5)
    public static let missingDBMigrationHasBeenAmendedV3 = UserDefaultKeys.generateKeyFor(major: 3, minor: 12, patch: 0, keyIndex: 6)


    // MARK: - 3.13
    public static let recentDeletedTokensKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 13, patch: 0, keyIndex: 0) + (User.current.info?.userID ?? "")
    public static let recentListUpdateConfig = UserDefaultKeys.generateKeyFor(major: 3, minor: 13, patch: 0, keyIndex: 1)


    // MARK: - 3.14
    public static let disabledOnboardings = UserDefaultKeys.generateKeyFor(major: 3, minor: 14, patch: 0, keyIndex: 0)


    // MARK: - 3.15
//    public static let enableSearchHighlightV2 = UserDefaultKeys.generateKeyFor(major: 3, minor: 15, patch: 0, keyIndex: 0)
    public static let verifiesAllOnboardings = UserDefaultKeys.generateKeyFor(major: 3, minor: 15, patch: 0, keyIndex: 3)


    // MARK: - 3.16
    public static let clientVarSqlieVersion = UserDefaultKeys.generateKeyFor(major: 3, minor: 16, patch: 0, keyIndex: 0)
    public static let hadMigratePicToSyncCache = UserDefaultKeys.generateKeyFor(major: 3, minor: 16, patch: 0, keyIndex: 1)
    public static let hadCleanCacheService = UserDefaultKeys.generateKeyFor(major: 3, minor: 16, patch: 0, keyIndex: 2)
    


    // MARK: - 3.17
    public static let didOpenOneDocsFile = UserDefaultKeys.generateKeyFor(major: 3, minor: 17, patch: 0, keyIndex: 0)
    public static let dragAndDropEnable = UserDefaultKeys.generateKeyFor(major: 3, minor: 17, patch: 0, keyIndex: 1)


    // MARK: - 3.18
//    public static let enableDelayLoadDB = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 1)
    public static let enableDocsLauncherV2 = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 2)  // 是否使用启动管理框架
    public static let monitorInterval = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 3)  // 启动框架闲时监控时间
    public static let leisureCondition = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 4)  // cpu 判断闲时百分比
    public static let shareToOtherAppEnable = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 5)
    public static let exDomainConfigKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 6)
    public static let domainPoolKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 7)
    public static let docsAbandonOverseaEnable = UserDefaultKeys.generateKeyFor(major: 3, minor: 18, patch: 0, keyIndex: 8)


    // MARK: - 3.19
    public static let preloadJSModuleInfo = UserDefaultKeys.generateKeyFor(major: 3, minor: 19, patch: 0, keyIndex: 1)

    // MARK: - 3.19 LarkDocs
    public static let helpdeskConfigKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 19, patch: 0, keyIndex: 51)


    // MARK: - 3.20
    public static let commentCardUseDebugSetting = UserDefaultKeys.generateKeyFor(major: 3, minor: 20, patch: 0, keyIndex: 0)
    public static let commentCardUIDebugValue = UserDefaultKeys.generateKeyFor(major: 3, minor: 20, patch: 0, keyIndex: 1)
    public static let grammarCheckEnabled = UserDefaultKeys.generateKeyFor(major: 3, minor: 20, patch: 0, keyIndex: 4)
    public static let shareLinkToastURL = UserDefaultKeys.generateKeyFor(major: 3, minor: 20, patch: 0, keyIndex: 5)


    // MARK: - 3.21
    public static let bitableEnabled = UserDefaultKeys.generateKeyFor(major: 3, minor: 21, patch: 0, keyIndex: 0)  // 独立 bitable 是否启用
    public static let domainPoolV2Key = UserDefaultKeys.generateKeyFor(major: 3, minor: 21, patch: 0, keyIndex: 1)
    public static let sqlcipherVersionDic = UserDefaultKeys.generateKeyFor(major: 3, minor: 21, patch: 0, keyIndex: 3)


    // MARK: - 3.22
    public static let showPermissiontTipsEnabled = UserDefaultKeys.generateKeyFor(major: 3, minor: 22, patch: 0, keyIndex: 0)
    public static let leisureTimes = UserDefaultKeys.generateKeyFor(major: 3, minor: 22, patch: 0, keyIndex: 2)  // cpu触发闲时任务判断次数

    // MARK: - 3.26
    public static let sqlcipherKeyFailCount = UserDefaultKeys.generateKeyFor(major: 3, minor: 26, patch: 0, keyIndex: 1)


    // MARK: - 3.28
    public static let historyInstallVersion = UserDefaultKeys.generateKeyFor(major: 3, minor: 28, patch: 0, keyIndex: 0)


    // MARK: - 3.30
    public static let isQMAccount = UserDefaultKeys.generateKeyFor(major: 3, minor: 30, patch: 0, keyIndex: 0)


    // MARK: - 3.33
    public static let enterSheetLandscapeToastShowCount = UserDefaultKeys.generateKeyFor(major: 3, minor: 33, patch: 0, keyIndex: 0)
    public static let hadMigrateSyncPicToLarkCache = UserDefaultKeys.generateKeyFor(major: 3, minor: 33, patch: 0, keyIndex: 1)

    // MARK: - 3.34
    public static let debugUploadImgByDocRequest = UserDefaultKeys.generateKeyFor(major: 3, minor: 34, patch: 0, keyIndex: 1)
    public static let voiceCommentSelectLanguage = UserDefaultKeys.generateKeyFor(major: 3, minor: 34, patch: 0, keyIndex: 2)

    // MARK: - 3.35
    public static let sheetPreFetchData = UserDefaultKeys.generateKeyFor(major: 3, minor: 35, patch: 0, keyIndex: 0) //预拉取sheet数据在render传入
    public static let widescreenModeLastSelected = UserDefaultKeys.generateKeyFor(major: 3, minor: 35, patch: 0, keyIndex: 1) //正文模式最后选择类型

    // MARK: - 3.39
    public static let disableRustRequest = UserDefaultKeys.generateKeyFor(major: 3, minor: 39, patch: 0, keyIndex: 0) // 禁止走Rust请求
    public static let exportDocumentNewTag = UserDefaultKeys.generateKeyFor(major: 3, minor: 39, patch: 0, keyIndex: 1) // 是否使用过导出能力
    
    // MARK: - 3.40
    public static let hadShowTodoRedPoint = UserDefaultKeys.generateKeyFor(major: 3, minor: 40, patch: 0, keyIndex: 1)  // space首页todo位置的红点

    // MARK: - 3.43
    public static let enableEtTest = UserDefaultKeys.generateKeyFor(major: 3, minor: 43, patch: 0, keyIndex: 0) // 是否使用前端ETTest

    // MARK: - 3.45
    public static let ipadCommentUseOldDebug = UserDefaultKeys.generateKeyFor(major: 3, minor: 45, patch: 0, keyIndex: 0)
    public static let saveAsTemplateClickKey = UserDefaultKeys.generateKeyFor(major: 3, minor: 45, patch: 0, keyIndex: 1) + (User.current.info?.userID ?? "")// 是否点击过more面板的保存为自定义模板, 用于判断小红点是否展示
    public static let hadAskVoicePermission = UserDefaultKeys.generateKeyFor(major: 3, minor: 45, patch: 0, keyIndex: 2)

    // MARK: - 4.00
    public static let docxIpadCatalogDisplayLastScene = UserDefaultKeys.generateKeyFor(major: 4, minor: 0, patch: 0, keyIndex: 0)

    // MARK: - 4.4.0
    public static let disableFilterBOMChar = UserDefaultKeys.generateKeyFor(major: 4, minor: 4, patch: 0, keyIndex: 0)

    // MARK: - 4.6.0
    // more面板suspend按钮是否显示
    public static let documentSuspendNewTag = UserDefaultKeys.generateKeyFor(major: 4, minor: 5, patch: 0, keyIndex: 0)
    // 导航栏more按钮红点 Native控制要不要显示，建议后面大家都是用这个，产品侧暂时没人力去梳理这块，后续会安排专项去搞，不用了可以废弃
    public static let navMoreNewTag = UserDefaultKeys.generateKeyFor(major: 4, minor: 5, patch: 0, keyIndex: 1)

    // MARK: - 4.7.0
    public static let nativeEditorUseDebugSetting = UserDefaultKeys.generateKeyFor(major: 4, minor: 7, patch: 0, keyIndex: 0)
    public static let docxUseNativeEditorInDebug = UserDefaultKeys.generateKeyFor(major: 4, minor: 7, patch: 0, keyIndex: 1)
    
    // MARK: - 5.2.0
    public static let userBusinessInfo = UserDefaultKeys.generateKeyFor(major: 5, minor: 2, patch: 0, keyIndex: 0)

    // MARK: - 5.2
    public static let lynxTemplateSourceURL = UserDefaultKeys.generateKeyFor(major: 5, minor: 2, patch: 0, keyIndex: 1)
    
    // MARK: - 5.6
    public static let wikiAnnouncement = UserDefaultKeys.generateKeyFor(major: 5, minor: 6, patch: 0, keyIndex: 0)
    
    // MARK: - 5.10
    // more面板分享按钮是否显示红点
    public static let documentShareNewTag = UserDefaultKeys.generateKeyFor(major: 5, minor: 10, patch: 0, keyIndex: 0)
    
    // MARK: - 5.14
    public static let lynxCustomPkgEnable = UserDefaultKeys.generateKeyFor(major: 5, minor: 14, patch: 0, keyIndex: 0)
    
    // MARK: - 5.16
    public static let commentDebugValue = UserDefaultKeys.generateKeyFor(major: 5, minor: 16, patch: 0, keyIndex: 0)
    /// Bitable 展示系统通讯录免责提示
    public static let bitableReadContactNotice = UserDefaultKeys.generateKeyFor(major: 5, minor: 16, patch: 0, keyIndex: 1)
    
    // MARK: - 5.18
    public static let localFileValue = UserDefaultKeys.generateKeyFor(major: 5, minor: 18, patch: 0, keyIndex: 1)
    
    // MARK: - 5.26
    /// more面板版本管理入口提示
    public static let docsVersionValue = UserDefaultKeys.generateKeyFor(major: 5, minor: 26, patch: 0, keyIndex: 1)
    /// 打开文档时命中ssr和clientVar缓存弹toast
    public static let enableSSRCahceToastForTest = UserDefaultKeys.generateKeyFor(major: 5, minor: 26, patch: 0, keyIndex: 2)

    public static let spaceMyFolderToken = UserDefaultKeys.generateKeyFor(major: 5, minor: 29, patch: 0, keyIndex: 1)
    
    // MARK: - 6.0
    public static let adPermImageOverloadStaticDomainKey = UserDefaultKeys.generateKeyFor(major: 6, minor: 0, patch: 0, keyIndex: 1)
    public static let bitableShareNoticeLearnMoreDomain = UserDefaultKeys.generateKeyFor(major: 6, minor: 0, patch: 0, keyIndex: 2)
    
    // MARK: - 6.8
    public static let keepSSRWebViewAliveForTest = UserDefaultKeys.generateKeyFor(major: 6, minor: 8, patch: 0, keyIndex: 1)


    // MARK: - 6.9
    /// more面板文档时效性入口提示
    public static let docsFreshness = UserDefaultKeys.generateKeyFor(major: 6, minor: 9, patch: 0, keyIndex: 0)
    /// more面板反馈内容过期入口提示
    public static let reportOutdated = UserDefaultKeys.generateKeyFor(major: 6, minor: 9, patch: 0, keyIndex: 1)
    
    // MARK: - 7.3
    public static let baseRecommendCache = UserDefaultKeys.generateKeyFor(major: 7, minor: 3, patch: 0, keyIndex: 1)
    
    // MARK: - 7.6
    public static let accociateAppBadgeIsShow = UserDefaultKeys.generateKeyFor(major: 7, minor: 6, patch: 0, keyIndex: 1)
    
    public static func registureDefault() {
        var defaultValues = [String: Any]()
        defaultValues[UserDefaultKeys.isNewDomainSystemKey] = true
        defaultValues[UserDefaultKeys.preloadPictureWifiOnly] = true
        CCMKeyValue.globalUserDefault.register(defaults: defaultValues)
        if let oldRecentKey = CCMKeyValue.globalUserDefault.data(forKey: UserDefaultKeys.recentSyncMetaInfoKey) {
            CCMKeyValue.globalUserDefault.set(oldRecentKey, forKey: UserDefaultKeys.recentSyncMetaInfoKeyNew)
            CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.recentSyncMetaInfoKey)
        }
        let firstLaunchTime = CCMKeyValue.globalUserDefault.double(forKey: UserDefaultKeys.firstLanuchTimeKey)
        if firstLaunchTime != 0 {
            DocsLogger.info("first launch time \(firstLaunchTime)")
        } else {
            let current = Date().timeIntervalSince1970
            CCMKeyValue.globalUserDefault.set(current, forKey: UserDefaultKeys.firstLanuchTimeKey)
            DocsLogger.info("set launch time \(current)")
        }
    }
}
