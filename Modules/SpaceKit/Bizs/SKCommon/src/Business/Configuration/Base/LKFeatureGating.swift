//
//  LKFeatureGating.swift
//  SpaceKit
//
//  Created by duanxiaochen.7 on 2020/3/11.
//  swiftlint:disable file_length
//⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
import Foundation
import SKFoundation
import LarkAppConfig
import LarkSetting
import SKUIKit
import SKInfra
//⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
public enum LKFeatureGating {

//    @CCMUserScopeFG(key: "spacekit.mobile.docs_diy_icon")
//    public static var docsDIYIconEnabled: Bool

    // 3.33 space列表刷新优化
    @CCMUserScopeFG(key: "spacekit.spacelist.reload.optimization")
    public static var spaceDiffReloadEnable: Bool

    // MARK: - 3.34
    // 3.34 工具栏加号block中的公式 FG
    @CCMUserScopeFG(key: "spacekit.mobile.doc_block_equation_enable")
    public static var blockEquationEnable: Bool

    //公式是否可编辑
    @CCMUserScopeFG(key: "spacekit.mobile.doc_block_equation_editable")
    public static var blockEquationEditable: Bool

    // MARK: - 3.35

    // V4 模板中心 企业模板入口
    @CCMUserScopeFG(key: "spacekit.mobile.template_optimization_v4_business")
    public static var templateV4BusinessEnable: Bool

    // MARK: - 3.39
    //RN 加载前端资源包出错时，进行兜底处理
    @CCMUserScopeFG(key: "spacekit.rn_load_res_saver_enable")
    public static var rnReloadResSaverEnable: Bool

    // MARK: - 3.41
    // 新建文档启用离线创建
    @CCMUserScopeFG(key: "spacekit.mobile.docs_enable_locally_create")
    public static var enableLocallyCreate: Bool

    // prelease ccm群命中
    @CCMUserScopeFG(key: "ccm_gray.client.ccm")
    public static var preleaseCcmGrayFG: Bool

    // prelease lark群命中
    @CCMUserScopeFG(key: "ccm_gray.client.lark")
    public static var preleaseLarkGrayFG: Bool

    // MARK: - 3.47

    /// 控制私有化 KA 是否具有 Bitable 进云空间功能，包括路由，预加载，列表页，新建入口, @ 面板
    @CCMUserScopeFG(key: "ccm.spacekit.bitable.enable")
    public static var bitableEnable: Bool
    
    /// 控制私有化 KA 是否有 Bitable 进模板中心，模板中心过滤选项
    @CCMUserScopeFG(key: "ccm.spacekit.template.bitable.enable")
    public static var bitableTemplateEnable: Bool

    // MARK: - docx接入模版中心
    /// 模板中心是否支持docx
    @CCMUserScopeFG(key: "spacekit.mobile.template_docx")
    public static var templateDocXEnable: Bool

    /// docx是否支持保存为自定义模板
    @CCMUserScopeFG(key: "spacekit.mobile.template_docx_save_to_custom")
    public static var templateDocXSaveToCustomEnable: Bool
    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: - 4.0
    //单容器需求 收藏列表、快速访问是否使用v2接口
    @CCMUserScopeFG(key: "ccm.space.api_v2")
    public static var quickAccessOrStarUseV2Api: Bool

    // MARK: - 4.2

    // DocX 支持新建
    @CCMUserScopeFG(key: "spacekit.mobile.docx_create_enable", isStatic: false)
    public static var createDocXEnable: Bool

    // MARK: - 4.4
    /// docx 是否支持导出
    @CCMUserScopeFG(key: "docx_export_enabled", isStatic: false)
    public static var docxExportEnabled: Bool

    // MARK: - 4.6
    /// more面板举报能力
    @CCMUserScopeFG(key: "spacekit.mobile.space_report_enable")
    public static var spaceReportEnable: Bool

    // Docx使用native编辑器
    @CCMUserScopeFG(key: "spacekit.mobile.native_docx_enable")
    public static var nativeDocxEnable: Bool

    /// docx是否支持历史记录入口
    @CCMUserScopeFG(key: "spacekit.mobile.docx_history_enable", isStatic: false)
    public static var docxHistoryEnable: Bool

    /// docx是否可以使用离线可用能力
    @CCMUserScopeFG(key: "spacekit.mobile.docx_manual_offline_enabled", isStatic: false)
    public static var docxManualOfflineEnabled: Bool

    /// 展示“客服”Doc内入口
    @CCMUserScopeFG(key: "suite_help_service_doc")
    public static var suiteHelpServiceDoc: Bool

    /// doc文件转在线文档为doc1.0还是2.0
    @CCMUserScopeFG(key: "ccm.suite.docx_import_enabled", isStatic: false)
    public static var docxImportEnabled: Bool
    @CCMUserScopeFG(key: "docx_enabled", isStatic: false)
    public static var docxEnabled: Bool

    // MARK: 4.11
    /// 控制iOS13系统飞书文档是否启用前后切换触发的相关逻辑
    @CCMUserScopeFG(key: "ccm.doc.foreground_switch_logic_enable")
    public static var foregroundSwitchLogicEnable: Bool

    /// Wiki所有知识库新UI
    @CCMUserScopeFG(key: "spacekit.mobile.wiki2.0_space_classify_enable")
    public static var wikiNewWorkspace: Bool

    /// 云空间大文件上传兜底
    @CCMUserScopeFG(key: "ccm.drive.size_limit_enable")
    public static var sizeLimitEnable: Bool

    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: 5.2
    /// 是否支持正文 Dark Mode
    @CCMUserScopeFG(key: "ccm.theme.mobile_darkmode_enable")
    public static var webviewDarkmodeEnabled: Bool
    
    /// docx是否启用ssr功能
    @CCMUserScopeFG(key: "ccm.docx.ssr_mobile_app")
    public static var docxSSREnable: Bool

    // MARK: - 5.3

    @CCMUserScopeFG(key: "ccm.docs.follow_comment_enable")
    public static var followCommentEnable: Bool

    // 文档内图片根据展示尺寸拉取cover
    @CCMUserScopeFG(key: "spacekit.mobile.docs_driveimage_cover_variable")
    public static var coverVariableFg: Bool

    /// 保存clientvar数据到本地内存优化
    @CCMUserScopeFG(key: "ccm.newcache.mobile.save_clientvar_memory_opt")
    public static var saveClientVarMemoryOpt: Bool

    // MARK: - 5.6
    ///文档密级
    @CCMUserScopeFG(key: "ccm.permission.mobile.sensitivty_label")
    public static var sensitivtyLabelEnable: Bool

    ///wiki 单页面owner
    @CCMUserScopeFG(key: "ccm.wiki.mobile.single_page_owner")
    public static var wikiSinglePageOwner: Bool

    /// wps中台版
    @CCMUserScopeFG(key: "spacekit.mobile.drive_wps_center_version_enable", isStatic: false)
    public static var wpsCenterVersionEnable: Bool

    // MARK: 5.7
    ///企业密钥删除
    @CCMUserScopeFG(key: "spacekit.mobile.cipher_delete_enable")
    public static var cipherDeleteEnable: Bool

    ///取消延迟释放jsb
    @CCMUserScopeFG(key: "spacekit.mobile.cancel_delay_release_jsb")
    public static var cancelDelayReleaseJsbFg: Bool

    // MARK: - 5.8
    ///支持表情面板对11个手势表情更换不同肤色
    @CCMUserScopeFG(key: "messenger.message_emoji_skinstones")
    public static var reactionSkinTonesEnable: Bool

    /// DocX 更多菜单是否展示“查找”功能入口
    @CCMUserScopeFG(key: "ccm.doc.moblie.find", isStatic: false)
    public static var docxSearchEnable: Bool

    ///禁止延迟展示评论面板
    @CCMUserScopeFG(key: "ccm.doc.mobile.disable_comment_delay_show")
    public static var disableCommentDelayFg: Bool

    // MARK: - 5.9
    ///sheetSSR
    @CCMUserScopeFG(key: "ccm.sheet.mobile.enable.ssr")
    public static var sheetSSRFg: Bool
    /// 新“共享空间”
    @CCMUserScopeFG(key: "ccm.space.newsharespace", isStatic: false)
    public static var newShareSpace: Bool

    /// 是否开启防止截图&录屏功能(文档、drive无复制权限时)
    @CCMUserScopeFG(key: "spacekit.mobile.screen_capture_prevent_enable")
    public static var screenCapturePreventEnable: Bool

    /// wiki feed推荐页入口是否跳过admin管控
    @CCMUserScopeFG(key: "ccm.wiki.recommend_feed_can_skip_admin_status", isStatic: false)
    public static var wikiFeedSkipAdmin: Bool

    @CCMUserScopeFG(key: "ccm.gpe.comment.optimize.loading_and_fail_mobile")
    public static var loadingAndFailMobileOptimize: Bool

    /// 是否开启Webview卡死检测
    @CCMUserScopeFG(key: "ccm.mobile.webview_check_responsive_enable")
    public static var webviewCheckResponsiveEnable: Bool

    // IM加号面板支持新建DocX
    @CCMUserScopeFG(key: "ccm.mobile.im_create_docx_enable", isStatic: false)
    public static var imCreateDocXEnable: Bool
    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: - 5.14
    // 文档保留标签入口
    @CCMUserScopeFG(key: "ccm.permission.mobile.retention", isStatic: false)
    public static var retentionEnable: Bool

    // MARK: - 5.16
    /// 是否开启fetch接口中iframeJsCheck字段检查逻辑
    @CCMUserScopeFG(key: "ccm.iframe_jsb.check", isStatic: false)
    public static var docsCheckIframeJsbEnable: Bool

    /// 是否支持级联选项设置
    @CCMUserScopeFG(key: "bitable.select_field.dynamic_enabled", isStatic: false)
    public static var bitableDynamicOptionsEnable: Bool

    // MARK: - 5.17
    // bitable地理字段
    @CCMUserScopeFG(key: "bitable.field.location", isStatic: false)
    public static var bitableGeoLocationFieldEnable: Bool

    /// 剪存功能: 前端根据开关切换逻辑
    @CCMUserScopeFG(key: "ccm.docs.clip_specify_enable", isStatic: false)
    public static var clipSpecifyEnable: Bool

    /// 剪存功能: 是否显示入口
    @CCMUserScopeFG(key: "ccm.docs.clip_enable", isStatic: false)
    public static var clipDocEnable: Bool

    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: - 5.19
    /// bitable 高级权限
    @CCMUserScopeFG(key: "bitable.template.bitable_advanced_permission_mobile", isStatic: false)
    public static var bitableAdvancedPermission: Bool

    /// wikiToken更新时替换正在打开的wiki文档token
    @CCMUserScopeFG(key: "spacekit.mobile.refresh_wiki_token_on_fetch", isStatic: false)
    public static var refreshWikiTokenOnFetch: Bool

    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: - 5.21
    /// 通过文档权限点位控制用户查看文档协同头像、点赞头像和光标信息
    @CCMUserScopeFG(key: "ccm.permission.set_user_restricted_client", isStatic: false)
    public static var setUserRestrictedEnable: Bool

    //密级降级审批开关
    @CCMUserScopeFG(key: "ccm.permisson.degrade_approval", isStatic: false)
    public static var degradeApproval: Bool

    // 移动端插入超链接开关
    @CCMUserScopeFG(key: "ccm.docx.enable.mobile.hyperlink", isStatic: false)
    public static var hyperLinkEnable: Bool
    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增

    // Phoenix 总开关
    @CCMUserScopeFG(key: "ccm.workspace.phoenix", isStatic: false)
    public static var phoenixEnabled: Bool
    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    public static var ccmios16Orientation: Bool {
        guard SKDisplay.phone else {
            DocsLogger.info("not iphone has no system bug")
            return false
        }
        var settingsArray: [String]?
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_mobile_system_bugfix"))
            if let systemVersions = settings["orientationBugFixSystemVersions"] {
                if let array = systemVersions as? [String] {
                    settingsArray = array
                } else {
                    DocsLogger.error("systemVersions is not string array")
                }
            } else {
                DocsLogger.error("settings has no systemVersions")
            }
        } catch {
            DocsLogger.error("ccmios16Orientation get settings error", error: error)
            return false
        }
        guard let settingsArray = settingsArray else {
            DocsLogger.info("has no settings,not fix system bug")
            return false
        }
        let systemVersion = UIDevice.current.systemVersion
        let va = settingsArray.contains(systemVersion)
        DocsLogger.info("settingsArray is \(settingsArray), systemVersion is \(systemVersion)")
        return va
    }

    // 是否只用水印sdk的水印
    @CCMUserScopeFG(key: "ccm.watermark.enable_use_lark_water_mark_sdk", isStatic: false)
    public static var enabelUseLarkWaterMarkSDK: Bool

    @CCMUserScopeFG(key: "ccm.doc.dlp_enable", isStatic: false)
    public static var docDlpEnable: Bool

    //⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
    // MARK: - 5.24
    // 是否支持横屏
    @CCMUserScopeFG(key: "ccm_docx_mobile.screen_view_horizental", isStatic: false)
    public static var enableScreenViewHorizental: Bool

    //原图/非原图上传
    @CCMUserScopeFG(key: "ccm.drive.mobile.video_compress", isStatic: false)
    public static var ccmDriveMobileVideoCompress: Bool

    @CCMUserScopeFG(key: "ccm.permission.mobile.sensitivty_label", isStatic: false)
    public static var sensitivtyOptimizationEnable: Bool

    @CCMUserScopeFG(key: "ccm.mobile.sensitivitylabel.forcedlabel", isStatic: false)
    public static var sensitivityLabelForcedEnable: Bool
    // 复制保护
    @CCMUserScopeFG(key: "spacekit.mobile.common.copy_security_enable", isStatic: false)
    public static var securityCopyEnable: Bool

    // 空间设置成员分组
    @CCMUserScopeFG(key: "ccm.permission.mobile.wiki_member", isStatic: false)
    public static var wikiMemberEnable: Bool
}
//⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
extension LKFeatureGating {

    @CCMUserScopeFG(key: "spacekit.mobile.slide_enabled")
    public static var slideEnabled: Bool

    // bear-mobile 移动端iOS自带纠错是否开启
    @CCMUserScopeFG(key: "spacekit.mobile.system_grammaZSr_check_on_ios_enabled")
    private static var _systemGrammarCheckOnIOSEnabled: Bool
    public static var systemGrammarCheckOnIOSEnabled: Bool {
        return _systemGrammarCheckOnIOSEnabled
    }

    @CCMUserScopeFG(key: "mindnote_enabled")
    private static var _mindnoteEnable: Bool
    public static var mindnoteEnable: Bool {
        if DomainConfig.envInfo.isFeishuBrand {
            // mindnote 国内已经GA, 如果需要改动此处逻辑，请先 找周源 or mindnote 团队的同学 review
            DocsLogger.info("DocsType.mindnote.fg --- updating mindnote fg final using value: \(true), using env config not isOversea")
            return true
        }
        if checkNeedUseFGValue(for: "mindnote_enabled") {
            DocsLogger.info("DocsType.mindnote.fg --- updating mindnote fg using LKFeatureGating cache value: \(_mindnoteEnable)")
            return _mindnoteEnable
        }
        return LKFeatureGating.mindnoteEnable
    }

    /// LKFG 首次拉取key的时候，value都是false，为了让mina value 为true 的用户无感知升级事件，对上面几个key做特殊处理
    /// V3.43新增，在V3.50 的时候可以删除，直接使用LKFeature获取到的值, 但是mindnote要保留
    private static func checkNeedUseFGValue(for key: String) -> Bool {
        guard let uid = User.current.info?.userID, !uid.isEmpty else {
            return true
        }
        defer {
            CCMKeyValue.userDefault(uid).set(true, forKey: "DocsCoreDefaultPrefix_\(key)")
        }
        if CCMKeyValue.userDefault(uid).bool(forKey: "DocsCoreDefaultPrefix_\(key)") {
            return true
        }
        // 如果是卸载重装，使用mina还是FG，都一样
        return false
    }
}
//⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
// MARK: - 评论模块
extension LKFeatureGating {
}

//extension LKFeatureGating {
//    /// 缓存起来，并且次FG已经关闭，对及时性要求不高
//    public static let isDiyIconEnable = docsDIYIconEnabled
//}
//⚠️此文件请不要再新增内容，请去SKFoundation Pod的 UserScopeNoChangeKeys.swift 和 RealTimeKeys.swift 新增
