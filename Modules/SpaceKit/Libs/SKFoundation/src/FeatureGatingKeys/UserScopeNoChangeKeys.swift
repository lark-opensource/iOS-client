//主端推荐的默认的FG使用方法，提供用户租户周期内稳定的FG值，更详细的说明请阅读 https://bytedance.feishu.cn/docx/doxcnJ7dzCiiqRxTi7yc9Jhebxe
import LarkSetting
public final class UserScopeNoChangeFG {
    // 按研发人员名称做scope，避免每次提交代码的时候FG文件冲突导致的反复rebase
    /// yinyuan.0
    public final class YY {
        // 6.2
        public static var allowAllNetLogDisable: Bool { fg("ccm.net.allow_all_log.disable") }
        // 6.5
        public static var bitableTabActivityTipsEnable: Bool { fg("ccm.bitable.tab.activity.tips.enable") }
        public static var bitableWorkbenchNewEnable: Bool { fg("ccm.bitable.workbench.new.enable") }
        // 6.7
        public static var bitableTabActivityEnable: Bool { fg("ccm.bitable.tab.activity.enable") }
        public static var bitableActivityNewDisable: Bool { fg("ccm.bitable.activity.new.disable") }
        public static var bitableBannerTitleMultiLineDisable: Bool { fg("ccm.bitable.banner.title_multi_line.disable") }
        public static var bitableHomepageFavDisable: Bool { fg("ccm.bitable.homepage.fav.disable") }
        // 7.1
        public static var bitableReferPermission: Bool { fg("ccm.bitable.base_refer_permission.enable") }
        // 7.4
        public static var bitableRecordShareFixDisable: Bool { fg("ccm.bitable.record_share_fix.disable") }
        public static var bitableRedesignFormViewFixDisable: Bool { fg("ccm.bitable.redesign_form_view_fix.disable") }
        // 7.6
        public static var bitableHeaderFixDisable: Bool { fg("ccm.bitable.header_fix.disable") }
        public static var bitablePreviewFileFullscreenDisable: Bool { fg("ccm.bitable.preview_file_fullscreen.disable") }
        public static var bitablePerfOpenInRecordShare: Bool { fg("base.bitable_card.perf_open_in_record_share") }
        public static var bitablePadCommentsKeyboardFixDisable: Bool { fg("ccm.bitable.pad_comments_keyboard_fix.disable") }
        public static var bitableDateFormatFixDisable: Bool { fg("base.bitable_card.date_format_fix.disable") }
        public static var bitableFieldLayoutFixDisable: Bool { fg("ccm.bitable.field_layout_fix.disable") }
        
        // 7.7
        /// Base 外记录快捷新建页是否开启
        public static var baseAddRecordPage: Bool { fg("ccm.bitable.add_record_page.enable")}
        /// Base 内提交模式是否生效，分享入口是否显示
        public static var baseAddRecordPageShareEnable: Bool { fg("ccm.bitable.add_record_page.share.enable")}
        public static var baseAddRecordPageAutoSubscribeEnable: Bool { fg("ccm.bitable.add_record_page.auto_subscribe.enable")}
        public static var bitableTemplateCreateFixDisable: Bool { fg("ccm.bitable.template_create_fix.disable") }
        public static var bitableGeoLocationFixDisable: Bool { fg("ccm.bitable.geo_location_fix.disable") }
        public static var bitableDocxInBaseFixJumpDisable: Bool { fg("ccm.bitable.docx_in_base_jump_fix.disable") }
        
        // 7.8
        public static var bitableAddRecordGestureV2Disable: Bool { fg("ccm.bitable.add_record_gesture_v2.disable") }
        public static var bitableCardQueueBlockedFixDisable: Bool { fg("ccm.bitable.card_queue_blocked_fix.disable") }
        
        // 7.9
        public static var bitableRecordShareCatalogueDisable: Bool { fg("ccm.bitable.record_share_catalogue.disable") }
        public static var bitableContainerViewSearchFixDisable: Bool { fg("ccm.bitable.container_view_search_fix.disable") }
        
    }
    
    /// wujiasheng.token
    public final class WJS {
        // 已内部重新划分负责人部分FG
        // 千人一面相关，ZYS
        public static var bitableMobileSupportRemoteCompute: Bool { fg("ccm.bitable.mobile.support_remote_compute") }
        public static var bitableRemoteComputeUpgrade: Bool { fg("bitable.mobile.remote_compute.upgrade") }
        // 字段相关，YY
        // 一行一群
        public static var bitableFieldGroupNewEditPanel: Bool { fg("ccm.bitable.field.group.new_edit_panel") }

        // MARK: - 7.3
        public static var baseLarkFormRemindInviterEnable: Bool { fg("ccm.base.lark_form_remind_inviter.enable") }
        // MARK: - 7.9
        // 是否开启邀请链路优化
        public static var baseFormShareNotificationV2: Bool { fg("ccm.base.form_share_notification_v2") }
    }
    
    /// xiongmin.super
    public final class XM {
        // MAKR: - 6.2
        public static var ccmBitableCardOptimized: Bool { fg("ccm.bitable.card_optimized") }
        // MARK: - 6.3
        public static var ccmBitableRecordsGantt: Bool { fg("bitable.pricing.recordsnumandgantt.fe") }
        // MAKR: -7.4
        public static var cardOpenLoadingEnable: Bool { fg("ccm.bitable.redesin.loading") }
        // MARK: - 7.5
        public static var bitableArchiveEnable: Bool { fg("ccm.bitable.archive_table_enabled") }
        // MAKR: - 7.7
        public static var blockCatalogueDarkModeFixDisable: Bool { fg("ccm.bitable.block_catalogue_dark_mode.fix.disable") }
        // MARK: - 7.8
        public static var nativeCardViewEnable: Bool { fg("ccm.bitable.native_card_view") }
        // MAKR: - 7.8
        public static var allowUserInteractionInAnimationDisable: Bool { fg("ccm.bitable.allow_animation.disable") }
        public static var cellForItemFixDisable: Bool { fg("ccm.bitable.cell_for_item.disable") }
        public static var dduiUnmoutBlockFixDisable: Bool { fg("ccm.bitable.ddui_unmount_fix.disable") }
        // MAKR: - 7.9
        public static var docxBaseOptimized: Bool { fg("ccm.bitable.docx_base.optimized.enable") }
    }
    
    public final class PXR {
        public static var btHomepageSwitchTabEnable: Bool { fg("ccm.bitable.homepage.new.enable") }
        public static var btHomepageSwitchTabLanguageEnable: Bool { fg("ccm.bitable.homepage.new.no.zh.enable") }
        public static var btSingleCardShowQrcodeWhenShareEnable: Bool { fg("base.record.share_opt.enable") }
        public static var baseHomepageHasSurveyEnable: Bool { fg("ccm.bitable.homepage.hassurvey.enable") }
        public static var baseCCMSpaceHasSurveyEnable: Bool { fg("ccm.bitable.ccmspace.hassurvey.enable") }
        public static var btHomepageFirstShowMySpaceEnable: Bool { fg("ccm.bitable.hp.first.show.myspace.enable") }
        public static var btHomepageRecommendDataCacheDisable: Bool { fg("bitable.homepage.new.native.recommend.storage.disable") }
        public static var btHomepageXYZDiversionEnable: Bool { fg("bitable.homepage.new.xyz.enable") }
        public static var baseWikiSpaceHasSurveyEnable: Bool { fg("bitable.wiki.hassurvey.enable") }
        /// MARK: - 7.3 卡片是否存在订阅功能
        public static var bitableRecordSubscribeEnable: Bool { fg("bitable.mobile.record_subscribe.enable") }
        /// MARK: - 7.3 订阅消息是否高亮字段
        public static var bitableRecordFieldHLEnable: Bool { fg("bitable.mobile.record_share_field_highlight.enable") }
        /// MARK: - 7.3 是否关闭被动订阅
        public static var bitableRecordCloseAutoSubscribe: Bool { fg("bitable.record_subscribe.auto.disable") }
        /// MARK: - 7.4 homepagev3版本
        public static var bitablehHomepageV3Enable: Bool { fg("bitable.homepage.v3.enable") }
    }
    
    /// majie.7
    public final class MJ {
        /// MARK: - 5.32
        public static var newWikiHomeFilterEnable: Bool { fg("ccm.wiki.mobile.space_classification_enable") }
        /// MARK: - 6.3 IM发送云文档页面支持侧滑
        public static var imSendDocSwipeEnable: Bool { fg("ccm.workspace.send_doc_swipe_enable") }
        /// MARK: - 7.1
        // 文件夹block
        public static var folderBlockEnable: Bool {
            fg("ccm.workspace.folder_block_enable")
        }
        // 云文档tab新刷新策略
        public static var newRecentListRefreshStrategy: Bool {
            fg("ccm.workspace.new_recent_list_refresh_strategy")
        }
        public static var sidebarSharedEnable: Bool {
            fg("ccm.workspace.next.sidebar_shared")
        }
        /// MARK: -7.2
        // wiki知识库支持自定义配置icon
        public static var wikiSpaceCustomIconEnable: Bool {
            fg("ccm.workspace.custom_space_icon")
        }
        /// MARK: - 7.3
        // wps支持.wps和.et格式文档
        public static var etAndWpsFileTypeEnable: Bool {
            fg("ccm.drive.wps_support_wps_and_et")
        }
    
        // 隐藏共享列表按编辑事件排序
        public static var disableShareEditTimeSort: Bool {
            fg("ccm.space.disable_share_edittime_sort")
        }
        
        /// MARK: - 7.4
        // space首页UI对齐web
        public static var newIpadSpaceEnable: Bool {
            WWJ.newSpaceTabEnable && fg("ccm.workspace.new_ipad_space_enable")
        }
        
        /// MARK: - 7.6
        // 新首页置顶目录树协同
        public static var sidebarSyncEnable: Bool {
            fg("ccm.workspace.sidebar_synergy_enable")
        }
        
        /// MARK: - 7.9
        public static var quickAccessFolderEnable: Bool {
            fg("ccm.mobile.pin_folder_enable")
        }
    }
    
    public final class GQP {
        // MARK: - 5.25
        public static var sensitivityLabelsecretopt: Bool { fg("ccm.permission.mobile.secretopt") }

        /// KA-HQ https://bytedance.feishu.cn/docx/WNaFdA46HobJbRxK4ZWcZpcNnmb
        public static var legacyFileProtectCloudDocDownload: Bool { fg("ccm.security.legacy_file_protect_cloud_doc_download") }
    }
    
    public struct LJY {
        
        // MARK: - 5.27
        public static var enableRnAggregation: Bool {
            fg("ccm.docx.mobile.enable_rn_aggregation")
        }
        
        public static var fixSheetSwitchKeyobardInIOS16: Bool { fg("ccm.sheet.adapter_ipad16_keyboard_switch") }
        
        // MARK: - 5.31
        
        //需要按租户开启，不能删除
        public static var disableCreateDoc: Bool { fg("ccm.docx.mobile.disable_doc1.0_create")}
        
        // MARK: - 6.0
        public static var enableRenderSSRWhenPreloadHtmlReady: Bool {
            fg("ccm.webview.load_ssr_after_wating_html_ready")
        }
        
        public static var enableDocsUserBehavior: Bool {
            #if DEBUG
            true
            #else
            fg("ccm.docs.forecast_enable")
            #endif
        }
        
        // MARK: - 6.4
        public static var enableResetWKProcessPool: Bool {
            #if DEBUG
            true
            #else
            fg("ccm.docs.enable_reset_wkprocesspool")
            #endif
        }
        
        // MARK: - 6.8
        public static var enableSSRWebView: Bool {
            fg("ccm.docs.enable_ssrwebview")
        }
        
        // MARK: - 6.11
        public static var templateInjectFg: Bool {
            fg("ccm.docs.template_inject_fg")
        }
        
        public static var enableSyncBlock: Bool {
            #if DEBUG
            true
            #else
            fg("ccm.docs.all.synced_block_enable")
            #endif
        }

        // MARK: - 7.1
        public static var injectTXTProfileFg: Bool {
            #if DEBUG
            true
            #else
            fg("ccm.mobile.inject_fg_enable")
            #endif
        }
        
        public static var enableIFrameCheckVPN: Bool {
            //是否开启vpn检测的反向fg
            !fg("ccm.mobile.vpn_iframe_notify")
        }
        
    }
    
    /// zhangyushan.s
    public final class ZYS {
        /// 7.8 数字字段无效输入清空 revert 开关
        public static var numberFieldIllegalFixRevert: Bool { fg("ccm.bitable.number_field_illegal_fix_revert") }
        /// header 安全区高度修复 revert 开关
        public static var recordHeaderSafeAreaFixRevertV2: Bool { fg("ccm.bitable.record_header_safe_area_fix_revert.v2") }
        /// 字段名去除高度限制 revert 开关
        public static var baseFieldNameHeightNoLimitRevert: Bool { fg("ccm.bitable.field_name_height_no_limit_revert") }
        /// bitable 支持仪表盘分享
        public static var dashboardShare: Bool { fg("ccm.bitable.share.dashboard") }
        /// 跨 Base 数据同步
        public static var integrationBase: Bool { fg("ccm.bitable.integration.base") }
        /// 表单支持 lookup 和 formula 字段
        public static var formSupportFormula: Bool { fg("ccm.bitable.form_support_formula") }
        
        /// 卡片样式功能开关
        public static var gridMobileViewEnable: Bool { fg("ccm.bitable.grid_mobile_view_enable") }
        /// 默认使用卡片样式开关
        public static var defaultMobileViewEnable: Bool { fg("ccm.bitable.default_mobile_view_enable") }
        /// Bugfix: https://meego.feishu.cn/larksuite/issue/detail/9322963
        public static var disableBarHiddenInPermView: Bool { fg("ccm.bitable.disable_bar_hidden_in_perm_view") }
        /// Bitable 分享链接域名跟随文档修复 revert 开关
        public static var disableBitableShareHostFix: Bool { fg("ccm.bitable.disable_bitable_share_host_fix") }
        // 扩展字段（人员字段支持扩展通讯录）
        public static var fieldSupportExtend: Bool { fg("ccm.bitable.field.extend_address") }
        // 记录分享 V2
        public static var baseRecordShareV2: Bool { fg("bitable.record.share.v2") }
        // 记录分享页左滑返回手势 revert 开关
        public static var recordShareSwipeCloseDisable: Bool { fg("bitable.record.share.swipe.close.disable") }
        // 单条记录视觉优化
        public static var recordCardV2: Bool { ZJ.btCardReform }
        /// 高级权限继承经典权限总开关
        public static var baseAdPermRoleInheritance: Bool { fg("base.advanced_permission.role_inheritance") }
        /// 控制新开启的base降级策略默认值是否选中默认角色
        public static var baseAdPermAggressiveDefaultPolicy: Bool { fg("base.advanced_permission.aggressive_default_policy") }
        /// 控制是否显示具体的“未分配角色的协作者”
        public static var baseAdPermAggressiveRolePreview: Bool { fg("base.advanced_permission.aggressive_role_preview") }
        /// 记录链接在 iPad 临时区内无法打开 Bugfix revert 开关
        public static var baseRecordTempOpenFixDisable: Bool { fg("bitable.record_temp_open_fix.disable") }
        /// 高级权限申请页 Owner 信息由后端返回
        public static var adPermApplyOwnerInfo: Bool { fg("ccm.bitable.advanced_permission.apply_owner_info") }
        /// Base 外记录页是否支持复制 revert 开关
        public static var recordCopySupportRevert: Bool { fg("ccm.bitable.zys.record_copy_support") }

        /// 5w 行按需加载
        public static var loadRecordsOnDemand: Bool { fg("ccm.bitable.table_ondemand_enabled") }
    }
    
    /// liujinwei
    public final class LJW {
        // MARK: - 5.25
        public static var toolbarAdapterForKeyboard: Bool { fg("ccm.doc.toolbar_adapter_for_ios16_keyboard") }
        
        // MARK: - 5.26
        public static var cameraStoragePermission: Bool { fg("ccm.doc.mobile.camera_storage_permission") }
        
        // MARK: - 5.27
        ///webView是否支持ios16气泡菜单
        public static var editMenuEnable: Bool { fg("ccm.webview.ios16_edit_menu_interaction_enable") }
        
        ///docx工具栏diff优化
        public static var toolbarDiffOptimize: Bool {
            fg("ccm.doc.toolbar_diff_optimize")
        }
        
        ///图片查看器支持查看裁剪过的图片
        public static var cropImageViewEnable: Bool {
            fg("ccm.doc.mobile.image_crop")
        }
        
        public static var sheetInputViewFix: Bool {
            fg("ccm.sheet.mobile.toolbar_layout_optimization")
        }

        //是否可查看裁剪动图
        public static var gifCropEnable: Bool {
            fg("ccm.doc.mobile.gif_crop")
        }

        // MARK: - 6.1
        ///newCache存储文件密钥根据userId实时更新
        public static var cipherUpdatedInRealtimeEnabled: Bool {
            fg("ccm.mobile.cipher_updated_in_realtime_enabled")
        }
        
        public static var sheetSecondaryClickEnabled: Bool {
            fg("ccm.webview.disable_secondary_click")
        }

        // MARK: - 6.5
        ///是否支持新版slides打开
        public static var slidesEnabled: Bool {
            return fg("ccm.mobile.slides_enabled")
        }
        
        public static var docFix: Bool {
            return fg("ccm.doc.mobile.toolbar_layout_optimization")
        }

        public static var urlUpdateEnabled: Bool {
            return fg("ccm.mobile.update_url_after_offline_sync")
        }

        public static var preloadHitOptimizationEnable: Bool {
            return fg("ccm.mobile.preload_hit_optimization_enable")
        }

        public static var batchMetaEnabled: Bool {
            return fg("ccm.mobile.batch_meta_enabled")
        }
        
        public static var catalogHoverTipEnabled: Bool {
            return fg("ccm.mobile.catalog_hover_tip_enabled")
        }

        public static var checkErrorEnabled: Bool {
            return fg("ccm.mobile.data_storage_check_error_enabled")
        }

        public static var rememberTranslateEnabled: Bool {
            return fg("ccm.mob.docx.translate_remember")
        }
        
        //同步块独立打开
        public static var syncBlockSeparatePageEnabled: Bool {
            fg("ccm.docx.synced_block.separate_page_mobile")
        }

        public static var sheetVersionEnabled: Bool {
            fg("ccm.sheet.mobilereadversion")
        }

        public static var urlEncodeDisabled: Bool {
            fg("ccm.mobile.url_query_encode_enabled")
        }
        
        public static var syncBlockPermissionEnabled: Bool {
            fg("ccm.docs.synced_block.permission")
        }

        public static var recordHitPreloadEnabled: Bool {
            fg("ccm.mobile.hit_preload_record_enabled")
        }
        
        public static var dbErrorOpt: Bool {
            fg("ccm.mobile.db_error_optimization")
        }
    }
    
    /// zengsenyuan
    public final class ZSY {
        public static var workbench: Bool { fg("ccm.bitable.file_add_to_workbench") }
    }

    /// zoujie.andy
    public final class ZJ {
        // MARK: - 5.26
        public static var btCellLargeContentOpt: Bool { fg("ccm.bitable.cell_with_large_content_optimize") }
        // MARK: - 5.27
        public static var btLinkPanelCreatRecordOpt: Bool { fg("ccm.mobile.bitable.link_panel_create_record_optimize") }
        /// 卡片diff recordID修改
        public static var recordDiffFixDisable: Bool { fg("ccm.bitable.reocrd_diff_fix.disable") }
        /// 卡片iOS12 diff crash修改
        public static var btDiffFixIOS12Disable: Bool { fg("ccm.bitable.diff_fix_for_iOS12.disable") }
        /// 卡片关联面板循环请求bugfix
        public static var btLinkPanleSearchDisable: Bool { fg("ccm.bitable.link_panle_search_fix.disable") }
        /// 关联字段编辑面板数据协同bugfix
        public static var btLinkPanelUpdateDataFixDisable: Bool { fg("ccm.bitable.link_panle_update_data_fix.disable") }
        /// 筛选关联字段条件值选择面板搜索bugfix
        public static var btFilterLinkViewSearchFixDisable: Bool { fg("ccm.bitable.filter_link_view_search_fix.disable") }
        /// 侧滑手势无效bugfix
        public static var btCustomTopContainerPopgestureFixDisable: Bool { fg("ccm.bitable.custom_top_pop_gesture_fix.disable") }
        /// 分享面板
        public static var btShareAddExtraParam: Bool { fg("ccm.bitable.share.add_extra_param") }
        /// 前端短时间内调用多次updateField事件导致crash bugfix
        public static var btCardUpdateFieldActionFixDisable: Bool { fg("ccm.bitable.card_update_field_action_fix.disable") }
        /// 单条记录改造
        public static var btCardReform: Bool { fg("ccm.bitable.card_reform") }
        /// 移动端卡片视图支持封面设置
        public static var btCardViewCoverEnable: Bool { fg("base.cardview.cover_enable") }
        /// 移动端卡片人员字段面板header背景色bugfix disable
        public static var btCardChatterPanelHeaderColorFixDisable: Bool { fg("ccm.bitable.card_chattre_panel_color_fix.disable") }
        /// 移动端base卡片push的情况下拿不到bwindow bugfix disable
        public static var windowNotFoundFixDisable: Bool { fg("ccm.mobile.window_no_found_fix.disable") }
        /// 移动端base单条记录改造itemView tab bugfix disable
        public static var btItemViewStageTabsFixDisable: Bool { fg("ccm.bitable.itemview_stage_tabs_fix.disable") }
        /// 移动端showPanel高度bugfix disable
        public static var btShowPanelHeightFixDisable: Bool { fg("ccm.bitable.showpanel_height_fix.disable") }
        /// 移动端卡片视图配置面板滚动调整高度bugfix disable
        public static var btCardViewLayoutSettingHeightFixDisable: Bool { fg("ccm.bitable.cardview_layout_setting_height_fix.disable") }
        /// 移动端单条记录iPad上打开多webview时bugfix disable
        public static var btItemViewIPadFixDisable: Bool { fg("ccm.bitable.itemview_ipad_fix.disable") }
        /// 移动端单条记录附件字段编辑态bugfix
        public static var btItemViewAttachmentFieldEditFixDisable: Bool { fg("ccm.bitable.itemview_attachment_edit_fix.disable") }
        /// 移动端tableView crash bugfix disable
        public static var tableViewUpdateFixDisable: Bool { fg("ccm.mobile.tableview_update_fix.disable") }
        /// 移动端搜索状态下webview safeArea bugfix disable
        public static var searchWebSafeAreaUpdateFixDisable: Bool { fg("ccm.mobile.search_web_safearea_fix.disable") }
        /// 移动端单条记录originField数据  bugfix disable
        public static var btItemViewOriginFieldsFixDisable: Bool { fg("ccm.mobile.bitable.itemview_originfied_fix.disable") }
        /// 移动端单条记录contentOffset重置  bugfix disable
        public static var btItemViewContentOffsetFixDisable: Bool { fg("ccm.mobile.bitable.itemview_contentoffset_fix.disable") }
        /// 移动端单条记录流程字段高级权限新增  bugfix disable
        public static var btItemViewProAddStageFieldFixDisable: Bool { fg("ccm.mobile.bitable.itemview_proadd_stagefield_fix.disable") }
        /// 移动端单条记录弹出方式改成模态 bugfix disable
        public static var btItemViewPresentModeFixDisable: Bool { fg("ccm.mobile.bitable.itemview_present_mode_fix.disable") }
        // 移动端showPanel docx iPad目录 bugfix disable
        public static var btShowPanelIPadFixDisable: Bool { fg("ccm.mobile.bitable.show_panel_ipad_fix.disable") }
        // 移动端单记录 diff bugfix disable
        public static var btItemViewDiffCrashFixDisable: Bool { fg("ccm.mobile.bitable.itemview_diff_crash_fix.disable") }
    }
    
    /// qiyongka.ka
    public final class QYK {
        // MARK: - 6.11
        // bitable 方形Icon设置
        public static var btSquareIcon: Bool { fg("ccm.bitable.square_icon") }

        // MARK: - 7.0
        /// 附件上传数据异常引发的crash，bugfix
        public static var btAttachmentUploadingCrashFixDisable: Bool { fg("ccm.bitable.attachment_uploading_crash_fix_disable") }
        
        // MARK: - 7.1
        /// base 区域切换记录卡顿，bugfix
        public static var btBaseSwitchRecordFixDisable: Bool { fg("ccm.bitable.base_switch_record_fix_disable") }

        // AI 扩展字段开关
        public static var btChatAIExtension: Bool { fg("ccm.bitable.mobile.ai_field_lark") }
        
        // MARK - 7.3
        /// bugfix MS, iOS作为跟随者打开附件后不能继续跟随切换附件
        public static var btSwitchAttachInMSFixDisable: Bool { fg("ccm.bitable.switch_attach_in_ms_fix_disable") }
        
        /// bugfix sheet@base从表格视图连续切换两个表单视图第二个表单视图展示为表格视图的数据
        public static var btSwitchFormInSheetFixDisable: Bool {
            fg("ccm.bitable.switch_form_in_sheet_fix_disable")
        }
        
        /// bugfix: 飞书导航栏的base标签，打开卡片base内跳转链接不会自动关闭卡片
        public static var btNavigatorCardCloseFixDisable: Bool {
            fg("ccm.bitable.navigator_card_close_fix_disable")
        }
        
        /// bugfix: 临时区拖动时，卡片偏移计算错误
        public static var btCardOffsetErrorFixDisable: Bool {
            fg("ccm.bitable.card_offset_error_fix_disable")
        }
        
        /// release/7.4 bugfix: 打开侧边栏目录切换到docx,docx中打开记录卡片没有从侧边打开
        public static var btCardPresentFromSideErrorFixDisable: Bool {
            fg("ccm.bitable.card_present_from_side_error_fix_disable")
        }
        
        /// release/7.7 bugfix: 侧边栏卡片不关闭
        public static var btSideCardCloseFixDisable: Bool {
            fg("ccm.bitable.side_card_close_fix_disable")
        }
        
        /// release/7.8 bugfix: base@sheet 卡片宽度计算问题
        public static var btSideCardWidthOnSheetFixDisable: Bool {
            fg("ccm.bitable.side_card_width_on_sheet_fix_disable")
        }
        
        // release/7.9.0 解决AI MaskView 遮挡AI配置面板的问题
        public static var btAIMaskViewFixDisable: Bool {
            fg("ccm.bitable.ai_mask_view_fix_disable")
        }
        
    }

    // zhuangyizhong
    public final class ZYZ {
        // MARK: - 5.25
        // bitable 附件上传任务支持恢复
        public static var btUploadAttachRestorable: Bool { fg("ccm.mobile.bitable.upload_attachment_restorability") }
    }
    
    // guoxinyi
    public final class GXY {
        // MARK: - 5.26
        // more面板查看版本列表入口
        public static var docsVersionOnBoarding: Bool {
            fg("doc.verson.mobileoboarding")
        }
        // MARK: - 5.27
        // mindnote支持横屏
        public static var mindnoteSupportScreenViewHorizental: Bool {
            fg("ccm_mindnote_mobile.screen_view_horizental")
        }
        // MARK: - 5.28
        // ms下webview复用池个数配置
        public static var msShareOptimizationEnable: Bool {
            fg("ccm.msshare.optimization_enable")
        }
        
        // 文档关闭时检查是否需要做ssr预加载
        public static var ssrPreloadOptimizationEnable: Bool {
            fg("ccm.ssrpreload_optimization_enable")
        }
        
        // MARK: - 5.29
        public static var landscapePopGestureEnable: Bool {
            fg("ccm.docs.landscapegesture_enable")
        }
        
        // MARK: - 5.30
        // 文档打开render出错时，上报错误码
        public static var renderReportEnable: Bool {
            fg("ccm.openfile.render_report_enable")
        }
        
        // wiki-DocX预加载SSR使用单独的队列
        public static var wikiDocxSSRQueueEnable: Bool {
            fg("ccm.docs.wiki_docx_ssr_queue_enable")
        }
        
        // iOS16系统增加锁定模式状态上报
        public static var lockdownModeEnable: Bool {
            fg("ccm.docs.webview_lockdown_enable")
        }
        
        // MARK: - 5.31
        // docx文档SSR闲时预加载FG
        public static var docxSSRIdelPreloadEnable: Bool {
            fg("ccm.mobile.docx_ssr_load_optimization")
        }
        
        // MARK: - 5.32
        // 文档预加载队列支持优先级
        public static var docxPreloadTaskPriorityEnable: Bool {
            fg("ccm.docs.preload_priority_enable")
        }
        
        // 文档预加载任务支持本地持久化
        public static var docxPreloadTaskArchviedEnable: Bool {
            fg("ccm.docs.preload_archvied_enable")
        }
        
        // docx_Feed增加首屏数据预加载开关
        public static var docsFeedFirstLoadPreloadEnable: Bool {
            fg("ccm.mobile.docx_docs_feed_load_enable")
        }
        
        // MARK: - 6.0
        /// iphoneWebview复用池个数，动态调整FG
        public static var docxDynamicWebViewCountEnable: Bool {
            fg("ccm.docs.dynamic_webview_count_enable")
        }
        
        /// 复用池里webview定时卡死检测
        public static var inPoolWebViewCheckUnResponseTimerEnable: Bool {
            fg("ccm.docs.webview_in_pool_check_enable")
        }
        
        /// 预加载队列优先级
        public static var docsPreloadQueuePriorityOldEnable: Bool {
            fg("ccm.docs.preload_queue_priority_enable")
        }
        
        // MARK： -6.1
        /// 预加载队列优先级
        public static var docsPreloadQueuePriorityEnable: Bool {
            fg("ccm.docs.preload_queue_priority_new_enable")
        }
        
        /// docs_feed预加载触发SDKInit闲时任务
        public static var docsFeedPreloadIdleTaskEnable: Bool {
            fg("ccm.docs.feed_preload_idle_task_enable")
        }
        
        // MARK： -6.2
        /// 数据库增加预加载字段
        public static var addPreloadColToRawTableEnable: Bool {
            fg("ccm.docs.add_preload_col_to_database_enable")
        }
        
        // MARK： -6.4
        /// 预加载任务接入同一管理框架
        public static var docsFeedPreloadCentralizedEnable: Bool {
            fg("ccm.docs.preload_centralized_enable")
        }
    }
    
    /// wuwenjian.weston
    public enum WWJ {
        // docx 版本创建副本功能是否启用
        public static var copyEditionEnable: Bool { fg("ccm.workspace.mobile.copy_edtion_enable") }
        // 文档库和云盘 & space2.0，space 1.0不开启文档库和云盘
        public static var cloudDriveEnabled: Bool {
            fg("ccm.workspace.personal_space_enabled") && fg("spacekit.mobile.single_container_enable")
        }

        public static var defaultCreateInLibraryEnabled: Bool {
            // 复用 web FG + 个人库 FG
            cloudDriveEnabled && fg("ccm.space.default_create_to_my_library_enabled")
        }

        public static var userDefaultLocationEnabled: Bool {
            cloudDriveEnabled && fg("ccm.mobile.space_use_personal_location")
        }

        // Space 文档、文件夹支持申请删除 & Space 文件夹支持申请移动
        public static var spaceApplyDeleteEnabled: Bool {
            fg("ccm.space.mobile.delete_apply_enable")
        }

        /// 权限 SDK 在 More 面板内是否启用
        /// 目前此 FG 未实际上线，仅用于从 debug 菜单 mock 进入
        public static var permissionSDKEnabledInMore: Bool {
            permissionSDKEnable
        }
        
        // space新首页FG
        public static var newSpaceTabEnable: Bool {
            //fg("ccm.workspace.next")
            fg("ccm.mobile.newspace")
        }

        // CM 创建按钮位置调整
        public static var createButtonOnNaviBarEnable: Bool {
            false
        }

        /// 影响 CCM 请求特定接口是否增加 TNS 参数，不影响 TNS 重定向逻辑
        public static var ccmTNSParamsEnable: Bool {
            fg("tns.crossborder.ccm")
        }

        /// 文档多权限实体场景是否区分鉴权（Base@Doc、SyncedBlock 前置依赖）
        public static var permissionReferenceDocumentEnable: Bool {
            fg("ccm.mobile.permission.reference_document_enable")
        }

        public static var permissionSDKEnableInCreation: Bool {
            permissionSDKEnable
        }

        public static var permissionSDKEnableInDrive: Bool {
            permissionSDKEnable
        }

        public static var permissionSDKEnable: Bool {
        #if DEBUG
            if AssertionConfigForTest.isBeingTest { return false }
            return fg("ccm.permission.permission_sdk_enable")
        #else
            fg("ccm.permission.permission_sdk_enable")
        #endif
        }

        public static var ccmSecurityMenuProtectEnable: Bool {
            fg("ccm.mobile.security_menu_protect")
        }

        public static var attachmentBlockMenuPermissionFixEnable: Bool {
            fg("ccm.permission.block_menu_permission_fix")
        }

        public static var translateLangRecognitionEnable: Bool {
            fg("ccm.mob.docx.translate_lang_recognition")
        }

        public static var auditPermissionControlEnable: Bool {
            fg("com.permission.audit_control_enable")
        }

        public static var ccmSettingVisable: Bool {
            fg("ccm.mobile.doc_settings_enable")
        }

        public static var imShareLeaderEnable: Bool {
            fg("ccm.permission.share_recommend.leader_auth")
        }
    }

    /// chensi.123
    public enum CS {
        /// 是否开启文档通知降噪功能
        public static var feedMuteEnabled: Bool { fg("ccm.message.mute") }
        // 前端调用native的消息分发方式性能优化
        public static var jsbDispatchOptimizationEnabled: Bool { fg("ccm.mobile.jsb_dispatch_opt_enable") }
        /// 基于CPU的MagicShare功耗优化: 例如有功耗问题时告知前端要降级
        public static var powerOptimizeDowngradeEnabled: Bool { fg("lark.core.cpu.manager.power.optimize") }
        /// 避免ioswebview进入睡眠状态,修复ios高CPU占用问题
        public static var msFloatWindowAudioEnabled: Bool { fg("ccm.common.keep_webview_alive") }
        /// 前端和RN的日志批量聚合
        public static var jsBatchLogEnabled: Bool { fg("ccm.common.batch_log") }
        // MARK: - 6.7
        /// 评论删除权限逻辑优化
        public static var commentDeletePermissionOpt: Bool { fg("ccm.comment.delete_permission") }
        /// 评论解决权限逻辑优化
        public static var commentReslovePermissionOpt: Bool { fg("ccm.comment.reslove_permission") }
        /// 评论解决权限逻辑优化V2
        public static var commentReslovePermissionOptV2: Bool { fg("ccm.comment.reslove_permission_v2") }
        // MARK: - 6.8
        /// 评论图片使用`文档附件`权限(预览、下载)
        public static var commentImageUseDocAttachmentPermission: Bool { fg("ccm.permission.attachment_seperate_auth_enable") }
        // MARK: - 7.1
        /// 提及人策略优化
        public static var mentionUserRecommendationOpt: Bool { fg("ccm.mention.user_recommendation_optimize") }
        /// 修复renderurl中调用deletequery引起的订阅文档后查看变更详情打开空白LB问题：https://bytedance.feishu.cn/docx/JwkAd6hxNoGGnVxP58Ec1FTqnWg
        public static var renderUrlDeleteQueryFix: Bool { fg("ccm.common.renderurl_deletequery_fix") }
        // MARK: - 7.7
        /// MS场景WebView复用优化
        public static var msWebviewReuseEnable: Bool { fg("ccm.docs.ms_webview_reuse_enable_ios") }
        // MARK: - 7.9
        /// 2023新增的MS降级策略
        public static var msDowngradeNewStrategyEnable: Bool { fg("ccm.mobile.magic_share_downgrade_enabled") }
    }
    
    /// huayufan
    public struct HYF {
        /// 评论锚点链接拷贝功能
        public static var commentAnchorLinkEnable: Bool { fg("ccm.gpe.comment.anchor_link_mobile") }
        
        public static var docFontZoomable: Bool { fg("ccm.doc.fontsize") }
        
        public static var commentTranslateConfig: Bool { fg("ccm.mobile.comment_translate_config") }
        
        public static var commentWikiIcon: Bool { fg("ccm.mobile.comment_wiki_link_icon_enable") }
        
        public static var gurdFixEnable: Bool { fg("ccm.ka.gurd_fix_enable") }
        
        public static var offlineTokensSyncEnable: Bool { fg("ccm.mobile.offline_tokens_queue_sync_enable") }
        
        public static var disableSendWhenParsingUrl: Bool { fg("ccm.comment.disable_send_when_parsing_url") }
        
        public static var scrollFeedToFirstUnread: Bool {  fg("ccm.mobile.feed_auto_scroll_to_first_unread_message") }
        
        public static var exportSupportCommentEnable: Bool { fg("ccm.docx.mob.export_support_comment") }
        
        public static var pdfInlineAIMenuEnable: Bool {
            fg("ccm.mobile.pdf_inline_ai_menu_enable")
        }
        
        public static var asideCommentHeightOptimize: Bool {
            fg("ccm.mobile.aside_comment_height_optimize")
        }

    }
    

    /// peilongfei
    public enum PLF {
        /// 邮箱分享文档授权
        public static var authEmailEnable: Bool { fg("ccm.permission.auth_email_enable") }
        /// 文档支持邮箱分享
        public static var mailSharingEnable: Bool { fg("ccm.permision.mail_sharing") }
        /// 转移owner时自动移动
        public static var transferAutoMoveEnabled: Bool { fg("ccm.permission.web.transfer_auto_move") }
        /// 上级自动授权
        public static var leaderAutoAuthEnabled: Bool { fg("ccm.permission.leader_auto_auth") }
        /// 文档支持可搜点位
        public static var searchEntityEnable: Bool { rtfg("ccm.permission.search_entity_enable") }
        /// 上级自动授权提示弹框
        public static var leaderPermTipsDialogEnabled: Bool { fg("ccm.permission.leader_perm_tips_dialog") }
        /// lynx链接分享
        public static var lynxLinkShareEnable: Bool { fg("ccm.permission.lynx_link_share") }
        /// 对外分享设置路径优化
        public static var shareExternalSettingEnable: Bool { fg("ccm.permission.share_external_setting_optimize") }
        /// 密级限制复制点位拆分
        public static var securityLevelSplitCopyEnable: Bool { fg("ccm.permission.security_level.split_copy") }
        /// 上级穿透
        public static var managerDefaultviewSubordinateEnable: Bool { fg("ccm.permission.manager_defaultview_subordinate1") }
        /// 关闭访问者头像
        public static var avatarSwitchEnable: Bool { fg("ccm.all.web.co_avatar_switch") }
        /// 新版举报申诉
        public static var appealV2Enable: Bool { fg("ccm.platform.appeal_v2") }
        /// 离线截屏
        public static var offlineScreenshotEnable: Bool { fg("ccm.permission.offline_perm_screenshot") }
        /// 荣耀租户屏蔽对外分享渠道
        public static var shareChannelDisable: Bool { fg("ccm.mobile.permission.share_channel") }
        /// wiki支持对外分享渠道
        public static var wikiShareChannelEnable: Bool { fg("ccm.permission.wiki_share_channel") }
        /// 自定义分享密码
        public static var customPasswordEnable: Bool { fg("ccm.permission.custompasswordfordocs") }
    }

    /// huangzhikai
    public enum HZK {
        
        // MARK: - 4.6
        /// 是否使用灰度包
        public static var useGrayscalePackage: Bool { fg("spacekit.res.use_grayscale_package") }
        
        // MARK: - 5.18
        public static var disableGeckoDownloadFullPkg: Bool { fg("ccm.resupdate.disable_gecko_download") }
        
        /// CCM接入统一存储
        public static var ccmUseUnifiedStorage: Bool { fg("ccm.common.use_unified_storage") }
        /// b2b 标签
        public static var b2bRelationTagEnabled: Bool { fg("lark.suite_admin.orm.b2b.relation_tag_for_office_apps") }
        /// mg域名优化
        public static var mgDomainOptimize: Bool { fg("ccm.common.mg_domain_optimize") }
        /// 网络优化，用于打印日志，监控网络请求线程卡死开关
        public static var enableNetworkOptimize: Bool { fg("ccm.common.enable_network_optimize") }
        /// 网络库优化，开启直接调用rust请求
        public static var enableNetworkDirectConnectRust: Bool {
            if AssertionConfigForTest.isBeingTest {
                return false
            }
            return fg("ccm.common.enable_network_direct_connect_rust")
        }
        // MARK: - 6.8
        /// 预加载不允许下载js相关资源
        public static var forbidDownloadDuringPreloading: Bool { fg("ccm.docs.forbid_download_during_preloading") }

        // MARK: - 6.7
        /// 完整包解压优化，因为第一次安装就需要当成打开使用， 这里取反操作：false 打开， true为关闭
        public static var fullPkgUnzipOptimize: Bool { fg("ccm.docs.full_pkg_unzip_optimize") }
        // MARK: - 7.2
        /// 自定义图标
        public static var customIconPart: Bool { fg("ccm.icon.custom_icon_part") }
        /// 自定义图标
        public static var sheetCustomIconPart: Bool { fg("ccm.icon.sheet_custom_icon_part") }
        
        // MARK: - 7.3
        /// 网络优化重试内存优化，默认为false，全量打开，有问题再开true
        public static var disableNetworkRetryOptimize: Bool { fg("ccm.common.disable_network_retry_optimize") }

        /// 是否打开文档提前拉取SSR
        public static var docsFetchSSRBeforeRender: Bool { fg("ccm.docx.fetch_ssr_before_render") }
        
        /// render的时候判断CSRwebview是否有渲染ssr，有则不从文件里面读clinetVar,，只读缓存
        public static var docsRenderGetClintVarOnlyCache: Bool { fg("ccm.docx.render_get_clintvar_onlycache") }
        
        ///主导航文档是否强制刷新
        public static var mainTabbarDisableForceRefresh: Bool { fg("ccm.docx.main_tabbar_disable_force_refresh") }
        
        // MARK: - 7.4
        /// ipad是否支持显示ssr
        public static var enableIpadSSR: Bool { fg("ccm.docx.enable_ipad_ssr") }

        /// 小程序/网页打开文档，增加来源参数
        public static var openDocAddFromParamDisable: Bool { fg("openplatform.api.open_docs.add_from_param.disable") }
        
        /// 域名替换需求，针对字节租户存量文档，在路由层做域名替换
        public static var correctDomainEnable: Bool { fg("ccm.mobile.correct_domain_enable") }

        // MARK: - 7.6
        /// 优化webview超时且卡死，reload的时候重复注册jsb的问题
        public static var fixRepeatRegisterJsb: Bool { fg("ccm.docx.fix_repeat_register_jsb") }
        
        // MARK: - 7.8
        /// 网络请求都带上crsf-token
        public static var enableCsrfVerification: Bool { fg("ccm.drive.enable_csrf_verification") }

        // MARK: - 7.7
        /// 网络库兜底域名cookie正则修改 取反fg，默认关闭
        public static var disableModifyDomainRegular: Bool { fg("ccm.common.disable_modify_domain_regular") }
        
        // MARK: - 7.9
        /// 网络库兜底域名cookie正则修改 取反fg，默认关闭
        public static var larkIconDisable: Bool { fg("ccm.icon.lark_icon_disable") }
    }
    
    /// tanyunpeng
    public enum TYP {
        ///审核、封禁能力是否开启
        public static var appealingForbidden: Bool { fg("ccm.drive.mobile.forbidden") }

        ///lark举报入口是否开启
        public static var larkTnsReport: Bool { fg("lark.tns.doc_report") }
        
        ///静态用户组
        public static var permissionUserGroup: Bool { fg("ccm.permission.web.user_group") }
        
        ///Drive webp 接入ByteWebImage 是否开启
        public static var DriveWebpEable: Bool {
            fg("ccm.drive.mobile.webp")
        }
        
        ///Drive webp 接入IM图片组件 是否开启
        public static var DriveIMImageEable: Bool {
            fg("ccm.drive.mobile.image.preview")
        }
        
        /// 密级详情页
        public static var permissionSecretDetail: Bool { fg("ccm.mobile.permission.secret_detail") }
        
        /// 自动/推荐打标
        public static var permissionSecretAuto: Bool { fg("ccm.mobile.permission.secret_auto") }
        
        /// 一键已读
        public static var messageAllRead: Bool { fg("ccm.message.allread") }
        
        /// vc下支持翻译
        public static var translateMS: Bool { fg("ccm.doc.translate_ms") }
        
        /// 翻译按钮位置
        public static var translateBottom: Bool { fg("ccm.mob.doc.translate_bottom") }
        
        /// 用于从标签页切换回云文档Tab时，需要把云文档列表展示出来
        public static var openBlankScreen: Bool { fg("ccm.docx.open_blank_screen") }
    }
    
    /// zenghao
    public enum ZH {
        /// 记录PDF文件阅读位置，7.2版本
        public static var recoveryPDFReadingProgress: Bool { fg("ccm.drive.pdf_location_persist") }
        /// PDF 接入MyAI分会话, 7.3版本
        public static var enablePDFMyAIEntrance: Bool { fg("ccm.drive.enable_pdf_ai") }
        
        /// 知识空间接入MyAI分会话，7.4版本
        public static var enableWikiSpaceMyAIEntrance: Bool { fg("ccm.wiki.myai_wiki_space_qa") }

        /// 禁用PDF 沉浸态，7.6版本
        public static var disablePDFImmerise: Bool { fg("ccm.mobile.drive.disable_pdf_immersive") }
        
        /// DriveSDK 支持外部缓存，7.9版本
        public static var driveSDKExternalCachePreviewEnable: Bool { fg("ccm.mobile.drive.add_preview_cache_enable") }


        /// 接入飞书卖点组件，7.7版本
        public static var enableCTAComponent: Bool { fg("ccm.mobile.cta_component_enable") }
    }
    
    /// zhangyuanping
    public enum ZYP {
        // 6.2.0 WPS渲染失败/模版加载失败优化
        public static var wpsOptimizeEnable: Bool { fg("ccm.drive.wps_optimization") }
        /// 通过静音播放再暂停的方式获取视频封面，避免 TTVideo 视频占用高问题
        public static var ttVideoPlayForCoverEnable: Bool { fg("ccm.drive.ttvideo_play_for_cover") }
        /// 6.7.0 IM的Excel文件支持编辑
        public static var imWPSEditEnable: Bool { fg("ccm.drive.im_wps_edit_enable") }
        /// 6.8.0 下载视频FileBlock封面
        public static var downloadVideoCover: Bool { fg("ccm.drive.download_video_cover") }
        /// 6.9.0 文档支持新鲜度
        public static var docFreshnessEnable: Bool { fg("ccm.mobile.more.fresh_content") }
        /// 最近列表过滤不再区分Wiki
        public static var recentListNewFilterEnable: Bool { fg("ccm.workspace.filter_include_wiki") }
        /// 6.11 WPS URL 联通性检测降级功能
        public static var wpsUrlCheckEnable: Bool { fg("ccm.drive.wps_url_check") }
        /// 7.1 转码中小视频下载预览
        public static var transcodingVideoDownloadEnable: Bool { fg("ccm.drive.mobile.video_little_rate") }
        /// 7.1.0 移动到入口：详情页（space）、置顶（新首页）、快速访问、收藏、最近列表
        public static var spaceMoveToEnable: Bool { fg("ccm.space.recent_move_enable") }
        /// 7.2.0 转码中特定码率和编码格式的视频支持原视频在线播放
        public static var transcodingVideoPlayOriginEnable: Bool { fg("ccm.drive.mobile.play_origin_video") }
    }

    /// liuyanlong.beijing
    public enum LYL {
        /// itemView 封面开关
        public static var enableAttachmentCover: Bool {
            fg("ccm.bitable.card.enable.cover")
        }
        
        public static var disableCoverRetryFix: Bool {
            fg("ccm.bitable.disable.cover.retry.fix")
        }

        public static var enableStatisticTrace: Bool {
            fg("ccm.bitable.mobile.statistic_trace")
        }

        public static var enableBaseFPSDrop: Bool {
            (enableStatisticTrace && fg("ccm.bitable.mobile.enable_fps_drop"))
        }
        
        public static var disableFixBaseDragTableSplash: Bool {
            fg("ccm.bitable.base.fix.drag.table.splash")
        }

        public static var disablePanelCheckBeingDismissed: Bool {
            fg("ccm.bitable.base.disable.panel.check.being_dismiss")
        }

        public static var enableHomePageV4: Bool {
            fg("bitable.homepage.v4.enable")
        }

        public static var disableAllViewAnimation: Bool {
            fg("ccm.bitable.base.disable.all_view_animation")
        }

        /*
         1.全屏不需要 fixedHidden 强制隐藏 header。全屏如果强制 hidden header, 非全屏要改回之前的 hidden 状态, 这块逻辑会很复杂
         2. 目前来看全屏不需要强制隐藏 header, 这里用个开关进行兜底
         */
        public static var disableFixHeaderModeCheckFullScreen: Bool {
            fg("ccm.bitable.base.disable.fix_header_check_full_screen")
        }

        public static var disableFixBitableWKScrollViewBounces: Bool {
            fg("ccm.bitable.base.disable.fix_wkscrollview_bounces")
        }

        public static var disableFixInRecordFileRecord: Bool {
            fg("ccm.bitable.base.disable.fix_inrecord_file_record")
        }

        public static var disableFixViewContainerConstraints: Bool {
            fg("ccm.bitable.base.disable.fix_viewcontainer_constraints")
        }

        public static var disablePopHomeWhenDarkModeChanged: Bool {
            fg("ccm.bitable.base.disable.pop_home_when_dark_mode_changed")
        }
    }

    public enum WPB {
        /// 关闭SlideableCell 中actions 通知
        public static var homepageScrollHorizontalEnable: Bool { fg("bitable.homepage.new.slide.horizontal.enable") }
        public static var homepageRecommendNativeEnable: Bool { fg("bitable.homepage.new.native.enable") }
    }

    /// chenwenjun.cn
    public final class CWJ {
        public static var wikiTreeOfflineEnable: Bool {
            fg("ccm.workspace.wiki_tree_offline_enable")
        }

        public static var enableLarkPlayerKit: Bool {
            fg("ccm.drive.mobile.enable_lark_player_kit")
        }

        public static var dropOriginVideoPreviewLimitation: Bool {
            fg("ccm.drive.mobile.drop_origin_video_preview_limitation")
        }

        public static var enableUserDownloadVideoDuringTranscoding: Bool {
            fg("ccm.drive.mobile.enable_user_download_video_during_transcoding")
        }
    }

#if DEBUG
    // mock fg使用，仅在单元测试场景进行 mock，非单元测试请直接使用主端基建的mock界面
    static var mockValues = [String: Bool]()
#endif
}
#if DEBUG
//这里的方法请不要改public，引入SKFoundation的时候请使用 @testable import SKFoundation
extension UserScopeNoChangeFG {
    // 设置mock的fg
    class func setMockFG(key: String, value: Bool) {
        mockValues[key] = value
    }
    // 移除mock的fg
    class func removeMockFG(key: String) {
        mockValues.removeValue(forKey: key)
    }
    // 移除所有mock的fg
    class func clearAllMockFG() {
        mockValues.removeAll()
    }
    fileprivate class func mockFG(key: String) -> Bool? {
        mockValues[key]
    }
}
#endif
// MARK: - 工具方法
private func fg(_ key: LarkSetting.FeatureGatingManager.Key) -> Bool {
#if DEBUG
    if let mockValue = UserScopeNoChangeFG.mockFG(key: key.rawValue) {
        DocsLogger.info("UserScopeNoChangeFG use mock value, key:\(key) value:\(mockValue)")
        return mockValue
    }
#endif
    return FeatureGatingManager.shared.featureGatingValue(with: key)
}

// 获取实时FG(RealTimeFeatureGating)
private func rtfg(_ key: LarkSetting.FeatureGatingManager.Key) -> Bool {
#if DEBUG
    if let mockValue = UserScopeNoChangeFG.mockFG(key: key.rawValue) {
        DocsLogger.info("UserScopeNoChangeFG use mock value, key:\(key) value:\(mockValue)")
        return mockValue
    }
#endif
    return FeatureGatingManager.realTimeManager.featureGatingValue(with: key)
}
