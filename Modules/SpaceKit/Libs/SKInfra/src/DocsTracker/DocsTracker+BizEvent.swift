//
//  DocsTracker+BizEvent.swift
//  SKFoundation
//
//  Created by lijuyou on 2020/5/24.
//  swiftlint:disable type_body_length file_length
// swiftlint:disable all
import SKFoundation

extension DocsTracker {

    public enum EventType: String, DocsTrackerEventType {
        case groupFieldSelectView        = "ccm_bitable_group_field_select_view"
        case groupFieldSelectClick       = "ccm_bitable_group_field_select_click"
        case listFile                    = "dev_performance_list_file"
        case firstLogin                  = "dev_performance_first_login"
        case createFile                  = "dev_performance_create_doc_file"
        case backendAPI                  = "dev_performance_backend_api"
        case preLoadTemplate             = "dev_performance_doc_template_preload"
        case performanceDocForecast      = "dev_performance_doc_forecast"
        case fetchServerResponse         = "dev_performance_native_network_request" //客户端发起网络请求，开始到结束
        case fetchServerSubResponse      = "dev_performance_native_network_stage" //客户端发起网络请求，某次请求（可能会重试）
        case pictureUpload               = "dev_performance_native_picture_upload"
        case webviewTerminate            = "dev_performance_webview_terminate"
        case databaseInit                = "dev_performance_database_init"
        case homeTabVCInit               = "dev_performance_homeTab_init"
        case docsSDKInit                 = "dev_performance_larkLoad_init"
        case openBitable                 = "dev_performance_bitable_open_finish" // Bitable打开成功率
        case openBitableStage            = "dev_performance_bitable_open_stages" // Bitable打开流程的分段Stage统计报表
        case browserVCInit               = "dev_performance_browserVC_init"

        case renameClick                 = "click_file_rename_within"   // 重命名按钮被点击。
        case createNewObject             = "create_new_objs"  // 创建被点击
        case confirmMention              = "confirm_mention" // 全文评论或列表评论，输入@，点击弹出列表
        case openMention                 = "open_mention"    // 呼出 @ 列表

        case clickCommentInput           = "click_comment_input"
        case clickDocsMessagePage        = "click_docs_message_page"
        case viewDocsmessagePage         = "view_docs_message_page"
        case showLeftSlide               = "show_left_slide" // 侧滑cell这个动作的统计
        case clickFilterBoard            = "click_filter_board" // 点击过滤按钮
        case clickInnerpageMore          = "click_innerpage_more" // 点击了右上角的 ...
        case clickViewSwitch             = "click_view_switch" // 点击了视图切换按钮
        case clickGridMore               = "click_grid_more"
        case clickListItem               = "click_list_item"
        case clickFilePin                = "click_file_pin"
        case clickFilePinCancel          = "click_file_pin_cancel"
        case clickFileStar               = "click_file_star"
        case clickFileCancelStar         = "click_file_cancel_star"
        case clickFileSubscrible         = "click_file_subscrible"
        case clickFileCancelSubscrible   = "click_file_cancel_subscrible"
        case clickApplyEditPermission    = "click_authority_apply_btn"
        case clickSendApplyEditPermission = "click_authority_apply_action"
        case clickFileItemOperation      = "click_file_item_operation"
        case leftSlide                   = "left_slide"
        case clickLeftSlide              = "click_left_slide_item"
        case announcementClickHistory         = "view_announcement_history"
        case clickFilePinAction          = "click_file_pin_action" // 长按快速访问进行的操作统计
        case clientAttachmentAlert       = "client_attachment_alert"
        case clientAttachmentAlertGoon   = "client_attachment_alert_goon"
        case clientAttachmentAlertCancel = "client_attachment_alert_cancel"
        case sheetEditAction             = "click_sheet_edit_action" // sheetInputView 编辑事件
        case sheetOperation              = "sheet_opration"          // sheet 的相关操作 (拼写错误将错就错了)
        case sheetEditCellContent        = "edit_cell_content"       // sheet 内编辑单元格内容
        case sheetCloseKeyboard          = "sheet_close_keyboard" // 关闭工具栏键盘
        case sheetCloseFabPanel          = "sheet_close_fabPanel" // 关闭工具箱
        case clientAttachmentPreview = "click_attachment_preview"
        case sdkInit                     = "dev_performance_docsSDK_init"
        case rnLoadBundle                = "dev_performance_rnbundle_load"
        case rnOutOfContact              = "rn_out_of_contact"
        case rnLoadBundleFailed          = "rn_exception"
        case clickDocsTab                = "client_enter_docs"
        case driveFileDownloadClick          = "ccm_drive_file_download_click"
        case driveFileDownloadView           = "ccm_drive_file_download_view"
        // drive pdf大纲事件
        case drivePDFCatalogExpand = "ccm_space_docs_contents_view"

        // bitable & Drive
        // 打开bitable文档（需要在native埋）
        // 预览Drive文件
        case clientFileOpen = "client_file_open"
        /// 统计用户操作切换文件内容展示状态的数据情况
        case clientClickDisplay = "client_click_display"
        /// 预览 Drive 文件，横竖屏切换事件
        case clientFileLandscape = "client_file_landscape"
        /// 业务方所认为的 "DriveSDK" 预览文件事件：doc/IM/开发平台/邮件/日历中的附件预览
        /// https://bytedance.feishu.cn/docs/doccnHndkAq9RVQu0j1ntE9jkSh#
        case driveSDKFileOpen = "drive_sdk_file_open"
        /// Excel 打开埋点 https://bytedance.feishu.cn/wiki/wikcnIF6TrgfN4paU0wcGAIT0hh
        case excelContentPageView = "ccm_excel_content_page_view"
        /// https://bytedance.feishu.cn/sheets/shtcnqPPSGnCmMCzezvXbEXDJEg?sheet=5Y3XxU
        /// Drive 文件预览（不是通过链接方式进入 Drive 的预览场景）
        case drivePageView = "ccm_drive_page_view"
        /// Drive 文件预览的更多菜单（Alert 的方式）
        case driveFileMenuView = "ccm_drive_file_menu_view"
        /// Drive 文件打开后页面上的点击事件
        case driveFileOpenClick = "ccm_drive_page_click"
        /// Drive 文件更多菜单上的点击事件
        case driveFileMenuClick = "ccm_drive_file_menu_click"
        /// Drive 上传列表页面
        case driveFileUploadProgressView = "ccm_drive_file_upload_process_view"
        /// Drive 上传列表页面的点击事件
        case driveFileUploadProgressClick = "ccm_drive_file_upload_process_click"
        /// Drive 取消上传弹框页面事件
        case driveStopUploadConfirmView = "ccm_drive_stop_upload_confirm_view"
        /// Drive 取消上传弹框页面点击事件
        case driveStopUploadConfirmClick = "ccm_drive_stop_upload_confirm_click"
        /// Drive 文件大小超过下载限制
        case driveExceedDownloadLimit = "ccm_drive_exceed_download_limit_view"
        /// Drive 手机存储空间不足
        case driveExceedStorageLimit = "ccm_drive_exceed_storage_limit_view"
        
        ///恶意文件弹窗我点击事件
        case driveAppealAlertClick = "ccm_permission_download_forbidden_toast_click"
        ///恶意文件检测界面展示
        case driveAppealAlertView = "ccm_permission_download_forbidden_toast_view"

        case docsPageView = "ccm_docs_page_view"
        case docsPageClick = "ccm_docs_page_click"
        /// Drive 文件编辑按钮
        case driveEditView = "ccm_drive_edit_view"
        case driveEditClick = "ccm_drive_edit_click"
        case driveDownloadBeginClick = "ccm_drive_download_begin_click"
        case driveDownloadFinishView = "ccm_drive_download_finish_view"
        case driveUploadFinishView = "ccm_drive_upload_finish_view"
        case bitableRecordEdit = "bitable_record_edit"
        //
        case clickEnterExplorerModule = "click_explorer_enter_docs"

        // 搜索
        case clickSearch = "click_search"
        case clickSearchItem = "click_search_item"
        case searchOperation = "search_operation"
        case searchNoResult = "search_no_result"
        case searchSuggestion = "search_suggestion"
        case clickSuggestionItem = "click_suggestion_item"

        // wiki 搜索
        case wikiClickSearch = "wiki_click_search"
        case wikiClickSearchItem = "wiki_click_search_item"
        case wikiSearchOperation = "wiki_search_operation"
        case wikiSearchNoResult = "wiki_search_no_result"

        //menu
        case showMenu = "start_action_mode"
        case clickJSMenuItem = "js_menu_item_clicked"
        case clickIntentMenuItem = "intent_menu_item_click"
        case clickLinkMenuItem = "link_menu_item_clicked"


        // 文件预览
        case clientAttachmentDownloaddonwAlert = "client_attachment_downloaddonw_alert"
        case clickAttachmentOpen = "click_attachment_open"
        case clientAttachmentCache = "client_attachment_cache"
        case clientAttachmentDownloaddonwAlertCancel = "client_attachment_downloaddonw_alert_cancel"
        case clientAttachmentDownloaddonwAlertGoon = "client_attachment_downloaddonw_alert_goon"

        // 点赞
        case showPraisePage = "show_praise_page"
        case clientPraiseIcon = "client_praise_icon"
        case clientPraise = "client_praise"

        // 导出长图
        case clientGenerateLongImage = "client_generate_long_image"
        case clickLongImageDownload = "click_long_image_download"
        case clickLongImageShare = "click_long_image_share"
        case generateLongImageInfo = "client_long_image_info"
        case clientGenerateLongImageV2 = "client_generate_longImage_v2"

        // 历史
        case clickEnterHistoryWithin = "click_enter_history_within"

        // 创建文档
        case clickCreateItem = "click_create_item"
        // 商业化。提醒用户付费时
        case clientCommerce = "client_commerce"

        // Folder View Contoller 相关
        case clientFileListRefresh = "client_file_list_refresh"
        case removeCompleteConfirm = "remove_complete_confirm"
        case clickFeedMessageIgnore = "click_feed_message_ignore"

        // 回收站
        case clickTrashFileRestore = "click_trash_file_restore"
        case clickTrashFileRestoreView = "click_trash_file_restore_view"

        // Feed
        case clientFeedMessageRefresh = "client_feed_message_refresh"
        case clickFeedItem = "click_feed_item"
        case clientFeedMessageReceive = "client_feed_message_receive"
        case feedMuteClick = "ccm_notification_panel_click" // 通知开关

        //
        case clickCommentCopy = "click_comment_copy"

        /// 「会话中URL渲染」页面，发生动作事件
        case imUrlRenderClick = "im_url_render_click"

        // Collaborator
        case showSharePage = "show_share_page"
        case share = "share"
        case sharePermLimitPop = "share_perm_limit_pop"
        case sharePermLimitOperate = "share_perm_limit_operate"
        case showInviteItemPage = "show_invite_item_page"
        case showInviteSettingPage = "show_invite_setting_page"
        case showCollaborateSettingPage = "show_collaborate_setting_page"
        case showPermmisionPage = "show_permmision_page"
        case showPermSettingPage = "show_perm_setting_page"
        case clickAddCollaborate = "click_add_collaborate"
        case clickInviteSearchBar = "click_invite_search_bar"
        case clickSelectPermInviter = "click_select_perm_inviter"
        case clickCollaborateInviterNextStep = "click_collaborate_inviter_next_step"
        case clickAlterCollaboratePerm = "click_alter_collaborate_perm"
        case clickEraseCollaboratePerm = "click_erase_collaberate_perm"
        case clickSendInviteBtn = "click_send_invite_btn"
        case shareOperation = "share_operation"
        case clickSearchInviter = "click_search_inviter"
        case showLinkShareTips = "show_linkshare_tips"
        case clickLinkShareTipsOperation = "click_linkshare_tips_operation"
        case showSendlinkPage = "show_send_link"
        case clickToSendLinkOperation = "send_link_no_perm"
        case showAskOwnerpage = "show_ask_owner"
        case clickToAskOwnerOperation = "send_ask_owner"
        case clickSwitchCountryCode = "click_switch_phonecode"
        case clickShareSearchResult = "click_share_search_result"
        case clientAuthError = "client_auth_error"

        // 新共享文件夹权限
        case shareFolderManager = "client_sfolder_manage"
        case shareFolderMember = "client_sfolder_member"

        // 创建
        case clickCreateBtn = "click_create_btn"

        // MoreView
        case clickFileAddtoWithin = "click_file_addto_within"
        case clickEnterCustomerservice = "click_enter_customerservice"
        case clickFileDeleteWith = "click_file_delete_with"
        case clickMoreFuncWithin = "click_more_func_within"

        // 分享面板
        case clickFilePermSetWithin = "click_file_perm_set_within"
        case clickLinkshareSetting = "click_linkshare_setting"
        
        /// 仪表盘分享 分享仪表盘按钮click事件
        case bitableToolBarClick = "ccm_bitable_toolbar_click"
        /// bitable通用分享组件设置页展示
        case bitableExternalPermissionView = "ccm_bitable_external_permission_view"
        /// bitable通用分享组件设置页点击
        case bitableExternalPermissionClick = "ccm_bitable_external_permission_click"
        /// bitable 编辑访问链接
        case bitableExternalPermissionLimitSetView = "ccm_bitable_external_share_limit_set_view"
        case bitableExternalPermissionLimitSetClick = "ccm_bitable_external_share_limit_set_click"

        // 目录
        case showOutLineCatalog = "show_outline_catalog"
        case clickOutLineCatalogItem = "click_outline_catalog_item"
        case showNavCatalog = "show_nav_catalog"
        case clickNavCatalogItem = "click_nav_catalog_item"
        case iPadClickCatalogButton = "iPad_click_catalog_button"

        //
        case clickLarkDocsExploreSwitch = "click_lark_docs_explore_switch"
        // 图片查看器操作
        case clientImageOperation = "client_image_operation"
        // Reminder操作
        case clientReminderOperation = "docs_client_reminder_operation"
        case clickMoreFindWithin = "click_more_find_within"
        /// 供 Docs App 使用，不合理，后续收回
        case login = "login"
        case logout = "logout"
        case showLoginPage = "show_login_page"
        case search = "search"
        case clickFileItem = "click_file_item"
        case clickFeedBack = "click_feed_back"
        case clickMoreInfo = "click_more_info"
        case clickAboutDocs = "click_about_docs"
        case launchApp = "launch_app"
        case launchActive = "launch_active"

        //md5校验失败
        case md5CheckFailed = "dev_performance_check_res_completion"
        case md5BadCase = "dev_performance_md5_check_badcase"
        case md5FailedCause = "dev_performance_res_fail_cause" /*对应跟安卓相同的事件*/
        case clickReadingInfo = "client_docs_management"
        case openingWebviewTerminaterd = "dev_performance_opening_webview_terminate"

        // 时长模块
        case launchDuration = "launch_duration"

        // 文档管理
        case clientContentManagement = "client_content_management"

        // 添加到文件夹
        case clickAddtoOperation = "click_addto_operation"

        // 创建副本
        case clickMakeCopy = "click_copy_doc"

        // 进入Drive文件预览后的操作 || Docs选择高亮颜色
        case toggleAttribute = "toggle_attribute"

        // https://bytedance.feishu.cn/docs/doccnHndkAq9RVQu0j1ntE9jkSh#
        // 上传状态栏的操作， 云空间+号上传图片和文件
        case clientFileUpload = "client_file_upload"
        // 文档、表格、局部评论、全局评论 上传文件
        case driveSDKFileUpload = "drive_sdk_file_upload"
        // doc/sheet/mindnote预览页导出
        // 云空间列表更多-导出为、设置为离线可使用
        case clientFileDownload = "client_file_download"
        // - docs/sheet/mindnote/评论 - 图片附件预览 - 下载(点开大图保存到相册)
        case driveSDKFileDownload = "sdk_drive_file_download"

        /// 离线情况下，是否置灰
        case listOfflineStatus = "dev_performance_show_list_item"

        /// 是否展示了loading
        case loadingHasShown = "dev_performance_doc_open_loading_shown"

        /// 打开drive
        case openDrive = "dev_performance_drive_open_finish"
        /// Drive 可降级的预览方式的事件
        case openDriveDowngrade = "dev_performance_drive_open_downgrade"
        /// Drive 本地解压压缩文件事件
        case driveArchiveExtract = "ccm_drive_archive_extract_dev"
        /// Drive 缓存元数据存储数据库操作事件
        case driveMetaDBOperate = "ccm_mobile_drive_metaDB_operate_dev"
        /// 内置精简包解压性能
        case bundleSlimPkgExtract = "ccm_extract_eesz_asset_result_dev" // Homeric.CCM_EXTRACT_EESZ_ASSET_RESULT_DEV

        /// 开始转换在线文档
        case convertDrive = "dev_performance_drive_import_finish"

        /// 评论总埋点
        case clientComment = "client_comment"

        /// 用户确认上传图片
        case imgPickerConfirm = "dev_image_picker_confirm"

        /// 前端开始叫 native 上传
        case imgPickerStartUploadImage = "dev_image_picker_start_upload"

        case clientHorizontalScreen = "client_horizontal_screen"
        ///预加载clietvar
        case preloadClientVar = "preload_clientvar"

        /// 文档内置顶操作事情
        case pinToQuickswitcher = "pin_to_quickswitcher"
        case unpinToQuickswitcher = "unpin_to_quickswitcher"

        /// 主动点击通知铃铛时显示
        case clickNotificationIcon = "click_notification_icon"
        /// 主动点击底部Tab空间按钮
        case clickSpaceIcon = "click_space_icon"
        /// 主动点击tab首页按钮
        case clickHomeIcon = "click_home_icon"

        /// Feed 展示
        case feedPanelOps = "feed_panel_ops"
        case feedV2Open   = "dev_performance_feed_open_finish"
        case feedV2Stage  = "dev_performance_feed_open_stage"
        case feedV2Error  = "dev_performance_feed_open_error"

        /// Bitable 旧埋点
        case bitableAttachmentOperation = "bitable_attachment_operation"
        case bitableUploadType = "bitable_upload_type"
        case bitableCardSwitch = "bitable_card_switch"
        case bitableShowMoreColumn = "click_bitable_card_show_more_column"
        case bitableClickOpenOriginLink = "click_openorigin_link"
        case bitablePerformanceOpenCard = "bitable_performance_open_card"
        case bitablePerformanceFail = "bitable_performance_fail_details"

        /// Bitable 新埋点 View
        case bitableCardView = "ccm_bitable_card_view"
        case bitableCardLinkPanelView = "ccm_bitable_relation_field_modify_view"
        case bitableCardEditDenyView = "ccm_bitable_card_edit_deny_view"
        /// Bitable 新埋点 Click
        case bitableAttachmentOperateClick = "ccm_bitable_attachment_operate_click"
        case bitableCardClick = "ccm_bitable_card_click" //卡片场景
        case bitableMailCellClick = "ccm_bitable_email_cell_click" // Email mailto 行为埋点
        case bitableFormClick = "ccm_bitable_form_click" //表单场景
        case bitableShareClick = "ccm_bitable_share_click"
        case bitableCardAttachmentOperateClick = "ccm_bitable_card_attachment_operate_click"
        case bitableCardLinkFieldClick = "ccm_bitable_relation_field_modify_click"
        case bitableCardAttachmentChooseView = "ccm_bitable_card_attachment_choose_view"
        case bitableCardAttachmentChooseViewClick = "ccm_bitable_card_attachment_choose_click"
        case bitableCardLimitedTipsView = "ccm_bitable_card_limited_tips_view"
        case bitableCardLimitedTipsClick = "ccm_bitable_card_limited_tips_click"
        case bitableCardAttachmentCoverSettingViewShow = "ccm_bitable_card_attachment_cover_setting_view"
        case bitableCardAttachmentCoverSettingViewHide = "ccm_bitable_card_attachment_cover_setting_click"
        case bitableCardAutoSubscribeClick = "ccm_bitable_record_auto_subscribe_click"
        case bitableRecordUnsubscribeView = "ccm_bitable_record_unsubscribe_view"
        case bitableRecordUnsubscribeViewClick  = "ccm_bitable_record_unsubscribe_click"
        
        // Bitable 记录快捷新建埋点
        case bitableRecordCreateView = "ccm_bitable_record_create_view"
        case bitableRecordCreateClick = "ccm_bitable_record_create_click"
        case bitableAddRecordQuitView = "ccm_bitable_add_record_quit_view"
        case bitableAddRecordQuitClick = "ccm_bitable_add_record_quit_click"
        case bitableNoPermissionAddRecordView = "ccm_bitable_no_permission_add_record_view"
        case bitableNoPermissionAddRecordClick = "ccm_bitable_no_permission_add_record_click"
        case bitableShareRecordMoreView = "ccm_bitable_share_record_more_view"
        case bitableShareRecordMoreClick = "ccm_bitable_share_record_more_click"
        case bitableAddRecordTimeoutView = "ccm_bitable_add_record_timeout_view"
        case bitableAddRecordTimeoutClick = "ccm_bitable_add_record_timeout_click"
        case bitableAddRecordQrcodeView = "ccm_bitable_add_record_qrcode_view"
        case bitableAddRecordQrcodeClick = "ccm_bitable_add_record_qrcode_click"

        ///Bitable选项字段埋点
        case bitableOptionFieldPanelOpen = "ccm_bitable_option_field_panel_view"
        case bitableOptionFieldPanelClick = "ccm_bitable_option_field_panel_click"
        case bitableOptionFieldEditPanelOpen = "ccm_bitable_option_field_edit_view"
        case bitableOptionFieldEditPanelClick = "ccm_bitable_option_field_edit_click"
        case bitableOptionFieldMoreViewOpen = "ccm_bitable_option_field_more_view"
        case bitableOptionFieldMoreViewClick = "ccm_bitable_option_field_more_click"
        case bitableOptionFieldDeleteViewOpen = "ccm_bitable_option_field_delete_view"
        case bitableOptionFieldDeleteViewClick = "ccm_bitable_option_field_delete_click"
    
        ///Bitable字段增删改埋点
        case bitableFieldModifyView = "ccm_bitable_field_modify_view"
        case bitableFieldModifyViewClick = "ccm_bitable_field_modify_click"
        case bitableFieldModifyCancelConfirmView = "ccm_bitable_field_modify_cancel_confirm_view"
        case bitableFieldModifyCancelConfirmClick = "ccm_bitable_field_modify_cancel_confirm_click"
        case bitableFieldTypeModifyView = "ccm_bitable_field_type_modify_view"
        case bitableFieldTypeModifyViewClick = "ccm_bitable_field_type_modify_click"
        case bitableFieldOperateView = "ccm_bitable_field_operate_view"
        case bitableFieldOperateViewClick = "ccm_bitable_field_operate_click"
        case bitableOptionFieldModifyViewClick = "ccm_bitable_option_field_modify_click"
        case bitableOptionFieldOpenColorSelectView = "ccm_bitable_color_board_view"
        case bitableAttachmentFieldModifyViewClick = "ccm_bitable_attachment_field_modify_click"
        case bitableTimeFieldFormatModifyView = "ccm_bitable_time_field_format_modify_view"
        case bitableTimeFieldFormatModifyViewClick = "ccm_bitable_time_field_format_modify_click"
        case bitableTimeFieldModifyClick = "ccm_bitable_time_field_modify_click"
        case bitableMemberFieldModifyViewClick = "ccm_bitable_member_field_format_modify_click"
        case bitableGroupFieldModifyViewClick = "ccm_bitable_group_field_modify_click"
        case bitableGroupFieldEntranceClick = "ccm_bitable_group_field_entrance_click"
        case bitableNumberFieldModifyView = "ccm_bitable_number_field_format_modify_view"
        case bitableNumberFieldModifyViewClick = "ccm_bitable_number_field_format_modify_click"
        case bitableProgressCellEditClick = "ccm_bitable_progress_cell_edit_click"
        case bitableProgressFieldModifyClick = "ccm_bitable_progress_field_modify_click"
        case bitableRatingCellEditClick = "ccm_bitable_rating_cell_edit_click"
        case bitableRatingFieldModifyClick = "ccm_bitable_rating_field_modify_click"
        case bitableRelationFieldModifyViewClick = "ccm_bitable_duplex_relation_modify_click"
        case bitableFieldModifyDynamicOptionsWarningView = "ccm_bitable_modify_field_quote_warning_view"
        case bitableFieldModifyDynamicOptionsWarningViewClick = "ccm_bitable_modify_field_quote_warning_click"
        case bitableOptionFieldModifyDuration = "ccm_bitable_option_field_modify_duration_view"
        case bitableRelationSwitchNoAddWarningToastClick = "ccm_bitable_relation_switch_no_add_warning_toast_click"
        case bitableRelationSwitchNoAddWarningToastView = "ccm_bitable_relation_switch_no_add_warning_toast_view"
        case bitableDatabaseSwitchToastView = "ccm_bitable_database_switch_toast_view"
        case bitableDatabaseSwitchToastClick = "ccm_bitable_database_switch_toast_click"
        case bitableRelationSwitchCanAddWarningToastView = "ccm_bitable_relation_switch_can_add_warning_toast_view"
        case bitableRelationSwitchCanAddWarningToastClick = "ccm_bitable_relation_switch_can_add_warning_toast_click"
        case bitableFieldModifyDurationView = "ccm_bitable_field_modify_duration_view"  //Bitable字段配置面板曝光时长埋点  https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=D2qM2O
        case bitableFieldTypeModifyDurationView = "ccm_bitable_field_type_modify_duration_view" //Bitable字段类型选择面板曝光时长埋点 https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=D2qM2O
        case bitableMobileSidebarGuideView = "ccm_bitable_mobile_sidebar_guide_view"
        case bitableMobileSidebarGuideClick = "ccm_bitable_mobile_sidebar_guide_click"
        case bitableCellEdit = "ccm_bitable_cell_edit"

        ///Bitable字段分组统计埋点
        case bitableStatisticsMethodModifyView = "ccm_bitable_statistics_method_modify_view"
        case bitableGroupStatisticsView = "ccm_bitable_group_statistics_view"
        case bitableGlobalStatisticsView = "ccm_bitable_statistics_view"
        
        case bitableReadMenuClick = "ccm_bitable_mobile_read_menu_click"
        case bitableEditMenuClick = "ccm_bitable_mobile_edit_menu_click"

        ///Bitable自动编号字段埋点
        case bitableAutoNumberFieldModifyView = "ccm_bitable_auto_number_field_modify_view"
        case bitableAutoNumberFieldViewClick = "ccm_bitable_auto_number_field_modify_click"
        case bitableAutoNumberCheckView = "ccm_bitable_auto_number_check_view"
        case bitableAutoNumberCheckClick = "ccm_bitable_auto_number_check_click"
        
        ///Bitable地理字段埋点
        case bitableGeoFieldModifyClick = "ccm_bitable_geography_field_modify_click"
        case bitableGeoCardClick = "ccm_bitable_geography_card_click"
        
        //bitable表单打开互联网可填写事件上报
        case bitableFormInternetPopupView = "ccm_bitable_form_internet_person_attachment_popup_view"
        
        /// bitable防截图loadview初始size上报
        case bitableCapturePreventViewInitSize = "ccm_bitable_captureprevent_viewinitsize_dev"
        
        case bitableKeyboardClick = "ccm_bitable_keyboard_click"

        /// Bitable支持电话号码字段埋点
        case bitableTelIconView = "ccm_bitable_tel_card_icon_view"
        case bitableTelIconClick = "ccm_bitable_tel_card_icon_click"
        case bitaleTelContactView = "ccm_bitable_tel_contact_icon_view"
        case bitaleTelContactClick = "ccm_bitable_tel_contact_icon_click"
        case bitableTelContactGuideView = "ccm_bitable_tel_contact_guide_view"
        case bitableTelContactGuideClick = "ccm_bitable_tel_contact_guide_click"
        /// 扫码字段
        case bitableScanFieldModifyClick = "ccm_bitable_scan_field_modify_click"
        case bitableScanCameraView = "ccm_bitable_scan_camera_view"
        case bitableScanCameraClick = "ccm_bitable_scan_camera_click"
        case bitableScanCameraOperate = "bitable_scan_camera_operate"
        
        /// 时区相关埋点
        case bitableTimeZoneSettingView = "ccm_bitable_time_zone_setting_view"
        case bitableTimeZoneSettingClick = "ccm_bitable_time_zone_setting_click"
        /// 筛选组件内点击埋点
        case bitableFilterSelectClick = "ccm_bitable_filter_select_click"
        /// 筛选排序底部工具栏
        case bitableFilterSortBoardView  = "ccm_bitable_mobile_bottom_toolbar_view"
        /// click：filter，sort target： ccm_bitable_filter_set_view  or ccm_bitable_sort_set_view
        case bitableFilterSortBoardClick  = "ccm_bitable_mobile_bottom_toolbar_click"
        case bitableFilterSetView =  "ccm_bitable_filter_set_view"
        case bitableFilterSetClick =  "ccm_bitable_filter_set_click"
        case bitableFilterSetHalfwayClick =  "ccm_bitable_filter_set_halfway_click"
        case bitableSortSetView =  "ccm_bitable_sort_set_view"
        case bitableSortSetClick =  "ccm_bitable_sort_set_click"
        case bitableSortSetHalfwayClick =  "ccm_bitable_sort_set_halfway_click"
        case bitableToolbarLimitedTips = "ccm_bitable_toolbar_limited_tips" // bottomBar 显示！
        case bitableCalculationOperateLimitedView = "ccm_bitable_calculation_operate_limited_view"
        case bitableMobileGridFormatView = "ccm_bitable_mobile_grid_format_view"
        case bitableMobileGridFormatClick = "ccm_bitable_mobile_grid_format_click"
        case bitableMobileGridEditOnboardingView = "ccm_bitable_mobile_grid_edit_onboarding_view"
        case bitableMobileGridEditOnboardingClick = "ccm_bitable_mobile_grid_edit_onboarding_click"
        case bitableMobileCardCoverView = "ccm_bitable_mobile_card_cover_num_view"
        
        /// 货币字段
        case bitableCurrencyFieldModifyClick = "ccm_bitable_currency_field_modify_click"
        
        /// 工作台
        case bitableAddToWorkplaceToastView = "ccm_bitable_add_to_workplace_toast_view"
        case bitableAddToWorkplaceOnboardingView = "ccm_bitable_add_to_workplace_onboarding_view"

        
        ///bitable Home页面
        case bitableHomePage = "ccm_bitable_workspace_landing_page_view"
        case bitableHomePageClick = "ccm_bitable_workspace_landing_page_click"
        case bitableHomeMoreMeunView = "ccm_bitable_workspace_landing_more_menu_view"
        
        case bitableHomeMoreMenuViewClick = "ccm_base_homepage_right_click_menu_click"
        
        case baseHomepageLandingView = "ccm_base_homepage_landing_view"
        case baseHomepageLandingClick = "ccm_base_homepage_landing_click"
        case baseHomepageFilelistView = "ccm_base_homepage_filelist_view"
        case baseHomepageFilelistClick = "ccm_base_homepage_filelist_click"
        case baseHomepageBannerView = "ccm_base_homepage_banner_view"
        case baseHomepageBannerClick = "ccm_base_homepage_banner_click"
        case baseHomepageActivityView = "ccm_base_homepage_activity_view"
        case baseHomepageActivityClick = "ccm_base_homepage_activity_click"
        case baseHomepageFeedContentView = "ccm_base_homepage_feed_content_view"
        case baseHomepageFeedContentEffectView = "ccm_base_homepage_feed_content_effect_view"
        case baseHomepageFeedContentClick = "ccm_base_homepage_feed_content_click"
        case baseHomepageFeedCoverView = "ccm_base_homepage_feed_cover_view"
        case baseHomepageFeedStayDuration = "ccm_base_homepage_feed_stay_duration_status"
        case baseHomepageNewAppear = "ccm_bitable_homepage_landing_view"
        
        /// bitable home dashboard chart
        case baseHomepageDashboardView = "ccm_bitable_homepage_dashboard_view"
        
        case baseHomepageChartClick = "ccm_bitable_component_click"
        case baseHomepageChartToggleFullScreen = "ccm_bitable_homepage_dashboard_component_full_screen_view"
        case baseHomepageChartFullScreenCilck = "ccm_bitable_homepage_dashboard_component_full_screen_click"
        case baseHomepageDashboardSettingClick = "ccm_bitable_homepage_dashboard_setting_click"
        case baseHomepageDashboardSettingView =  "ccm_bitable_homepage_dashboard_component_setting_view"
        case baseHomepageChartSettingClick = "ccm_bitable_homepage_dashboard_component_setting_click"
        case baseHomepageChartAddView = "ccm_bitable_homepage_dashboard_component_add_view"
        case baseHomepageChartAddClick = "ccm_bitable_homepage_dashboard_component_add_click"
        case baseDashboardDurationView = "ccm_bitable_dashboard_duration_view"
        /// bitable信息框架改版埋点
        case bitableCalloutSidebarClick = "ccm_bitable_callout_sidebar_click"
        
        /// bitable Native 卡片视图埋点
        case baseContentPageView = "ccm_bitable_content_page_view"
        
        /// bitable
        case bitableRowExpandRecordLimitView = "ccm_bitable_row_expand_mobile_record_limit_view"

        /// Feed 埋点
        case isHasNotification = "is_has_notification"
        // MARK: - 3.5
        case continuousOpen    = "dev_performance_continuous_open" //连续打开应用

        ///slide字体下载用户操作
        case clientSlideFont = "client_slide_font"
        //slide字体下载成功率
        case slideFontDownload = "dev_client_slide_font_download"
        //统计侧边导航条拖动跳转
        case slideClickNavCatalog = "click_nav_catalog"
        //字体下载阶段埋点
        case fontDownloadStage = "dev_performance_font_download_stage"
        // 导出 PDF & png
        case clickExport = "click_export"

        // 传图接力
        case imageHandoff = "client_upload_image_from_mobile"

        // dirve 打开文档过程上报时的事件名
        case driveStageEvent = "dev_performance_drive_open_stages"
        case driveErrorEvent = "dev_performance_drive_error"
        case dataCollectionEvent = "dev_performance_data_collection"
        case driveEnterPresentation = "drive_enter_presentation"
        
        case clickPinSort = "click_pin_sort"
        case showListSlide = "show_list_slide"
        case clickPinSortAction = "click_pin_sort_action"
        case fileSendMessage = "file_send_message"
        case showOnboardingGuideMobile = "show_onboarding_guide_mobile"
        case showOnboardingCreateMobile = "show_onboarding_create_mobile"
        case docsOpenFinish = "dev_performance_doc_open_finish"
        case openStageEvent = "dev_performance_stage"
        case dbError = "dev_db_error"
        // 文档编辑中文输入空格事件耗时统计
        case chineseInputNativeCost = "ccm_doc_ipad_chinese_input_native_cost_dev"
        // 第三方预览打开业务统计
        case thirdpatyOpenMentioned = "click_open_mentioned_obj"


        // MARK: - Wiki
        case wikiPagesOperation = "client_wiki_pages_operation"
        case wikiHomeWorkspaceOperation = "client_wiki_home_workspace_operation"
        case wikiEnterEvent = "client_enter_wiki"
        case wikiTriggerSlideEvent = "ccm_wiki_trigger_slide_event_dev"

        // MARK: - Wiki性能埋点
        case wikiOpenTreePerformance = "wiki_performance_open_tree_finish"
        case wikiOpenTreeStagePerformance = "wiki_performance_open_tree_stages"
        case wikiExpandNodePerformance = "wiki_performance_expand_child_tree_finish"
        case wikiExpandNodeStagePerformance = "wiki_performance_expand_child_tree_stages"
        case wikiOperateTreePerformance = "wiki_performance_tree_operation_finish"

        // MARK: - Wiki View事件埋点
        case wikiHomeView = "ccm_wiki_home_view"
        case wikiAllSpaceView = "ccm_wiki_all_space_view"
        case wikiCreateNewView = "ccm_wiki_create_new_view"
        case wikiCreateNewCatalogView = "ccm_wiki_create_new_catalog_view"
        case wikiFileLocationSelectView = "ccm_wiki_file_location_select_view"
        case wikiTreeView = "ccm_wiki_tree_view"
        case wikiTreeAddView = "ccm_wiki_tree_add_view"
        case wikiTreeMoreView = "ccm_wiki_tree_more_view"
        case wikiDeleteConfirmView = "ccm_wiki_delete_confirm_view"
        case wikiTrashView = "ccm_wiki_trash_view"
        case wikiTrashRestoreView = "ccm_wiki_trash_restore_view"
        case wikiTrashDeleteView = "ccm_wiki_trash_delete_view"
        case wikiPermissionChangeView = "ccm_wiki_permission_change_view"
        case wikiCatalogView = "ccm_wiki_catalog_view"
        case wikiCatalogCreateNewView = "wiki_catalog_create_new_view"
        case wikiCatalogDropdownMenuView = "ccm_wiki_catalog_dropdown_menu_view"
        case wikiApplyMoveOutView = "ccm_wiki_apply_move_out_view"
        case wikiDocsMoveResultToastView = "ccm_wiki_docs_move_result_toast_view"
        case wikiTreeGuideView = "ccm_wiki_tree_guide_view"
        
        // MARK: - Wiki Click事件埋点
        case wikiHomeClick = "ccm_wiki_home_click"
        case wikiAllSpaceClick = "ccm_wiki_all_space_click"
        case wikiCreateNewClick = "ccm_wiki_create_new_click"
        case wikiCreateNewCatalogClick = "ccm_wiki_create_new_catalog_click"
        case wikiTreeClick = "ccm_wiki_tree_click"
        case wikiTreeAddClick = "ccm_wiki_tree_add_click"
        case wikiTreeMoreClick = "ccm_wiki_tree_more_click"
        case wikiTreeDeleteConfirmClick = "ccm_wiki_delete_confirm_click"
        case wikiTrashClick = "ccm_wiki_trash_click"
        case wikiTrashRestoreClick = "ccm_wiki_trash_restore_click"
        case wikiTrashDeleteClick = "ccm_wiki_trash_delete_click"
        case wikiFileLocationSelectClick = "ccm_wiki_file_location_select_click"
        case wikiCatalogClick = "wiki_catalog_click"
        case wikiCatalogCreateNewClick = "wiki_catalog_create_new_click"
        case wikiCatalogDropdownMenuClick = "ccm_wiki_catalog_dropdown_menu_click"
        case wikiPermissionChangeClick = "ccm_wiki_permission_change_click"
        case wikiApplyMoveOutClick = "ccm_wiki_apply_move_out_click"
        case wikiDocsMoveResultToastClick = "ccm_wiki_docs_move_result_toast_click"
        case wikiAIEnterChatMainView = "im_chat_main_view"

        case spaceUploadProgressView = "ccm_space_upload_progress_view"
        case spaceUploadProgressClick = "ccm_space_upload_progress_click"

        // RN
        case rnFatal = "dev_performance_rn_fatal"
        case rnException = "dev_performance_rn_exception"
        case rnErrorLog = "dev_performance_rn_rnErrorLog"

        case rnBundleFileHandleFail = "dev_performance_rn_bundle_file_handle_fail"

        /// 文档Icon
        case clientIconChange = "client_icon_change"

        //点击链接
        case linkClicked = "link_clicked"

        // 封面
        case clientCoverOperation = "client_cover_operation"

        // 链接共享
        case externalPublicShareOK = "external_public_share_ok"
        case externalPublicShareCancel = "external_public_share_cancel"

        // 密码分享
        case clientLockSetting = "client_lock_setting"

        // 缩略图
        case thumbnailInfo = "thumb_info"
        case thumbnailRequestResult = "thumb_request_result"

        // MARK: - 飞书文档 Onboarding
        case larkDocsOnboardingOptionResearch = "onboarding_option_research"
        case larkDocsOnboardingTemplateBanner = "onboarding_template_banner"
        case larkDocsOnboardingShare = "onboarding_share"

        case templateMoreButton = "click_template_more_button"

        // 大搜性能埋点 (不用加前缀)
        case searchTime = "search_time"
        case viewSearchResult = "view_search_result"
        case viewSearchResultRollFps = "view_search_result_roll_fps"

        //space列表展示
        case spaceOpenFinish = "dev_performance_space_open_finish"
        //space列表展示各阶段耗时
        case spaceOpenStage = "dev_performance_space_open_stages"

        // 新版模板中心
        case clickTemplatePrimaryTab = "click_template_primary_tab"
        case clickTemplateSecondaryFilter = "click_template_secondary_filter"
        // 下载完整包的耗时
        case fullPackageDownloadDuration = "dev_fullPackage_download_duration"
        // 开始下载完整包x秒后检查完整包是否下载成功
        case fullPackageDownloadResultDev = "docs_fullPackage_download_result_dev"
        // 前端资源包管理异常case上报
        case fePkgManageBadCase = "fe_pkg_manage_bad_case_dev"

        // 离线同步
        case devPerformanceSyncStatus = "dev_performance_sync_status"
        case devPerformanceSyncBeginsync = "dev_performance_sync_beginsync"

        case loadFeRemoteResource = "load_fe_remote_resource"

        // 文档内图片上传
        case devPerformancePicUpload = "dev_performance_native_pic_upload_result"
        // 文档内文件上传
        case devPerformanceFileUpload = "dev_performance_native_file_upload_result"
        // 文档内图片下载
        case devPerformancePicDownload = "dev_performance_native_pic_download_result"
        // 文档图片上传前压缩
        case devPerformancePicCompress = "docs_dev_performance_native_pic_compress"
    
        // TodoCenter
        case todoCenter = "client_todo_center"

        // 金刚位展示事件
        case spaceEntranceShow = "icon_show"
        // 金刚位点击事件
        case spaceEntranceClick = "icon_click"
        // space首页banner展示
        case spaceBannerShow = "banner_show"
        // space首页banner点击
        case spaceBannerClick = "banner_click"

        // space首页子tab点击
        case spaceSubTabClick = "tab_click"

        // 单品首页点击创建按钮
        case clickNewIcon = "click_new_icon"
        
        // 模板中心banner曝光
        case showTemplateinnerbanner = "show_templateinnerbanner"
        
        // 模板中心用户点击banner
        case clickTemplateinnerbanner = "click_templateinnerbanner"
        // 模板中心搜索事件
        case templateSearch = "template_search"
        
        // 模板中心单个模板曝光事件
        case singletemplateExposure = "singletemplate_exposure"
        // 模板中心的曝光事件
        case enterTemplateCenter = "enter_template_center"
        // 场景化模版预览点击事件
        case clickTemplateButton = "click_template_button"
        // 点击预览场景化模版
        case clickTemplatePreview = "click_template_preview"
        // 保存场景化模版成功时上报
        case createFromTemplateCenter = "create_from_template_center"
        
        /// 模板操作事件
        case managementTemplateByUser = "management_template_by_user"
        
        /// 系统模板中心页面的点击事件
        case ccmTemplateSystemcenterViewClick = "ccm_template_systemcenter_view_click"
        
        /// 自定义模板中心页面的点击事件
        case ccmTemplateUsercenterViewClick = "ccm_template_usercenter_view_click"
        
        /// 企业模板中心页面的点击事件
        case ccmTemplateEnterprisecenterViewClick = "ccm_template_enterprisecenter_view_click"
        
        /// 模板banner页面的点击事件
        case ccmTemplateBannerViewClick = "ccm_template_banner_view_click"
        
        /// 模板搜索结果页的点击事件
        case ccmTemplateSearchResultViewClick = "ccm_template_search_result_view_click"
        
        /// 普通模板预览页面的点击事件
        case ccmTemplatePreviewViewClick = "ccm_template_preview_view_click"
        
        /// 会议文档底部模板操作埋点
        case ccmVCTemplateBottomClick = "ccm_vc_template_bottom_click"
        
        /// 套组模板预览页的点击事件
        case ccmSetTemplatePreviewClick = "ccm_set_template_preview_click"
        
        /// 创建面板推荐模版数据请求
        case devRecommendTemplateDataRequest = "recommend_template_data_request_dev"

        ///block快捷菜单关闭事件
        case blockMenuPullingDown = "ccm_block_close"

        ///Pencilkit画板埋点
        case clientPencilkitTips = "client_pencilkit_tips"
        case clientPencilkitDataUpload = "client_pencilkit_data_upload"
        case clientPencilkitDataDownload = "client_pencilkit_data_download"
        
        /// ccm超限弹框曝光
        case commonPricePopup = "common_pricing_popup_view"
        case commonPricePopClick = "common_pricing_popup_click"

        /// 用户容量弹出
        case storageExcessView = "ccm_space_storage_excess_view"
        case storageExcessClick = "ccm_space_storage_excess_click"
        /// 单文件上传容量限制限制
        case driveUploadLimitView = "ccm_drive_upload_limit_view"
        case driveUploadLimitViewClick = "ccm_drive_upload_limit_click"
        /// 导航栏
        case navigationBarView = "ccm_space_docs_topbar_view"
        case navigationBarClick = "ccm_space_docs_topbar_click"

        ///space主页
        case spaceHomePageView = "ccm_space_home_page_view"
        ///在space首页的点击动作
        case spaceHomePageClick = "ccm_space_home_page_click"
        ///个人空间主页
        case spacePersonalPageView = "ccm_space_personal_page_view"
        ///在个人空间主页的点击动作
        case spacePersonalPageClick = "ccm_space_personal_page_click"
        ///共享空间主页
        case spaceSharedPageView = "ccm_space_shared_page_view"
        ///在共享空间主页的点击动作
        case spaceSharedPageClick = "ccm_space_shared_page_click"
        ///收藏主页
        case spaceFavoritesPageView = "ccm_space_favorites_page_view"
        ///在收藏主页的点击动作
        case spaceFavoritesPageClick = "ccm_space_favorites_page_click"
        ///离线文档主页
        case spaceOfflinePageView = "ccm_space_offline_page_view"
        ///在离线文档主页的点击动作
        case spaceOfflinePageClick = "ccm_space_offline_page_click"
        ///搜索初始页
        case spaceSearchInitializedView = "ccm_space_search_initialized_view"
        ///搜索结果页
        case spaceSearchResultView = "ccm_space_search_result_view"
        ///筛选框view
        case spaceHeaderFilterView = "ccm_space_header_filter_view"
        ///在筛选框上的点击动作
        case spaceHeaderFilterClick = "ccm_space_header_filter_click"
        ///文档list左滑点击“…”后出现的view
        case spaceRightClickMenuView = "ccm_space_right_click_menu_view"
        ///文档list左滑点击“…”后出现的view上的点击
        case spaceRightClickMenuClick = "ccm_space_right_click_menu_click"
        ///文档详情页里右上角“…”点击后的view
        case spaceDocsMoreMenuView = "ccm_space_docs_more_menu_view"
        ///文档详情页more面板内部的点击
        case spaceDocsMoreMenuClick = "ccm_space_docs_more_menu_click"
        /// 导出word设置或导出pdf设置面板曝光
        case docsExportAsSetView = "ccm_docs_export_as_set_view"
        /// 导出word设置或导出pdf设置面板点击
        case docsExportAsSetClick = "ccm_docs_export_as_set_click"
        ///ipad右键菜单框点击更多的view
        case spaceRightClickMenuMoreIpadView = "ccm_space_right_click_menu_more_ipad_view"
        ///ipad右键菜单框点击更多view的click
        case spaceRightClickMenuMoreClick = "ccm_space_right_click_menu_more_click"
        ///新建view
        case spaceCreateNewView = "ccm_space_create_new_view"
        ///新建view上的点击
        case spaceCreateNewClick = "ccm_space_create_new_click"
        ///新建文件夹view
        case spaceCreateNewFolderView = "ccm_space_create_new_folder_view"
        ///新建文件夹view上的点击
        case spaceCreateNewFolderClick = "ccm_space_create_new_folder_click"
        ///选择文件view
        case spaceFileChooseView = "ccm_space_file_choose_view"
        ///选择文件view上的点击
        case spaceFileChooseClick = "ccm_space_file_choose_click"
        ///文件夹view
        case spaceFolderView = "ccm_space_folder_view"
        ///文件夹view里的点击
        case spaceFolderClick = "ccm_space_folder_click"
        ///文件重命名view
        case spaceDriveRenameView = "ccm_space_drive_rename_view"
        ///文件重命名click
        case spaceDriveRenameClick = "ccm_space_drive_rename_click"
        ///文档信息view
        case spaceDocsDetailsView = "ccm_space_docs_details_view"
        ///权限设置view
        case spacePemissionSettingsView = "ccm_space_pemission_settings_view"
        ///保存为自定义模板
        case spaceSaveCustomizeTemplateView = "ccm_space_save_customize_template_view"
        ///导出为面板框
        case spaceExportAsView = "ccm_space_export_as_view"
        ///导出为面板框里的下载
        case spaceExportAsClick = "ccm_space_export_as_click"
        ///点击翻译为之后弹出的view
        case spaceTranslateView = "ccm_space_translate_view"
        /// 点击具体翻译为什么语言
        case spaceTranslateClick = "ccm_space_translate_click"
        /// 添加快捷方式重复提醒弹窗view
        case addShortcutDuplicateCheckView = "ccm_space_add_to_folder_duplicate_view"
        /// 添加快捷方式重复提醒弹窗click
        case addShortcutDuplicateCheckClick = "ccm_space_add_to_folder_duplicate_click"
        /// 未整理 主页
        case spaceUnsortedPageView = "ccm_space_unsorted_page_view"
        /// 云盘主页
        case spaceDrivePageView = "ccm_space_drive_page_view"
        /// 在云盘主页的点击动作
        case spaceDrivePageClick = "ccm_space_drive_page_click"

        // MARK: - ********************* 权限新埋点 start ************************
        // MARK: 权限Click事件
        /// 分享面板点击动作
        case permissionShareClick = "ccm_permission_share_click"
        /// 协作者管理页面点击动作
        case permissionManagementCollaboratorClick = "ccm_permission_management_collaborator_click"
        /// 协作者管理权限选择页面点击动作
        case permissionManagementCollaboratorListClick = "ccm_permission_management_collaborator_list_click"
        /// 邀请协作者页面点击动作
        case permissionSelectContactClick = "ccm_permission_select_contact_click"
        /// ask owner页面点击动作
        case permissionShareAskOwnerClick = "ccm_permission_share_ask_owner_click"
        /// ask owner权限选择页面点击动作
        case permissionShareAskOwnerTypeClick = "ccm_permission_share_ask_owner_type_click"
        /// 修改自己权限弹窗点击动作
        case permissionChangeAlertClick = "ccm_permission_change_click"
        /// 加锁弹窗点击动作
        case lockAlertClick = "ccm_permission_lock_click"
        /// 解锁弹窗点击动作
        case lockRestoreAlertClick = "ccm_permission_lock_restore_click"
        /// 搜索协作者页面点击动作
        case permissionAddCollaboratorClick = "ccm_permission_add_collaborator_click"
        /// 文档权限设置页面点击
        case permissionSetClick = "ccm_permission_set_click"
        /// 微信分享弹窗页面点击
        case permissionShareWechatClick = "ccm_permission_share_wechat_click"
        /// 链接分享设置页面点击
        case permissionShareEncryptedLinkClick = "ccm_permission_share_encrypted_link_click"
        /// 转移所有者弹窗页面点击
        case permissionManagementCollaboratorSetOwnerClick = "ccm_permission_management_collaborator_set_owner_click"
        /// 开启互联网联链接分享弹窗页面点击
        case permissionPromptClick = "ccm_permission_prompt_click"
        /// 申请权限页面点击
        case permissionWithoutPermissionClick = "ccm_permission_without_permission_click"
        /// 复制弹窗页面点击
        case permissionCopyLinkClick = "ccm_permission_copy_link_click"
        /// 申请编辑权限页面点击
        case permissionReadWithoutEditClick = "ccm_permission_read_without_edit_click"
        /// askowner半屏页面点击
        case permissionAskOwnerClick = "ccm_permission_ask_owner_click"
        /// askowner半屏权限选择页面点击
        case permissionAskOwnerTypeClick = "ccm_permission_ask_owner_type_click"
        /// 组织架构邀请协作者页面点击
        case permissionOrganizationAuthorizeClick = "ccm_permission_organization_authorize_click"
        /// 无权限页面点击
        case permissionUnableToApplyClick = "ccm_permission_unable_to_apply_click"
        /// 发送链接页面点击
        case permissionSendLinkClick = "ccm_permission_send_link_click"
        /// owner未开启链接分享提示弹窗点击
        case permissionSharePublicAccessClick = "ccm_permission_share_public_access_click"
        /// 文档内点击人名后授权页面点击
        case permissionShareAtPeopleClick = "ccm_permission_share_at_people_click"
        /// 非owner未开启链接分享提示弹窗点击
        case permissionOwnerTurnedOffPromptClick = "ccm_permission_owner_turned_off_prompt_click"
        /// 文档内@人后授权弹窗提示点击
        case permissionCommentWithoutPermissionClick = "ccm_permission_comment_without_permission_click"
        /// 组织架构授权勾选发送通知时二次确认弹窗页面上的点击
        case permissionOrganizationAuthorizeSendNoticeClick = "ccm_permission_organization_authorize_send_notice_click"
        /// 用户组授权选择页面上的点击
        case permissionDynamicUserGroupAuthorizeClick = "ccm_permission_dynamic_user_group_authorize_click"
        /// 高级权限申请页面 view 事件
        case premiumPermissionApplicationView = "ccm_bitable_premium_permission_application_view"
        /// 高级权限申请页面 click 事件
        case premiumPermissionApplicationClick = "ccm_bitable_premium_permission_application_click"
        
        /// 展示toast，目前场景时禁止截图录屏时的toast
        case toastView = "ccm_docs_toast_view"
        
        // MARK: 权限View事件
        case noneTargetView = "none"
        /// 权限选择页面显示
        case permissionManagementCollaboratorListView = "ccm_permission_management_collaborator_list_view"
        /// 修改自己权限弹窗
        case permissionChangeAlertView = "ccm_permission_change_view"
        /// 加锁权限弹窗
        case lockAlertView = "ccm_permission_lock_view"
        /// 解锁权限弹窗
        case lockRestoreView = "ccm_permission_lock_restore_view"
        /// 分享页面显示
        case permissionShareView = "ccm_permission_share_view"
        /// 协作者列表页面显示
        case permissionManagementCollaboratorView = "ccm_permission_management_collaborator_view"
        /// 搜索协作者页面显示
        case permissionAddCollaboratorView = "ccm_permission_add_collaborator_view"
        /// 邀请协作者页面显示
        case permissionSelectContactView = "ccm_permission_select_contact_view"
        /// 权限设置页面显示
        case permissionSetView = "ccm_permission_set_view"
        /// 点击分享方式-飞书会话后的页面显示
        case permissionShareLarkView = "ccm_permission_share_lark_view"
        /// 点击分享方式-微信后的页面显示
        case permissionShareWechatView = "ccm_permission_share_wechat_view"
        /// 链接分享设置页面显示
        case permissionShareEncryptedLinkView = "ccm_permission_share_encrypted_link_view"
        /// 设为所有者弹窗显示
        case permissionManagementCollaboratorSetOwnerView = "ccm_permission_management_collaborator_set_owner_view"
        /// 开启互联网弹窗提示
        case permissionPromptView = "ccm_permission_prompt_view"
        /// 无权限申请权限页面显示
        case permissionWithoutPermissionView = "ccm_permission_without_permission_view"
        /// 申请编辑权限页面显示
        case permissionReadWithoutEditView = "ccm_permission_read_without_edit_view"
        /// 复制弹窗提示
        case permissionCopyLinkView = "ccm_permission_copy_link_view"
        ///  复制文档受阻时Toast弹窗
        case permissionCopyForbiddenToastView = "ccm_permission_copy_forbidden_toast_view"
        /// askowner半屏页面显示
        case permissionAskOwnerView = "ccm_permission_ask_owner_view"
        /// askowner半屏页面选择权限显示
        case permissionAskOwnerTypeView = "ccm_permission_ask_owner_type_view"
        /// 无权限askowner协作者页面显示
        case permissionShareAskOwnerView = "ccm_permission_share_ask_owner_view"
        /// 无权限askowner协作者页面修改权限显示
        case permissionShareAskOwnerTypeView = "ccm_permission_share_ask_owner_type_view"
        /// 组织架构页面显示
        case permissionOrganizationAuthorizeView = "ccm_permission_organization_authorize_view"
        /// 组织架构搜索页面显示
        case permissionOrganizationAuthorizeSearchView = "ccm_permission_organization_authorize_search_view"
        /// 无权限不能申请权限页面显示
        case permissionUnableToApplyView = "ccm_permission_unable_to_apply_view"
        /// 发送链接页面显示
        case permissionSendLinkView = "ccm_permission_send_link_view"
        /// owner未开启链接分享提示弹窗
        case permissionSharePublicAccessView = "ccm_permission_share_public_access_view"
        /// 文档内点击人名后授权页面显示
        case permissionShareAtPeopleView = "ccm_permission_share_at_people_view"
        /// 非owner未开启链接分享提示弹窗
        case permissionOwnerTurnedOffPromptView = "ccm_permission_owner_turned_off_prompt_view"
        /// 文档内@人后授权弹窗提示
        case permissionCommentWithoutPermissionView = "ccm_permission_comment_without_permission_view"
        /// 组织架构授权勾选发送通知时二次确认弹窗的页面曝光
        case permissionOrganizationAuthorizeSendNoticeView = "ccm_permission_organization_authorize_send_notice_view"
        /// 选择页用户组授权面曝光
        case permissionDynamicUserGroupAuthorizeView = "ccm_permission_dynamic_user_group_authorize_view"
        /// 点击添加协作者后的曝光页面或者点击邀请协作者后的页面曝光
        case permissionAddCollaboratorGroupView = "ccm_permission_add_collaborator_group_view"
        /// 用户组搜索页面显示
        case permissionDynamicUserGroupAuthorizeSearchView = "ccm_permission_dynamic_user_group_authorize_search_view"
        /// 保留标签页面显示
        case retentionSettingView = "ccm_space_retention_setting_view"
        /// 分享页面加载耗时
        case permissionPerformanceShareOpenTime = "ccm_permission_performance_share_open_time_dev"
        /// 分享页面加载成功率
        case permissionPerformanceShareOpenFinish = "ccm_permission_performance_share_open_finish_dev"
        /// 组织架构不通知成员弹窗
        case permissionBlockNotifyAlertView = "ccm_permission_organization_excess_notice_view"
        case permissionBlockNotifyAlertClick = "ccm_permission_organization_excess_notice_click"
        case permissionInternetForbiddenView = "ccm_permission_internet_forbidden_view"
        case permissionInternetForbiddenClick = "ccm_permission_internet_forbidden_click"
        case permissionChangePasswordView = "ccm_permission_change_password_view"
        case permissionChangePasswordClick = "ccm_permission_change_password_click"
        case permissionLeaderAuthorizeSetView = "ccm_permission_leader_authorize_set_view"
        case permissionLeaderAuthorizeSetClick = "ccm_permission_leader_authorize_set_click"
        // ********************* 权限新埋点 end ************************

        // MARK: - mindnote新埋点
        ///  View
        ///  移动端，除了iPad，键盘上方工具栏
        case bottomToolbarView = "ccm_bottom_toolbar_view"
        ///  移动端，除了iPad，键盘上方工具栏中的字体颜色设置
        case bottomToolbarFontColorView = "ccm_bottom_toolbar_font_color_view"
        ///  iPad端，键盘上方工具栏
        case bottomToolbarIPadView = "ccm_bottom_toolbar_iPad_view"
        ///  iPad端，键盘上方工具栏中的header设置
        case bottomToolbarHeaderIPadView = "ccm_bottom_toolbar_header_iPad_view"
        ///  iPad端，键盘上方工具栏中的字体颜色设置
        case bottomToolbarFontColorIPadView = "ccm_bottom_toolbar_font_color_iPad_view"

        // MARK: - 表单新埋点
        ///  View
        ///  表单分享面板上的点击事件
        case bitableFormPermissionClick = "ccm_bitable_form_permission_click"
        ///  表单填写限制view
        case bitableFormLimitSetView = "ccm_bitable_form_limit_set_view"
        ///  表单填写限制click
        case bitableFormLimitSetClick = "ccm_bitable_form_limit_set_click"
        ///  编辑表单填写者view
        case bitableFormPermissionCollaboratorView = "ccm_bitable_form_permission_collaborator_view"
        ///  编辑表单填写者click
        case bitableFormPermissionCollaboratorClick = "ccm_bitable_form_permission_collaborator_click"
        ///  删除表单填写者确认弹框view
        case bitableFormCollaboratorDeleteView = "ccm_bitable_form_collaborator_delete_view"
        ///  删除表单填写者确认弹框click
        case bitableFormCollaboratorDeleteClick = "ccm_bitable_form_collaborator_delete_click"
        ///  邀请表单协作者view
        case bitableFormPermissionSelectContactView = "ccm_bitable_form_permission_select_contact_view"
        ///  邀请表单协作者click
        case bitableFormPermissionSelectContactClick = "ccm_bitable_form_permission_select_contact_click"


        // MARK: - 云文档安全设置和分享设置 新埋点
        /// 点击“谁可以添加协作者”的选项时触发
        case ccmPermissionAddCollaboratorSetView = "ccm_permission_add_collaborator_set_view"
        /// 点击“谁可以复制内容”的选项时触发
        case ccmPermissionFileCopySetView = "ccm_permission_file_copy_set_view"
        /// 点击“谁可以复制内容、创建副本、打印、导出或以图片分享文档”的选项时触发
        case ccmPermissionFileSecuritySetView = "ccm_permission_file_security_set_view"
        ///选择“谁可以评论”的选项时触发
        case ccPermissionFileCommentSetView = "ccm_permission_file_comment_set_view"
        /// 选择“谁可以查看点赞人头像”的选项时触发
        case ccmPermissionCollaboratorProfileListSetView = "ccm_permission_collaborator_profile_list_set_view"
        /// 添加协作者设置页面的点击动作
        case ccmPermissionAddCollaboratorSetClick = "ccm_permission_add_collaborator_set_click"
        /// 复制内容设置页面的点击动作
        case ccmPermissionFileCopySetClick = "ccm_permission_file_copy_set_click"
        /// 安全设置页面的点击动作
        case ccmPermissionFileSecuritySetClick = "ccm_permission_file_security_set_click"
        /// 评论设置页面的点击动作
        case ccmPermissionFileCommentSetClick = "ccm_permission_file_comment_set_click"
        /// “谁可以查看协作者头像及列表”设置页面的点击动作
        case ccmPermissionCollaboratorProfileListSetClick = "ccm_permission_collaborator_profile_list_set_click"
        ///  "你没有查看协作者信息和列表的权限"toast
        case ccmPermissionNoCollaboratorProfileListView = "ccm_permission_no_collaborator_profile_list_view"


        // MARK: - 多维表格高级权限埋点 新埋点
        ///Bitable高级权限设置面板
        case ccmBitablePremiumPermissionSettingView = "ccm_bitable_premium_permission_setting_view"
        ///Bitable高级权限设置面板点击
        case ccmBitablePremiumPermissionSettingClick = "ccm_bitable_premium_permission_setting_click"
        ///Bitable权限规则详情页面
        case ccmBitablePremiumPermissionRulesettingView = "ccm_bitable_premium_permission_rulesetting_view"
        ///Bitable添加协作者邀请页面
        case ccmBitablePremiumPermissionInviteCollaboratorView = "ccm_bitable_premium_permission_invite_collaborator_view"
        ///Bitable添加协作者邀请页面点击
        case ccmBitablePremiumPermissionInviteCollaboratorClick = "ccm_bitable_premium_permission_invite_collaborator_click"
        ///Bitable管理协作者页面
        case ccmBitablePremiumPermissionManageCollaboratorView = "ccm_bitable_premium_permission_manage_collaborator_view"
        ///Bitable管理协作者页面点击
        case ccmBitablePremiumPermissionManageCollaboratorClick = "ccm_bitable_premium_permission_manage_collaborator_click"
        ///Bitable确认移除协作者弹窗
        case ccmBitablePremiumPermissionRemoveConfirmView = "ccm_bitable_premium_permission_remove_confirm_view"
        ///Bitable确认移除协作者弹窗点击
        case ccmBitablePremiumPermissionRemoveConfirmClick = "ccm_bitable_premium_permission_remove_confirm_click"
        ///开启/关闭高级权限
        case ccmBitablePremiumPermissionEntrance = "ccm_bitable_premium_permission_entrance"
        ///Bitable高级权限设置面板开关关闭点击
        case ccmBitablePremiumPermissionDeleteView = "ccm_bitable_premium_permission_delete_view"
        ///Bitable高级权限转换为模板时的预警弹窗露出
        case ccmBitablePremiumPermissionTemplateWarningView = "ccm_bitable_premium_permission_template_warning_view"
        ///Bitable高级权限转换为模板时的预警弹窗点击
        case ccmBitablePremiumPermissionTemplateWarningClick = "ccm_bitable_premium_permission_template_warning_click"
        //高级权限计算类型提示面板露出
        case ccmBitablePremiumPermissionCalculationTypeView = "ccm_bitable_premium_permission_calculation_type_view"
        //高级权限计算类型提示面板的点击
        case ccmBitablePremiumPermissionCalculationTypeClick = "ccm_bitable_premium_permission_calculation_type_click"
        //高级权限文档类型升级提示露出
        case ccmBitablePremiumPermissionBackendUpgradeTipsView = "ccm_bitable_premium_permission_backend_upgrade_tips_view"

        // MARK: - 文档密级管控埋点
        ///文档密级设置页面
        case ccmPermissionSecuritySettingView = "ccm_permission_security_setting_view"
        ///文档密级调宽时的理由申请页面
        case ccmPermissionSecurityDemotionView = "ccm_permission_security_demotion_view"
        ///文档密级设置页面的点击动作
        case ccmPermissionSecuritySettingClick = "ccm_permission_security_setting_click"
        ///将文档由高密级调整为低密级时，填写申请理由时的曝光页面
        case ccmPermissionSecurityDemotionClick = "ccm_permission_security_demotion_click"
        ///用户未确认密级（文档有默认密级，但未获得用户确认）或未设置密级时，文档详情上方新增banner提示view
        case ccmPermissionSecurityDocsBannerView = "ccm_permission_security_docs_banner_view"
        /// 在推荐打标展示时上报
        case scsFileRecommendedLabelBannerView = "scs_file_recommended_label_banner_view"
        /// 在推荐打标发生动作时上报
        case scsFileRecommendedLabelBannerClick = "scs_file_recommended_label_banner_click"
        ///用户未确认密级（文档有默认密级，但未获得用户确认）或未设置密级时，文档详情上方新增banner提示view上的点击
        case ccmPermissionSecurityDocsBannerClick = "ccm_permission_security_docs_banner_click"

        ///降级审批记录页
        case ccmPermissionSecurityResubmitToastView = "ccm_permission_security_resubmit_toast_view"
        ///降级审批记录页上的点击事件
        case ccmPermissionSecurityResubmitToastClick = "ccm_permission_security_resubmit_toast_click"
        ///重复提交申请提示弹窗
        case ccmPermissionSecurityDemotionResubmitView = "ccm_permission_security_demotion_resubmit_view"
        ///重复提交申请提示弹窗上的点击
        case ccmPermissionSecurityDemotionResubmitClick = "ccm_permission_security_demotion_resubmit_click"
        ///密级降级修改结束后的弹窗
        case ccmPermissionSecurityDemotionResultView = "ccm_permission_security_demotion_result_view"
        ///密级降级修改成功弹窗上的点击
        case ccmPermissionSecurityDemotionResultClick = "ccm_permission_security_demotion_result_click"

        // MARK: - 内嵌文档授权埋点
        ///引用文档授权的曝光页面
        case ccmPermissionCitedDocAuthorizeView = "ccm_permission_cited_doc_authorize_view"
        ///引用文档授权的页面点击动作
        case ccmPermissionCitedDocAuthorizeClick = "ccm_permission_cited_doc_authorize_click"
        ///引用文档授权全部授权时的二次确认弹窗
        case ccmPermissionCitedDocAllAuthorizeView = "ccm_permission_cited_doc_all_authorize_view"
        ///引用文档授权全部授权时的二次确认弹窗上的点击
        case ccmPermissionCitedDocAllAuthorizeClick = "ccm_permission_cited_doc_all_authorize_click"

        // MARK: - DLP埋点
        /// owner或分享操作者打开被DLP命中的文档时的提示banner
        case ccmDlpSecurityBannerHintView = "ccm_dlp_security_banner_hint_view"
        /// owner或分享操作者打开被DLP命中的文档时的提示banner上的点击
        case ccmDlpSecurityBannerHintClick = "ccm_dlp_security_banner_hint_click"
        /// DLP拦截结果事件
        case ccmDlpInterceptResultView = "ccm_dlp_intercept_result_view"
        /// DLP安全拦截出现的toast弹框
        case ccmDlpSecurityInterceptToastView = "ccm_dlp_security_intercept_toast_view"
        
        // MARK: - 上级自动授权
        /// 自动授权toast提示
        case ccmPermissionAutomaticPermView = "ccm_permission_automatic_perm_view"
        /// 自动授权toast提示上的点击
        case ccmPermissionAutomaticPermClick = "ccm_permission_automatic_perm_click"
        /// 上级自动授权完成事件（有无toast弹出都需上报)
        case ccmPermissionAutomaticPermFinishView = "ccm_permission_automatic_perm_finish_view"
        
        // MARK: - 评论&mention埋点

        /// 评论页面（侧边栏评论+全文评论）
        case commentView = "ccm_comment_view"
        
        /// 评论UI内点击事件
        case commentClick = "ccm_comment_click"
        
        case commentLoadImgRetryClick = "ccm_comment_load_img_retry_click"
        
        /// @面板曝光事件
        case mentionPanelView = "ccm_mention_panel_view"
        
        /// @面板点击事件
        case mentionPanelClick = "ccm_mention_panel_click"
        
        /// 解析mention由使用xml降级为正则
        case mentionParseDowngrade = "ccm_mention_parse_downgrade_dev"
        
        case commentCopyLinkSuccess = "ccm_comment_copy_link_success"

        
        /// 新建sheet tab
        case sheetCreateTabView = "ccm_sheet_create_tab_view"
        
        /// 查找和替换设置弹窗
        case sheetSearchReplaceView = "ccm_sheet_search_replace_view"
        
        /// 在sheet主页的点击动作 事件：edit_reminder、insert_mention、close_toolbox、smart_screencapture（触发智能截屏）
        /// smart_screencapture_click（智能截屏页面的点击）
        case sheetContentPageClick = "ccm_sheet_content_page_click"

        /// 查找和替换页面按钮点击
        case sheetSearchReplaceClick = "ccm_sheet_search_replace_click"
        /// docx查找和替换页面按钮点击
        case docFindReplacePanelClick = "ccm_doc_find_replace_panel_click"
        /// docx查找和替换面板显示
        case docFindReplacePanelView = "ccm_doc_find_replace_panel_view"

        /// 搜索AI埋点
        case aiSearchView = "asl_search_view"
        case aiSearchClick = "asl_search_click"
        case aiSearchShow = "asl_search_show"
        
        /// 群公告底部模版页面展示
        case announceTemplateViewShow = "ccm_groupchat_template_center_show"
                /// 群公告页面展示
        case announcementPageView = "im_chat_announcement_page_view"
        
        /// 正文表情回应事件
        case contentReactionEvent = "ccm_reaction_click"
        /// 正文表情回应: 展开表情详情
        case contentReactionDetailView = "ccm_reaction_detail_page_view"
        /// 正文表情回应: 表情详情界面事件
        case contentReactionDetailClick = "ccm_reaction_detail_page_click"
        
        /// 评论草稿埋点
        case commentDraftInputShow = "comment_draft_input_show_dev"
        
        case commentFPS = "mobile_comment_scroll_fps_dev"
        
        case commentLoadCost = "mobile_comment_load_cost_dev"
        
        case commentEditCost = "mobile_comment_editable_cost_dev"

        /// 评论成功率埋点
        case commentSuccRate = "mobile_comment_send_dev"

        // MARK: - wiki单页面及对外分享
        /// 「权限范围变更」弹窗
        case permissionScopeChangeView = "ccm_permission_scope_change_view"
        ///权限范围变更页面点击
        case permissionScopeChangeClick = "ccm_permission_scope_change_click"
        /// 链接分享点击item项
        case permissionChangeShareLinkClick = "ccm_permission_change_share_link_click"

        
        /// 文档明细
        case docsDetailsClick = "ccm_space_docs_details_click"
        case docsDetailsRecordView = "ccm_space_docs_details_record_view"
        case docsDetailsRecordClick = "ccm_space_docs_details_record_click"
        case docsDetailsSettingView = "ccm_space_docs_details_setting_view"
        case docsDetailsSettingClick = "ccm_space_docs_details_setting_click"
        
        /// 文档空间公告
        case announcementView = "ccm_announcement_view"
        case announcementClick = "ccm_announcement_click"
        case richEditorOpenEvent = "rich_text_editor_page_load_event_dev"
        
        /// 模板文档顶部banner
        case templateContentPageClick = "ccm_template_content_page_click"
        case templateContentPageView = "ccm_template_content_page_view"
        
        ///DocX转屏埋点
        case docXSwitchHorizontalClick = "ccm_doc_mobile_switch_horizontal_click"
        case docXSwitchVerticalClick = "ccm_doc_mobile_switch_vertical_click"
        
        /// 剪存埋点
        case clipResultClick = "ccm_clip_result_click"
        
        case clipStagDuration = "clip_stage_duration_dev"
        
        /// 复制文档内容
        case docsGlobalCopyClick = "ccm_docs_global_copy_click"
        
        // MARK: - 文档恢复埋点
        case docsDeleteView = "ccm_docs_delete_view"
        case docsDeleteRestoreClick = "ccm_docs_delete_click"
        case docsResotreResultView = "ccm_docs_recover_result_view"
        
        // MARK: - 开发者性能埋点
        case webviewResponsiveState = "ccm_webview_responsive_state_dev"

        // MARK: - Workspace
        // MARK: workspace 业务埋点
        case workspaceRedirectEvent = "ccm_workspace_redirect_event_dev"

        // MARK: - 开发者异常事件埋点
        /// docs内嵌iframe调用jsb异常上报
        case docsIframeJsbForbidden = "ccm_docs_iframe_jsb_event_dev"
        
        // MARK: - 预加载性能埋点
        case docsPreloadDataPerformance  = "ccm_docs_preload_data_dev"
        // MARK: - 文档render错误性能埋点
        case docsRenderJSFailPerformance  = "ccm_docs_render_fail_dev"
        // MARK: - 编辑&添加链接弹框曝光
        case docsLinkEditDialog = "ccm_doc_mobile_link_edit_page_view"
        case docsLinkEditDialogClick = "ccm_doc_mobile_link_edit_page_click"
        case docsBubbleToolBarClick = "ccm_doc_mobile_bubble_toolbar_click"

        case docsCookieMiss = "docs_cookie_miss_dev"
        // MARK: - 同层预览埋点
        case docsDevSameRenderOpenFinish = "dev_same_render_open_finish_dev"
        
        // MARK: - 同步块
        case docContentPageClick = "ccm_doc_content_page_click"
        
        // MARK: - 文档版本埋点
        // 文档版本详情页曝光
        case docsVesionPage = "ccm_docs_version_page_view"
        case sheetVersionPage = "ccm_sheet_version_page_view"
        // 文档版本右上角“...”点击出现的更多面板
        case docsVersionMoreMenu = "ccm_docs_version_more_menu_view"
        case sheetVersionMoreMenu = "ccm_sheet_version_more_menu_view"
        // 文档版本右上角“...”点击出现的更多面板的点击
        case docsVersionMoreMenuClick = "ccm_docs_version_more_menu_click"
        case sheetVersionMoreMenuClick = "ccm_sheet_version_more_menu_click"
        // 重命名版本弹框的展示
        case docsRenameVersion = "ccm_doc_rename_version_view"
        case sheetRenameVersion = "ccm_sheet_rename_version_view"
        // 重命名版本弹框的点击
        case docsRenameVersionClick = "ccm_doc_rename_version_click"
        case sheetRenameVersionClick = "ccm_sheet_rename_version_click"
        // 删除版本提示页的展示
        case docsDeleateVersion = "ccm_doc_delete_version_view"
        case sheetDeleteVersion = "ccm_sheet_delete_version_view"
        // 删除版本提示页的点击
        case docsDeleateVersionClick = "ccm_doc_delete_version_click"
        case sheetDeleteVersionClick = "ccm_sheet_delete_version_click"
        // 版本已删除回到原文档的展示
        case docsVersionDeletedTip = "ccm_doc_version_deleted_tips_view"
        case sheetVersionDeletedTip = "ccm_sheet_version_deleted_tips_view"
        // 版本已删除回到原文档的点击
        case docsVersionDeletedTipClick = "ccm_doc_version_deleted_tips_click"
        case sheetVersionDeletedTipClick = "ccm_sheet_version_deleted_tips_click"
        // 版本列表展示
        case docsVersionPanel = "ccm_doc_saved_version_view"
        case sheetVersionPanel = "ccm_sheet_saved_version_view"
        // 版本列表面板点击某个版本
        case docsVersionSavedClick = "ccm_doc_saved_version_click"
        case sheetVersionSavedClick = "ccm_sheet_saved_version_click"

        // 设置文档新鲜度面板埋点
        case docfreshnessCardClick = "ccm_space_freshness_card_click"
        // setData token不一致问题接口埋点
        case tokenInconsistency = "dev_performance_doc_token_inconsistency"
        
        // MARK: - 一事一档相关埋点
        // 应用关联文档插件曝光
        case applicationDocsPluginView = "ccm_application_docs_plugin_view"
        // 应用关联文档插件点击
        case applicationDocsPluginClick = "ccm_application_docs_plugin_click"

        public var stringValue: String {
            self.rawValue
        }

        public var shouldAddPrefix: Bool {//判断是否需要添加Docs_前缀
            if self.rawValue.hasPrefix("ccm_space") { return false }
            switch self {
            case .linkClicked, .searchTime, .viewSearchResult, .viewSearchResultRollFps, .commonPricePopup, .commonPricePopClick:
                return false
            default:
                return true
            }
        }
    }

    static let shouldReportSpaceVersionPrefixes = ["ccm_space", "ccm_wiki", "ccm_permission"]
    static var eventSpaceVersion: String = {
        return UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? "new_format" : "original"
    }()

    /// 使用枚举值打点
    #warning ("从4.2版本开始废弃使用旧接口进行埋点，后续埋点前缀需要大家自己填写，旧逻辑还是走这里加前缀。故不能删除此处逻辑。")
    /// 旧接口，默认会帮大家加上前缀docs_
    public static func log(enumEvent: EventType, parameters: [AnyHashable: Any]?) {
        // 以 ccm_space、ccm_wiki、ccm_permission 开头的事件统一加上 space_version 参数
        var params: [AnyHashable: Any]? = parameters
        if shouldReportSpaceVersionPrefixes.contains(where: enumEvent.rawValue.hasPrefix) {
            params?.updateValue(eventSpaceVersion, forKey: "space_version")
        }
        Self.log(enumEvent: enumEvent as DocsTrackerEventType, parameters: params)
    }
    /// 新接口，并不会帮大家加上前缀
    public static func newLog(enumEvent: EventType, parameters: [AnyHashable: Any]?) {
        // 以 ccm_space、ccm_wiki、ccm_permission 开头的事件统一加上 space_version 参数
        var params: [AnyHashable: Any]? = parameters
        if shouldReportSpaceVersionPrefixes.contains(where: enumEvent.rawValue.hasPrefix) {
            params?.updateValue(eventSpaceVersion, forKey: "space_version")
        }
        Self.newLog(enumEvent: enumEvent as DocsTrackerEventType, parameters: params)
    }

    public class func startRecordTimeConsuming(eventType: EventType, parameters: [String: Any]?, subType: String = "") {
        self.startRecordTimeConsuming(eventType: eventType as DocsTrackerEventType, parameters: parameters, subType: subType)
    }

    public class func endRecordTimeConsuming(eventType: EventType, parameters: [String: Any]?, subType: String = "") {
        self.endRecordTimeConsuming(eventType: eventType as DocsTrackerEventType, parameters: parameters, subType: subType)
    }
}
