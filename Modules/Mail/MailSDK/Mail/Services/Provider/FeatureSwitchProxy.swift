//
//  FeatureSwitchProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/19.
//

import Foundation
import RxSwift
import LarkContainer

public struct FeatureKey {
    let fgKey: FeatureGatingKey
    let openInMailClient: Bool

    // 三方需要强制打开的功能入口
    func forceOpenInMailClient() -> Bool {
        return fgKey == .enterpriseSignature
    }
}

public enum FeatureGatingKey: String {
    case messageListRotate = "larkmail.cli.messagelist.supportrotate"   //支持横屏阅读
    case translation = "larkmail.cli.translation"   //翻译
    case poolActiveReset = "larkmail.mobile.editor.reset"   //重用池重新创建问题
    case translateRecommend = "larkmail.cli.translaterecommend" //translate recommend switch
    case nativeRender = "larkmail.cli.messagelist.nativerender.enable"  //同层渲染
    case larkSmartCompose = "suite.ai.smart_compose.mobile.enabled" //smart_compose
    case editorTimeoutReload = "larkmail.cli.timeout.reload.editor" //超时重试reload editor
    case readMailLazyLoadItem = "larkmail.cli.mobile.readmail.lazyloaditem" //是否懒加载 itemContent
    case asyncRender = "larkmail.cli.asyncrender"   //LarkMail iOS 首页Thread List异步渲染开关
    case sendSeparaly = "larkmail.cli.send_separately"  //邮箱是否开启分别发送
    case gmailFolder = "larkmail.cli.folder_gmail"  //针对gmail授权用户开通文件夹功能
    case contactCards = "contact.contactcards.email"    //联系人卡片
    case preloadMail = "larkmail.cli.readmail.preloadmail"  //读信优化-点击预加载mailItem
    case unreadPreloadMail = "mail.readmail.ios.unreadpreload"   //读信优化-未读预加载
    case readMailFirstScreen = "mail.readmail.ios.firstscreen" //读信优化-首帧渲染
    case largeAttachment = "larkmail.cli.largefile.phase2"
    case quoteStyle = "larkmail.cli.column_quote_style" //写信回复，引用区域样式改版
    case mentionAddAddress = "larkmail.cli.mention.addto" //写信提及是否要添加到to中
    case autoSaveDraft = "larkmail.cli.draft.autosave" //写信时自动保存草稿
    case aiBlock = "larkmail.cli.hide_ai_point"
    case deleteExtern = "larkmail.cli.deleteexternaladdress"    //写信删除外部联系人fg
    case copyDrivePic = "larkmail.cli.image.multi.copy" // 写信paste docs图片
    case conversationModeInternal = "larkmail.cli.non_conversation_mode_internal" // 非会话模式内部fg
    case mailPicker = "larkmail.cli.mailpicker" // 邮箱联系人picker入口
    case sendStatus = "lark.mail.send_status"
    case mobileEditorKit = "larkmail.cli.mobile_editor_kit" // 新 editor kit
    case autoTranslateAttachment = "larkmail.cli.auto_translate_attachment" //自动转超大附件
    case moreFonts = "larkmail.cli.support_more_fonts"
    case conversationModeTips = "larkmail.cli.conversation_onboarding" // Conversation引导
    case mailClient = "larkmail.cli.mail_client"
    case conversationSetting = "larkmail.cli.conversation_setting" // conversation设置页
    case enterpriseSignature = "larkmail.cli.enterprise.signature"// 企业签名
    /// 对单封message删除
    case trashMessage = "larkmail.cli.trashmessage"
    case copyBlob = "larkmail.cli.image.message.copy"
    case htmlBlock = "larkmail.cli.new_html_block"
    case grayHistoryQuote = "mail.client.gray_block_history_quote"
    case defaultFontSize = "larkmail.cli.default_font_size" // 编辑器增加默认字号大小
    case editorReuseDom = "larkmail.cli.editor_reuse_dom" // 编辑器复用DOMParser结果
    case editorCacheDraft = "larkmail.cli.cache_draft_mobile" // 编辑器保存草稿时缓存DeltaSet
    case editorListStylePositionOutside = "larkmail.cli.editor_list_outside" // 编辑器有序/无序列表的文字超长换行时，序号/点是否在文字外面
    case editorNewInlineStyleInherit = "larkmail.cli.editor_style_override" // 编辑器新样式继承方案
    case longDeleteBackward = "larkmail.cli.editor_long_delete_backward" // 编辑器长按删除键支持批量删除
    case preRender = "larkmail.cli.editor.pre_render"   // 新邮件提前加载
    case replyAttachment = "larkmail.cli.reply_add_attachment" //回复带附件
    case mailCover = "larkmail.cli.mail_cover"   // 读信有邮件封面
    case editMailCover = "larkmail.cli.mail_edit_cover"   // 写信有邮件封面
    case fgNotifyUseApi = "larkmail.cli.fg_notify_use_api"
    case mailClientOAuthLoginExchange = "larkmail.cli.mail_client_oauth_login_exchange"
    case mailClientOAuthLoginO365 = "larkmail.cli.mail_client_oauth_login_office365"
    case mailClientOAuthLoginGmail = "larkmail.cli.mail_client_oauth_login_gmail"
    case mailCheckBlank = "larkmail.cli.blank_check"
    case mailCheckBlankOptDisable = "larkmail.cli.blank_check.opt.disable"

    /// 读信页尺寸变化后重新进行scale，如iPad旋转
    case rescaleOnResize = "mail.readmail.rescaleonresize"
    case sendMailCalendar = "larkmail.cli.calendar_invite"
    case clientSearchContact = "larkmail.cli.mail_client_search"   // 三方支持联系人搜索
    case openBotDirectly = "larkmail.cli.open_bot_notification_directly" // 点击新邮件bot通知直接展示

    case labelListNotice = "larkmail.cli.label_list_notice"
    //超大附件提示增强，size计算逻辑优化
    case largefileUploadOpt = "larkmail.cli.largefile.upload_opt"
    case uniStore = "larkmail.cli.mail_uni_store"
    /// 读信加载缩略图优化
    case loadThumbImageEnable = "larkmail.cli.mail.load_image_thumb"
    ///  读信正文图图片预加载
    case preloadMailImageEnable = "larkmail.cli.preload_thumb_image"
    /// 读信正文图片加载流程优化
    case optimizeImgDownload = "larkmail.cli.optimize_image"
    /// 支持图片下载队列
    case enableImageDownloadQueue = "larkmail.cli.mail.web_image_queue"
    case labelListNoticeRedDot = "larkmail.cli.label_list_notice_red_dot"
    case newOutbox = "larkmail.cli.new_outbox"

    /// 是否拦截WebViewHTTP下载请求
    case interceptWebViewHttp = "mail.ios_webview.intercept_http"
    case encryptCache = "larkmail.cli.encrypt_img"
    case signatureEditable = "larkmail.cli.signature_editable"

    case newSpamPolicy = "larkmail.cli.spam_policy_optimization"

    /// 离线阅读/搜索
    case offlineSearch = "larkmail.search.offline_search"

    /// 首屏loading出现时机调整
    case homeSpeedupLoading = "larkmail.cli.home_speedup_loading"
    case securityFile = "larkmail.cli.security_file" // 文件安全检测
    case calendarRsvpReply = "calendar.rsvp.replyui" // 日程回复留言交互优化

    case draftContentHTMLDecode = "larkmail.cli.draft_content_bodyhtml_decode" // 在新版本去除了bodyHTML的处理，用于保险回退
    case replaceAddressName = "larkmail.cli.mail_address_name"
    case ignoreMe = "larkmail.cli.mail_address_isme"

    case darkMode = "larkmail.cli.dark_mode"
    /// 页面适配优化
    case scaleOptimize = "mail.readmail.scaleoptimize"
    /// 页面适配性能优化
    case scalePerformance = "mail.readmail.improve_scale_performance"
    case longTextOptimize = "mail.readmail.long_text_optimize"
    case doubleTab = "larkmail.cli.double_click_tab"
    case cleanTrashTip = "larkmail.cli.auto_clean_trash_tip"

    case stranger = "larkmail.cli.mail.stranger_v2"
    case threadCustomSwipeActions = "larkmail.cli.custom_swipe_actions"
    case interceptWebImage = "larkmail.cli.web_image_blocking"
    case interceptWebImagePhase2 = "larkmail.cli.web_image_blocking_2"
    
    case offlineCache = "lark.mail.mail_cache"
    case offlineCacheImageAttach = "lark.mail.mail_cache_attachment_image"
    case tabUnreadCountApply = "larkmail.cli.tab_unread_count.apply"
    case tabUnreadCount = "larkmail.cli.tab_unread_count"
    case eas = "larkmail.cli.eas"
    case largeAttachmentManage = "larkmail.cli.large_attachment_manage"
    case largeAttachmentManagePhase2 = "larkmail.cli.mail.large_attachment_manage_phase2" // 超大附件管理2期
    case disableAccountValidCheck = "larkmail.cli.disable_account_valid_check"
    
    case bitsCiIn = "larkmail.cli.native_mail_template.bits_ci_in" // 是否启用读信模板pod集成

    /// 支持所有用户在 Lark 上绑定邮箱
    case newFreeBindMail = "larkmail.cli.lark_free_bind"
    case newFreeBindGMail = "larkmail.cli.lark_free_bind_gmail"
    case newFreeBindExchange = "larkmail.cli.lark_free_bind_exchange"
    case newFreeBindIMAP = "larkmail.cli.lark_free_bind_imap"
    case emlAsAttachment = "larkmail.cli.eml_as_attachment"

    case searchTrashSpam = "larkmail.cli.search.trash_and_spam_search" // 搜索支持已删除举报邮件
    case massiveSendRemind = "larkmail.cli.massive_send_remind" // 大规模发送邮件支持弹窗提醒
    case repliedMark = "larkmail.cli.replied_mark" // 已回复标记
    case docAuthOpt = "larkmail.cli.doc_auth_opt"
    case applinkDelete = "larkmail.cli.enable_applink_delete_mail" // applink 删除邮件
    case riskBanner = "larkmail.cli.risk_banner" // 风险banner fg开 且 need_risk_tips为true(代表后端命中新逻辑) 的时候，使用新UI
    case attachmentLocation = "larkmail.cli.attachment_location" // 附件置顶
    case blockSender = "lark.mail.block_sender"
    case autoCC = "larkmail.cli.create_draft_cc_myself" // 自动抄送或密送自己
    case larkAI = "lark.my_ai.main_switch"
    case mailAI = "larkmail.cli.ai_inline_mode"
    case ChatAI = "larkmail.cli.ai_chat_mode"
    case promptOptAI = "larkmail.cli.ai_prompt_opt"
    case draftSync = "larkmail.cli.remote_draft_conflict" // 跨设备草稿同步问题处理
    case folderSort = "larkmail.cli.folder.sort.alphabetically"
    case sanitizeWebImage = "larkmail.cli.sanitizer_image_blocking"
    case mailAIOnboard = "larkmail.cli.ai_inline_mode.onboard"
    case replyLangOpt = "larkmail.cli.forward_reply_prefix_lang_opt"
    case settingUpdate = "larkmail.cli.ios_setting_incremental_update" // setting优化，改为增量更新
    case isolateOverflowContent = "larkmail.cli.readmail.isolate_overflow_content"
    case mailFPSOpt = "larkmail.cli.fps_opt"    //卡顿优化
    case pickerDepartment = "larkmail.cli.picker_select_department_mobile" // picker一键选择部门
    case mailSlardarWebClose = "larkmail.cli.slardar_eitor_close" //关闭写信页slardar监控，默认开启
    case unreadPreloadMailOpt = "larkmail.cli.ios_unreadpreload_opt"   // 读信未读预加载策略优化
    case groupShareReplace = "larkmail.rust.group_share_address_name_replace"
    case mailPriority = "larkmail.cli.enable_mail_priority" // 邮件重要程度
    case migrationDelegation = "larkmail.cli.migration_delegation" //显示搬家邮件的委托信息
    case mailAISmartReply = "larkmail.cli.ai_inline_mode.reply" //ai智能回复生成
    case revertScale = "larkmail.cli.readmail.revert_scale"
    case readReceipt = "larkmail.cli.read.receipt" // 已读回执
    case sendMailNameSetting = "larkmail.cli.setting_send_name_mobile"

    // imap migration
    case imapMigrationShowSettingView = "larkmail.cli.mail.imap_migration_setting" // 是否展示搬家设置提示界面
    case imapMigration = "larkmail.cli.mail.imap_migration" // 是否开启imap搬家能力
    
    case editorPerformance = "larkmail.cli.editor.performance" // 写信页开启性能监控
    case optimizeLargeMail = "larkmail.cli.readmail.improve_large_mail_performance" // 优化大会话性能
    case mailToFeed = "larkmail.cli.mail_to_feed" // mail进feed
    case replyCheckAddress = "larkmail.cli.reply_check_address_name" // 回复邮件检查
    case searchFilter = "larkmail.cli.search_filter"
    case openRag = "larkmail.cli.ai_chat_mode_rag"
    case aiHistoryLink = "larkmail.cli.ai_history_preview"
}

public protocol FeatureSwitchProxy {
    func getFeatureBoolValue(for key: String) -> Bool
    func getFeatureBoolValue(for key: FeatureGatingKey) -> Bool
    func getRealTimeFeatureBoolValue(for key: FeatureGatingKey) -> Bool
    func getFeatureNotify() -> Observable<Void>
}

struct FeatureManager {

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static var featureSwitchProvider: FeatureSwitchProxy? {
        if let featureSwitch = try? Container.shared.getCurrentUserResolver().resolve(assert: FeatureSwitchProxy.self) {
            return featureSwitch
        } else {
            mailAssertionFailure("[UserContainer] Access featureSwitch before user login")
            return nil
        }
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func open(_ feature: FeatureKey, provider: FeatureSwitchProxy? = nil) -> Bool {
        let featureSwitch = provider ?? featureSwitchProvider
        if Store.settingData.mailClient {
            if !feature.openInMailClient { // Feature不支持三方
                return false
            } else if feature.openInMailClient, feature.forceOpenInMailClient() { // 三方下需要强制打开该Feature
                return true
            }
        }

        // KA需要屏蔽的入口
        if feature.fgKey == .translation || feature.fgKey == .translateRecommend {
            return !(featureSwitch?.getFeatureBoolValue(for: .aiBlock) ?? false) &&
                featureSwitch?.getFeatureBoolValue(for: feature.fgKey) ?? false
        }
        // Feature支持三方则不做拦截，以fg为准
        return featureSwitch?.getFeatureBoolValue(for: feature.fgKey) ?? false
    }

    fileprivate static func convertExistFG(_ feature: FeatureGatingKey) -> FeatureKey {
        if feature == .contactCards {
            return Store.settingData.mailClient
            ? FeatureKey(fgKey: .mailClient, openInMailClient: true)
            : FeatureKey(fgKey: .contactCards, openInMailClient: false)
        }

        // 三方需要屏蔽的功能入口
        if feature == .copyDrivePic || feature == .largeAttachment || feature == .nativeRender
            || feature == .mailPicker || feature == .asyncRender || feature == .autoTranslateAttachment
            || feature == .translation || feature == .translateRecommend || feature == .editMailCover {
            return FeatureKey(fgKey: feature, openInMailClient: false)
        }

        return FeatureKey(fgKey: feature, openInMailClient: true)
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func open(_ feature: FeatureGatingKey, provider: FeatureSwitchProxy? = nil) -> Bool {
        return FeatureManager.open(convertExistFG(feature), provider: provider)
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func realTimeOpen(_ feature: FeatureGatingKey, provider: FeatureSwitchProxy? = nil) -> Bool {
        let featureSwitch = provider ?? featureSwitchProvider

        if feature == .enterpriseSignature && Store.settingData.mailClient {
            return true
        }
        return featureSwitch?.getRealTimeFeatureBoolValue(for: feature) ?? false
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func realTimeOpen(_ feature: FeatureGatingKey, openInMailClient: Bool, provider: FeatureSwitchProxy? = nil) -> Bool {
        var isMailClient = Store.settingData.mailClient
        if feature == .newFreeBindMail {
            isMailClient = realTimeOpen(.mailClient)
        }
        if !openInMailClient && isMailClient {
            return false
        } else {
            return realTimeOpen(feature)
        }
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func open(_ feature: FeatureGatingKey, openInMailClient: Bool) -> Bool {
        return FeatureManager.open(FeatureKey(fgKey: feature, openInMailClient: openInMailClient))
    }

    @available(*, deprecated, message: "Please use `featureManager` in MailUserContext or MailAccountContext!")
    static func getFeatureNotify() -> Observable<Void> {
        return (featureSwitchProvider?.getFeatureNotify() ?? Observable.empty()).observeOn(MainScheduler.instance)
    }
}

/// 获取用户相关的 fg
class UserFeatureManager {
    let featureSwitch: FeatureSwitchProxy?
    init(featureSwitch: FeatureSwitchProxy?) {
        self.featureSwitch = featureSwitch
    }

    func open(_ feature: FeatureKey) -> Bool {
        FeatureManager.open(feature, provider: featureSwitch)
    }

    @available(*, deprecated, message: "please use open(_ feature: FeatureKey) method, confirm that your feature is enabled in mail client.")
    func open(_ feature: FeatureGatingKey) -> Bool {
        FeatureManager.open(feature, provider: featureSwitch)
    }

    func realTimeOpen(_ feature: FeatureGatingKey) -> Bool {
        FeatureManager.realTimeOpen(feature, provider: featureSwitch)
    }

    func realTimeOpen(_ feature: FeatureGatingKey, openInMailClient: Bool) -> Bool {
        FeatureManager.realTimeOpen(feature, openInMailClient: openInMailClient, provider: featureSwitch)
    }

    func open(_ feature: FeatureGatingKey, openInMailClient: Bool) -> Bool {
        return open(FeatureKey(fgKey: feature, openInMailClient: openInMailClient))
    }

    func getFeatureNotify() -> Observable<Void> {
        return (featureSwitch?.getFeatureNotify() ?? Observable.empty()).observeOn(MainScheduler.instance)
    }
}

extension FeatureManager {
    static func enableSystemFolder() -> Bool {
        let protocl = Store.settingData.getCachedCurrentAccount()?.protocol
        return FeatureManager.open(.eas, openInMailClient: true) && protocl != nil && protocl == .exchange
    }
}
