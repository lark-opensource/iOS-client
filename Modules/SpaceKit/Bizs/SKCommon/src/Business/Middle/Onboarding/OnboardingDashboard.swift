// 
// Created by duanxiaochen.7 on 2019/11/4.
// Affiliated with SpaceKit.
// 
// Description: OnboardingDashboard aggregates all miscellanies regarding onboarding.

import SKUIKit
import UniverseDesignColor

public enum OnboardingType {
    case text
    case flow
    case card
}

public enum OnboardingBusiness {
    case doc
    case sheet
    case space
    case wiki
    case larkDocs
}

/// Naming rule: `mobile_{business}_{featureName}_{description}`
///
/// - `business`: `doc`, `sheet`, `wiki`, `space` etc.
/// - `featureName`: For example, `toolbarV2` for toolbar V2 related onboardings.
/// - `description`: A concise description of the new feature to be introduced.
/// Use **Camel Naming Convention** for `business`, `sequence` and `feature`.
///
/// There should be **NO** underscores inside `business`, `featureName` or `description`. That is to say, **an OnboardingID has only three underscores in it**.
public enum OnboardingID: String, CaseIterable {
    case docTranslateIntro             = "mobile_doc_translate_intro"
    case docGroupAnnouncementIntro     = "mobile_doc_groupAnnouncement_intro"
    case docGroupAnnouncementAutoSave  = "mobile_doc_groupAnnouncement_autoSave"
    case docToolbarV2AddNewBlock       = "mobile_doc_toolbarV2_addNewBlock"
    case docToolbarV2BlockTransform    = "mobile_doc_toolbarV2_blockTransform"
    case docToolbarV2Pencilkit         = "mobile_doc_toolbarV2_pencilKit"
    case bitableLarkFormSubmitNotify   = "bitable_lark_form_submit_notify_new"
    case docBlockMenuPenetrableIntro   = "mobile_doc_blockmenu_penetrableIntro"
    case docBlockMenuPenetrableComment = "mobile_doc_blockmenu_penetrableComment"
    case docIPadCatalogIntro           = "mobile_doc_iPadCatalog_intro"
    case docWidescreenModeIntro        = "mobile_doc_widescreenMode_introFirst"
    case docWidescreenModeIntroSecond  = "mobile_doc_widescreenMode_introSecond"
    case docSmartComposeIntro          = "mobile_doc_smartCompose_intro"
    case docInsertTable                = "mobile_doc_toolbarV2_insertTable"
    case sheetRedesignSearch           = "mobile_sheet_redesign_search"
    case sheetRedesignListMode         = "mobile_sheet_redesign_listMode"
    case sheetRedesignViewImage        = "mobile_sheet_redesign_viewImage"
    case sheetRedesignCardModeEdit     = "mobile_sheet_redesign_cardModeEdit"
    case sheetLandscapeIntro           = "mobile_sheet_landscape_intro"
    case sheetNewbieIntro              = "mobile_sheet_newbie_intro"
    case sheetNewbieSearch             = "mobile_sheet_newbie_search"
    case sheetNewbieEdit               = "mobile_sheet_newbie_edit"
    case sheetToolbarIntro             = "mobile_sheet_toolbar_intro"
    case sheetOperationPanelOperate    = "mobile_sheet_oppanel_operate"
    case sheetCardModeShare            = "mobile_sheet_cardMode_share"
    case sheetCardModeToolbar          = "mobile_sheet_cardMode_toolbarEntry"
    case sheetCardModeDrag             = "mobile_sheet_cardMode_dragEntry"

    case spaceNewbieCreate             = "mobile_space_newbie_create"
    case spaceNewbieTemplate           = "mobile_space_newbie_template"
    case spaceNewbieSwitch             = "mobile_space_newbie_switch"
    case spaceNewCreateTemplate        = "mobile_space_new_createTemplate"

    // space 首页改版 onboarding
    case spaceHomeNewbieNavigation     = "mobile_space_newbie_navigation"
    case spaceHomeNewbieCreateDocument = "mobile_space_newbie_createDocument"
    case spaceHomeNewbieCreateTemplate = "mobile_space_newbie_createTemplate"
    case spaceHomeCloudDrive           = "mobile_space_newbie_home_drive"

    // 运营banner
    case spaceBannerNewYear            = "mobile_space_banner_newYearTemplate"

    case wikiNewbiePageTree            = "mobile_wiki_newbie_pageTree"
    case wikiNewbieSwipeLeft           = "mobile_wiki_newbie_swipeLeft"
    case wikiNewSheetType              = "mobile_wiki_sheet_intro"

    //Todo的 onboarding
    case docTodoCenterIntro            = "mobile_doc_todocenter_intro"

    // MARK: LarkDocs
    case larkDocsNewbieShareCallout    = "mobile_doc_share_callout"
    case larkDocsPCWebRedBadgeNewFeature       = "mobile_space_mycenter_weburl"

    case spaceHomeNewShareSpace        = "mobile_space_share_with_me_navigation"

    //bitable字段增删改
    case bitableFieldEditIntro         = "mobile_bitable_fieldEdit_intro"
    case bitableExposeCatalogIntro     = "mobile_bitable_expose_catalog_intro"

    //bitable字段增删改页面级联选项设置引导
    case bitableFieldEditDynamicIntro  = "bitable_select_option_red_dot"
    
    //bitable 进度条字段展示新字段标签
    case bitableProgressFieldNew        = "bitable_progress_field_new"
    
    //bitable 扫码字段展示新字段标签
    case bitableBarcodeFieldNew         = "bitable_barcode_field_new"
    
    //bitable 货币字段展示新字段标签
    case bitableCurrencyFieldNew        = "bitable_currency_field_new"
    case bitableLarkFormNewTheme = "bitable_lark_form_new_theme_onboarding"
    case bitableLarkFormScheuledNotifyNew = "bitable_lark_form_scheduled_notify_new"
    
    // base 新版问卷登陆引导
    case bitableLarkFormLoginVerifyGuide = "bitable_lark_form_login_verify_guide"
    
    // bitable 群字段展示新字段标签
    case bitableGroupFieldNew           = "bitable_group_field_new"

    /// 移动端卡片视图引导：位置在 Webview 上挖孔
    case mobileBitableGridMobileView1    = "mobile_bitable_grid_mobile_view"
    /// 移动端卡片视图引导：位置在 bottomToolBar 的 Item 上
    case mobileBitableGridMobileView2    = "mobile_bitable_grid_mobile_view_setting"

    case bitablePermissionUpgradeSsc    = "bitable_permission_upgrade_ssc"
    
    // bitable 评分字段展示新字段标签
    case bitableRatingFieldNew           = "bitable_rating_field_new"
    
    // email 邮箱字段展示新字段标签
    case bitableEmailFieldNew           = "bitable_email_field_new"
    
    /// 扩展字段，人员字段 new 标签
    case bitableUserFieldExtendNew          = "bitable_user_extend_address_field_new"
    /// 扩展字段，扩展开关 new 标签
    case bitableFieldExtendSwitchNew          = "bitable_switch_extend_address_field_new"
    
    /// cardView支持封面
    case bitableCardViewCoverSupportEntryNew  = "base_card_view_cover_support_entry"
    case bitableCardViewCoverSupportSwitch    = "base_card_view_cover_support_switch"
    case bitableCardViewCoverNew              =  "base_card_view_cover_support"
    
    // docx投票引导
    case docxNoMoreDocxPollPublishTips    = "docx_no_more_docx_poll_publish_tips"
    case docxNoMoreDocxPollvoteChangeTips = "docx_no_more_docx_poll_vote_change_tips"
    case docxNoMoreDocxPollUndoTips       = "docx_no_more_docx_poll_undo_tips"
    case docxNoMoreDocxPollCloseTips      = "docx_no_more_docx_poll_close_tips"
    
    // AI 字段生成 OnBoarding
    case baseFieldAiExinfoMobile        = "base_field_ai_exinfo_mobile"
    
    // 上级自动授权弹框
    case permissionLeaderAutoAuth = "ccm_permission_leader_auto_auth"

    public var business: OnboardingBusiness {
        switch self {
        case let id where id.rawValue.starts(with: "mobile_doc"): return .doc
        case let id where id.rawValue.starts(with: "mobile_sheet"): return .sheet
        case let id where id.rawValue.starts(with: "mobile_space"): return .space
        case let id where id.rawValue.starts(with: "mobile_wiki"): return .wiki
        case let id where id.rawValue.starts(with: "mobile_larkDocs"): return .larkDocs
        default: fatalError("id 不规范")
        }
    }
    // 工作台
    case bitableFileAddToWorkbenchGuide = "bitable_file_add_to_workbench_guide"

    case baseBlockAddLinkedDocxUpdateMobile = "base_block_add_linked_docx_update_mobile"
    case baseBlockAddLinkedDocxToastNotNoticeMobile = "base_block_add_linked_docx_toast_not_notice_mobile"
    case baseHomepageEntranceSurveyNew = "bitable_base_homepage_entrance_survey_new"
    // Base 新框架 Onboarding
    case baseNewArchMobile = "base_new_arch_mobile"
}

public struct OnboardingStyle {
    /// The shape of the hollowed out oval in OnboardingFlowView.
    public enum Hollow {
        case circle // an incircle centered in the target rect 内切圆
        case capsule // corner radius is a half of target rect's height
        case roundedRect(CGFloat) // customized corner radius
    }

    /// The direction where the bubble's arrow is pointing.
    public enum ArrowDirection {
        case targetBottomEdge
        case targetTopEdge
        case targetTrailingEdge  // for iPad only
        case targetLeadingEdge // for iPad only
    }

    /// The behavior when the user touches down on transparent region of the onboarding view **outside the onboarding bubble**.
    ///
    /// For `.text` typed onboardings, you can switch between `.disappearWithoutPenetration` and `.disappearAndPenetrate` to
    /// obtain a modal/non-modal behavior when touching the screen.
    ///
    /// For `.flow` typed onboardings with mask on, you can switch between `.nothing`, `.disappearWithoutPenetration` and `.disappearAndPenetrate` to
    /// configure the transparent focus area touch action. If you opt out of the mask, the penetrable area extends to the window bounds.
    ///
    /// For `.card` typed onboardings, you can only use `.nothing` to force an interaction with the card.
    public enum TapBubbleOutsideBehavior {
        /// Tapping outside the onboarding bubble has no effect at all
        case nothing

        /// Tapping outside the onboarding bubble will only let the onboarding view disappear.
        /// No further touch event will be sent to views below.
        case disappearWithoutPenetration

        /// Tapping outside the onboarding bubble will both let the onboarding view disappear
        /// and let the touch event get through.
        case disappearAndPenetrate
    }

    /// In what way the onboarding view is going to disppear.
    public enum DisappearStyle {
        case immediatelyAfterUserInteraction
        case countdownAfterUserInteraction(DispatchTimeInterval)
        case countdownAfterAppearance(DispatchTimeInterval)
    }

    /// The behavior after the onboarding view has disappeared. This property is dynamically set based on user interaction.
    ///
    /// `.proceed`: continue executing onboarding tasks without calling any delegate method
    ///
    /// `.acknowledge`: call the delegate's `onboardingAcknowledge(_:)` method and continue executing further tasks
    ///
    /// `.skip`: call the delegate's `onboardingSkip(_:)` method and stop executing onboarding tasks
    public enum DisappearBehavior {
        case proceed
        case acknowledge
        case skip
    }

    static let maxCompactBubbleWidth: CGFloat = 280
    static let maxRegularBubbleWidth: CGFloat = 340
    static let bubbleGraphHeight: CGFloat = 120
    static let cardWidth: CGFloat = 300
    static let cardTextWidth: CGFloat = cardWidth - cardPadding * 2

    static let bubbleCornerRadius: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 4

    private static let sixteen: CGFloat = 16
    // 1 for one text element (only hint is present), 2 for two text elements (title and hint are both present)

    static let bubblePaddingBottom1: CGFloat = sixteen + hintLineHeightCompensation / 2
    static let bubblePaddingBottom2: CGFloat = 24 + hintLineHeightCompensation / 2
    static let bubblePaddingTopLeadingTrailing: CGFloat = 20
    static let cardGraphPaddingBottom1: CGFloat = sixteen + hintLineHeightCompensation / 2
    static let cardGraphPaddingBottom2: CGFloat = sixteen + titleLineHeightCompensation / 2
    static let cardPadding: CGFloat = 20
    static let buttonPaddingTop1: CGFloat = sixteen + hintLineHeightCompensation / 2
    static let buttonPaddingTop2: CGFloat = 24 + hintLineHeightCompensation / 2
    static let buttonPaddingTrailingBottom: CGFloat = 20
    static let flowInterbuttonSpacing: CGFloat = 8
    static let cardSkipPaddingTopTrailing: CGFloat = 12

    static let bubbleLayoutMargin: CGFloat = 8 // relative to window edge
    static let arrowTipOffsetFromTargetPoint: CGFloat = 8
    // nolint-next-line: magic number
    static let arrowLayoutMargin: CGFloat = bubbleLayoutMargin + bubbleCornerRadius * 1.2

    static let titleMarginTop: CGFloat = sixteen + titleLineHeightCompensation / 2
    static let titleHintSpacing: CGFloat = titleLineHeightCompensation / 2 + 8 + hintLineHeightCompensation / 2
    static let hintMarginTop: CGFloat = sixteen + hintLineHeightCompensation / 2

    // MARK: line height 补偿不使用 lineHeightMultiple 的原因是单个 line fragment 无法垂直居中，导致首行上面间距过大
    static let titleLineHeightScale = titleFont.lineHeight / titleFontSize
    // nolint-next-line: magic number
    static let titleLineHeightCompensation = (1.5 - titleLineHeightScale) * titleFontSize
    static let titleLineSpacing: CGFloat = titleLineHeightCompensation
    static let hintLineHeightScale = hintFont.lineHeight / hintFontSize
    // nolint-next-line: magic number
    static let hintLineHeightCompensation = (1.5 - hintLineHeightScale) * hintFontSize
    static let hintLineSpacing: CGFloat = hintLineHeightCompensation

    static let titleKern: CGFloat = 0.2
    static let hintKern: CGFloat = 0.2

    static let titleFontSize: CGFloat = 20
    static let hintFontSize: CGFloat = sixteen
    static let indexFontSize: CGFloat = sixteen
    static let skipTextFontSize: CGFloat = 14
    static let flowAckTextFontSize: CGFloat = 14
    static let cardAckTextFontSize: CGFloat = sixteen

    static let flowButtonHeight: CGFloat = 32

    static let cardAckButtonSize = CGSize(width: cardTextWidth, height: 40)
    static let cardSkipButtonSize = CGSize(width: 20, height: 20)
    static let cardImageBackgroundHeight: CGFloat = 187
    static let arrowSize = CGSize(width: 20, height: 10)

    static let titleFont = UIFont.systemFont(ofSize: titleFontSize, weight: .semibold)
    static let hintFont = UIFont.systemFont(ofSize: hintFontSize, weight: .medium)
    static let indexFont = UIFont.systemFont(ofSize: indexFontSize, weight: .medium)
    static let skipTextFont = UIFont.systemFont(ofSize: skipTextFontSize, weight: .medium)
    static let flowAckTextFont = UIFont.systemFont(ofSize: flowAckTextFontSize, weight: .medium)
    static let cardAckTextFont = UIFont.systemFont(ofSize: cardAckTextFontSize, weight: .medium)

    static let flowButtonTextInsets = UIEdgeInsets(top: 9, left: 15, bottom: 9, right: 15)
    static let buttonHitTestInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)

    static let titleColor = UDColor.primaryOnPrimaryFill
    static let hintColor = UDColor.primaryOnPrimaryFill
    static let indexColor = UDColor.primaryOnPrimaryFill
    static let skipTextColor = UDColor.primaryOnPrimaryFill
    static let ackButtonBackgroundColor = UDColor.primaryOnPrimaryFill
    static let startButtonBackgroundColor = UDColor.primaryOnPrimaryFill
    static let cardSkipButtonColor = UDColor.iconN2 & UDColor.iconN3
    static let cardSkipButtonHighlightColor = UDColor.iconN3
    static let cardImageBackgroundColor = UDColor.primaryOnPrimaryFill
    static let bubbleColor = UDColor.primaryFillHover & UDColor.primaryContentDefault
    static let maskColor = UDColor.bgMask


    static var titleAttributes: [NSAttributedString.Key: Any] {
        var attr: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .kern: titleKern,
            .foregroundColor: titleColor
        ]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .natural
        paraStyle.lineBreakMode = .byWordWrapping
        paraStyle.paragraphSpacingBefore = 0
        paraStyle.paragraphSpacing = 0
        paraStyle.lineSpacing = titleLineSpacing
        attr[.paragraphStyle] = paraStyle
        return attr
    }

    static var hintAttributes: [NSAttributedString.Key: Any] {
        var attr: [NSAttributedString.Key: Any] = [
            .font: hintFont,
            .kern: hintKern,
            .foregroundColor: hintColor
        ]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .natural
        paraStyle.lineBreakMode = .byWordWrapping
        paraStyle.paragraphSpacingBefore = 0
        paraStyle.paragraphSpacing = 0
        paraStyle.lineSpacing = hintLineSpacing
        attr[.paragraphStyle] = paraStyle
        return attr
    }
}
