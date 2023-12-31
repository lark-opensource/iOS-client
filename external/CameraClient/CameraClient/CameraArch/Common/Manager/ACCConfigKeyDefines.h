//
// ACCConfigKeyDefines.h
// CameraClient
//
// Created by yangying on 2021/3/10.
//

#ifndef ACCConfigKeyDefines_h
#define ACCConfigKeyDefines_h

#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreationKitComponents/ACCBeautyConfigKeyDefines.h>
#import <CreationKitComponents/ACCFilterConfigKeyDefines.h>

/// 基于快拍实验的AB
NS_INLINE BOOL ACCBaseOnStoryConfigBool(NSArray *pair) {
    return ACCConfigBool(pair) && ACCConfigBool(kConfigBool_enable_story_tab_in_recorder);
}

#pragma mark - Float Keys

// 支持脏镜头检测-脏镜头阈值
#define kConfigDouble_dirty_camera_detection_toast_threshold \
ACCConfigKeyDefaultPair(@"dirty_camera_detection_toast_threshold", @(0.8))

#define kConfigDouble_http_retry_interval \
ACCConfigKeyDefaultPair(@"http_retry_interval", @(-1.f))

#define kConfigDouble_story_picture_duration \
ACCConfigKeyDefaultPair(@"story_image_play_time", @(5.0))

// 拍摄抽帧间隔
#define kConfigDouble_studio_record_media_frame_interval \
ACCConfigKeyDefaultPair(@"studio_record_media_frame_interval", @(2.0))

// 上传视频抽帧间隔
#define kConfigDouble_studio_upload_media_frame_interval \
ACCConfigKeyDefaultPair(@"studio_upload_media_frame_interval", @(0.5))

// 帧存储压缩比
#define kConfigDouble_studio_media_frame_compression_ratio \
ACCConfigKeyDefaultPair(@"studio_media_frame_compression_ratio", @(0.6))

// 合拍原视频时长
#define kConfigDouble_studio_duet_default_video_duration \
ACCConfigKeyDefaultPair(@"duet_default_video_duration", @(1.0))

// 合拍导入视频的默认音量为0，前置依赖enable_duet_import_asset
#define kConfigDouble_duet_import_asset_volume \
ACCConfigKeyDefaultPair(@"duet_import_asset_volume", @(0.0))

#pragma mark - Array Keys

#define kConfigArray_ai_recommend_music_list_default_url_lists \
ACCConfigKeyDefaultPair(@"aweme_music_ailab.song_url_list", @[])

#define kConfigArray_activity_sticker_ids \
ACCConfigKeyDefaultPair(@"aweme_activity_setting.activity_sticker_id_array", @[])

#define kConfigArray_text_record_mode_backgrounds \
ACCConfigKeyDefaultPair(@"text_record_mode_backgrounds", @[])

#define kConfigArray_audio_record_mode_backgrounds \
ACCConfigKeyDefaultPair(@"voice_publish_mode_backgrounds", @[])

#define kConfigArray_activity_mv_ids \
ACCConfigKeyDefaultPair(@"aweme_activity_setting.mv_ids", @[])

#define kConfigArray_smart_mv_loading_assets \
ACCConfigKeyDefaultPair(@"smart_mv_loading_assets", @[])

#define kConfigArray_video_record_size \
ACCConfigKeyDefaultPair(@"video_size_category", @[])

#define kConfigArray_video_record_bitrate \
ACCConfigKeyDefaultPair(@"video_bitrate_category", @[])

#define kConfigArray_upload_video_size \
ACCConfigKeyDefaultPair(@"upload_video_size_category", @[])

#define kConfigArray_upload_video_bitrate \
ACCConfigKeyDefaultPair(@"upload_video_bitrate_category", @[])

#define kConfigArray_super_entrance_effect_ids \
ACCConfigKeyDefaultPair(@"acc_super_entrance_effect_ids", @[])

#define kConfigArray_cache_clean_exclusion_list \
ACCConfigKeyDefaultPair(@"aweme_base_conf.tmp_cache_whitelist", @[@"com.apple.dyld"])

#define kConfigArray_publish_private_popup_window_activity_types \
ACCConfigKeyDefaultPair(@"publish_page_private_bubble_activity_video_types", @[])

#define kConfigArray_edit_toolbar_exhibit_list \
ACCConfigKeyDefaultPair(@"edit_toolbar_exhibit_list", @[])

// 剪同款 gameplay settings
#define kConfigArray_studio_cutsame_gameplay_config \
ACCConfigKeyDefaultPair(@"cutsame_gameplay_config.styles", @[])

#pragma mark - Dictionary Keys

typedef NSString *ACCPrefetchNetwork NS_TYPED_ENUM;
static const ACCPrefetchNetwork ACCPrefetchNetworkAll = @"all";
static const ACCPrefetchNetwork ACCPrefetchNetworkWifiOnly = @"wifi_only";

// 预取道具/贴纸/特效
#define kConfigDict_prefetch_effects \
ACCConfigKeyDefaultPair(@"tc_pre_fetch_effects", @{})

// settings
#define kConfigDict_text_read_sticker_configs \
ACCConfigKeyDefaultPair(@"creative_read_text_sticker_config", @{})

// settings
#define kConfigDict_poi_default_style_info \
ACCConfigKeyDefaultPair(@"poi_def_style_info", @{})

// settings
#define kConfigDict_karaoke_basic_configs \
ACCConfigKeyDefaultPair(@"karaoke_basic_configs", @{})

#define kConfigDict_karaoke_delay_config \
ACCConfigKeyDefaultPair(@"tools_ktv_record_delay", @{})

// settings
#define kConfigDict_drafts_feedback_config \
ACCConfigKeyDefaultPair(@"drafts_feedback", @{})

// settings
#define kConfigDict_modern_sticker_panel_config \
ACCConfigKeyDefaultPair(@"modern_sticker_panel_config", @{})

#define kConfigDict_studio_optim_sidebar_list \
ACCConfigKeyDefaultPair(@"studio_optim_sidebar_list", @{})

#define kConfigDict_tools_edit_activity_notice_toast \
ACCConfigKeyDefaultPair(@"tools_edit_activity_notice_toast", @{})

// 手机屏幕亮度调整实验
#define kConfigDict_studio_screen_brightness_adjust \
ACCConfigKeyDefaultPair(@"studio_screen_brightness_adjust_new", @{})

// 新能力灰度道具
#define kConfigDict_studio_new_ability_gray_prop \
ACCConfigKeyDefaultPair(@"avtools_record_sticker_gray", @{})

// 拍摄器本地花草自动识别配置
#define kConfigDict_tools_smart_recognition_autoscan_config \
ACCConfigKeyDefaultPair(@"tools_smart_recognition_autoscan_config", @{})

#pragma mark - BOOL Keys

// 道具拍同款状态下是否开启低端机拍摄帧率降级
#define kConfigBOOL_enable_reduce_prop_frame_rate \
ACCConfigKeyDefaultPair(@"enable_reduce_prop_frame_rate", @(NO))

//预加载道具/贴纸/特效
#define kConfigBOOL_enable_prefetch_effects \
ACCConfigKeyDefaultPair(@"enable_prefetch_effects", @(NO))

// Use BYTEVC1 encode in recorder
#define kConfigBool_use_bytevc1_encode_in_recorder \
ACCConfigKeyDefaultPair(@"studio_recorder_vesdk_use_bytevc1_encode_in_recorder", @(NO))

// Use BYTEVC1 encode in editor
#define kConfigBool_use_bytevc1_encode_in_editor \
ACCConfigKeyDefaultPair(@"studio_editor_vesdk_use_bytevc1_encode_in_editor", @(NO))

// Enable unified beauty config with livestream
#define kConfigBool_studio_enable_unified_beauty \
ACCConfigKeyDefaultPair(@"studio_enable_unified_beauty", @(NO))

#define kConfigBool_use_one_key_lens_hdr_denoise \
ACCConfigKeyDefaultPair(@"hdrv2_use_denoise", @(NO))

#define kConfigBool_use_one_key_lens_hdr_no_denoise \
ACCConfigKeyDefaultPair(@"hdrv2_no_denoise", @(NO))

#define kConfigBool_use_optimized_hdr_detection \
ACCConfigKeyDefaultPair(@"hdrv2_opti", @(NO))

#define kConfigInt_lens_oneKey_max_cache_size \
ACCConfigKeyDefaultPair(@"lens_oneKey_maxCacheSize", @(4))

#define kConfigInt_asf_mode \
ACCConfigKeyDefaultPair(@"asf_mode", @(0))

#define kConfigInt_hdr_mode \
ACCConfigKeyDefaultPair(@"hdr_mode", @(0))

// 时光故事支持模板选择
#define kConfigBool_moments_support_choose_template \
ACCConfigKeyDefaultPair(@"moments_support_choose_template", @(NO))

// 自定义贴纸/enable upload stickers
#define kConfigBool_info_sticker_support_uploading_pictures \
ACCConfigKeyDefaultPair(@"info_sticker_support_uploading_pictures", @(NO))

// mention和hashtag贴纸
#define kConfigBool_sticker_support_mention_hashtag \
ACCConfigKeyDefaultPair(@"studio_sticker_support_mention_hashtag", @(NO))

// mention和hashtag贴纸样式统一
#define kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform \
ACCConfigKeyDefaultPair(@"edit_poi_mention_hashtag_enable_UI_uniform", @(NO))

// groot贴纸
#define kConfigBool_sticker_support_groot \
ACCConfigKeyDefaultPair(@"enable_groot", @(NO))
 
// 单图和图集推荐允许优化抽帧
#define kConfigBool_enable_improve_frame_count \
ACCConfigKeyDefaultPair(@"enable_improve_frame_count", @(YES))

// 音乐面板根据打开抽帧状态选择数据源
#define kConfigBool_music_panel_request_with_current_state \
ACCConfigKeyDefaultPair(@"music_panel_request_with_current_state", @(NO))

// 开启文字贴纸朗读/enable text reading
#define kConfigBool_enable_edit_text_reading \
ACCConfigKeyDefaultPair(@"creative_use_edit_text_reading", @(NO))

// Enable remove temp directory
#define kConfigBool_enable_remove_temp_directory \
ACCConfigKeyDefaultPair(@"studio_enable_remove_temp_directory", @(YES))

// Enable remove temp's mlmodel directory
#define kConfigBool_enable_remove_temps_directory \
ACCConfigKeyDefaultPair(@"studio_enable_remove_temps_directory", @(YES))

// 客户端支持1080P高清视频上传
#define kConfigBool_enable_1080p_publishing \
ACCConfigKeyDefaultPair(@"studio_enable_1080p_publishing", @(NO))

// 拍摄页预加载道具列表
#define kConfigBool_enable_prefetch_effect_list \
ACCConfigKeyDefaultPair(@"pre_fetch_effect_list_in_studio_record", @(NO))

// VE process unit跨平台
#define kConfigBool_use_ve_cross_platform_process_unit \
ACCConfigKeyDefaultPair(@"studio_ve_cross_platform_process_unit", @(YES))

// 使用WCDB管理草稿数据库时，删除不可恢复的数据库
#define kConfigBool_draft_wcdb_remove_unrecoverable_db \
ACCConfigKeyDefaultPair(@"studio_draft_wcdb_remove_unrecoverable_db", @(NO))

// 是否关闭camera effect
#define kConfigBool_disable_camera_effect \
ACCConfigKeyDefaultPair(@"studio_camera_effect_disable", @(NO))

// 是否开启recorder component耗时统计
#define kConfigBool_enable_recorder_component_time_trace \
ACCConfigKeyDefaultPair(@"studio_recorder_component_time_trace_enable", @(NO))

// 是否开启editor component耗时统计
#define kConfigBool_enable_editor_component_time_trace \
ACCConfigKeyDefaultPair(@"studio_editor_component_time_trace_enable", @(NO))

// 道具外露面板
#define kConfigBool_enable_expose_prop_panel \
ACCConfigKeyDefaultPair(@"acc_studio_expose_prop_style_v2", @(NO))

// 聚焦打开道具外露面板
#define kConfigBool_enable_focus_to_open_expose_prop_panel \
ACCConfigKeyDefaultPair(@"studio_expose_prop_style_v2_enable_focus_open", @(NO))

// 外露面板过滤商业化道具
#define kConfigBool_enable_expose_prop_panel_filter_commerce \
ACCConfigKeyDefaultPair(@"studio_expose_prop_style_v2_filter_commerce", @(NO))

// AI配乐上传3帧
#define kConfigBool_upload_three_frames \
ACCConfigKeyDefaultPair(@"editpage_use_three", @(NO))

// enable editor beauty
#define kConfigBool_enable_editor_beauty \
ACCConfigKeyDefaultPair(@"studio_enable_editor_beauty", @(NO))

// 启用视频信息日志输出
#define kConfigBool_enable_video_info_output_online \
ACCConfigKeyDefaultPair(@"enable_video_info_output_online", @(NO))

// 相册到编辑页跳过剪裁
#define kConfigBool_skip_clip_from_album_to_edit \
ACCConfigKeyDefaultPair(@"acc_skip_clip_from_album_to_edit", @(NO))

// 开启智能剪辑数据回流需求
#define kConfigBool_enable_smart_stick_point_feedback \
ACCConfigKeyDefaultPair(@"enable_smart_stick_point_feedback", @(NO))

// 编辑页滑动切换滤镜
#define kConfigBool_tools_edit_filter_switch_enable \
ACCConfigKeyDefaultPair(@"tools_edit_filter_switch_enable", @(YES))

// 编辑页上滑弹出贴纸面板
#define kConfigBool_tools_edit_sticker_panel_swipe_up \
ACCConfigKeyDefaultPair(@"tools_edit_sticker_panel_swipe_up", @(NO))

// 拍摄页录制中双击切换镜头
#define kConfigBool_tools_shoot_switch_camera_while_recording \
ACCConfigKeyDefaultPair(@"tools_shoot_switch_camera_while_recording", @(NO))

// 双击切换手势屏蔽AR和Game道具
#define kConfigBool_tools_shoot_double_tap_except_game_ar_sticker \
ACCConfigKeyDefaultPair(@"tools_shoot_double_tap_except_game_ar_sticker", @(NO))

// 存草稿landing到草稿tab
#define kConfigBool_enable_draft_save_landing_tab \
ACCConfigKeyDefaultPair(@"enable_draft_save_landing_tab", @(NO))

// 个人页展示草稿tab
typedef NS_ENUM(NSUInteger, ACCUserHomeProfile) {
    ACCUserHomeProfileDefaultStyle = 0,
    ACCUserHomeProfileTabStyle = 1,
    ACCUserHomeProfileCollectionStyle = 2,
    ACCUserHomeProfileSubTabStyle = 3,
};

#define kConfigInt_enable_draft_tab_experiment \
ACCConfigKeyDefaultPair(@"enable_draft_tab_experiment", @(ACCUserHomeProfileDefaultStyle))

// 相机高级设置 @彭世晨
#define kConfigBool_tools_shoot_advanced_setting_panel \
ACCConfigKeyDefaultPair(@"is_support_record_page_settings", @(NO))

// 相机高级设置-最大拍摄时长
#define kConfigBool_tools_maximum_shooting_time \
ACCConfigKeyDefaultPair(@"maximum_shooting_time", @(YES))

// 相机高级设置-音量键拍摄
#define kConfigBool_tools_use_volume_keys_to_shoot \
ACCConfigKeyDefaultPair(@"use_volume_keys_to_shoot", @(YES))

// 相机高级设置-轻触快门拍照
#define kConfigBool_tools_tap_to_take \
ACCConfigKeyDefaultPair(@"tap_to_take", @(YES))

// 相机高级设置-多镜头变焦
#define kConfigBool_tools_multi_lens_zoom \
ACCConfigKeyDefaultPair(@"multi_lens_zoom", @(YES))

// 相机高级设置-网格
#define kConfigBool_tools_camera_grid \
ACCConfigKeyDefaultPair(@"camera_grid", @(YES))

// 相机高级设置 服务端下发配置
#define kConfigArray_camera_settings_options \
ACCConfigKeyDefaultPair(@"camera_settings_options", @[])

// 启用投稿二次验证
#define kConfigBool_enable_publish_second_verify \
ACCConfigKeyDefaultPair(@"tools_enable_publish_second_verify", @(NO))

// 智能搜索hashtag
#define kConfigBool_enable_publish_recommend_hashtag \
ACCConfigKeyDefaultPair(@"publish_recommend_hashtag", @(NO))

// 拍摄1-3min方案优化
#define kConfigBool_enable_record_3min_optimize \
ACCConfigKeyDefaultPair(@"studio_enable_shoot_3min_optimize_for_quick", @(NO))

// 开启草稿箱迁移功能
#define kConfigBool_enable_draft_migrate \
ACCConfigKeyDefaultPair(@"enable_draft_migrate_2", @(NO))

// 开启异步删除草稿功能
#define kConfigBool_enable_asyn_delete_draft_resource \
ACCConfigKeyDefaultPair(@"enable_asyn_delete_draft_resource", @(NO))

#define kConfigBool_creation_draft_box_sticker_record_another \
ACCConfigKeyDefaultPair(@"creation_draft_box_sticker_record_another", @(NO))

#define kConfigBool_creation_draft_box_recommend_resource \
ACCConfigKeyDefaultPair(@"creation_draft_box_recommend_resource", @(NO))

// 是否开启系统相册混排直接进入编辑页
#define kConfigBool_enable_system_album_mix_upload_optimization \
ACCConfigKeyDefaultPair(@"tools_enable_system_album_mix_upload_optimization", @(YES))

// 是否开启边合成边上传
#define kConfigBool_enable_merge_upload \
ACCConfigKeyDefaultPair(@"studio_publish_merge_upload", @(NO))

// 是否使用encode block
#define kConfigBool_use_encode_block \
ACCConfigKeyDefaultPair(@"studio_publish_use_encode_block", @(NO))

// TC会场默认landing到同城
#define kConfigBool_tc21_publish_landing_nearby \
ACCConfigKeyDefaultPair(@"tc21_publish_landing_nearby", @(NO))

// 录制采用1080P高清发布标准
#define kConfigBool_enable_use_hd_export_setting \
ACCConfigKeyDefaultPair(@"tool_enable_hd_record_resolution", @(YES))

// 拍摄页支持手动曝光补偿
#define kConfigBool_enable_exposure_compensation \
ACCConfigKeyDefaultPair(@"studio_record_enable_exposure_compensation", @(NO))

/// -------------------------------- 图集 & 图文 相关

// 图集MVP支持发布
#define kConfigBool_enable_images_album_publish \
ACCConfigKeyDefaultPair(@"images_mvp_enable_publish", @(NO))

// 图集MVP支持编辑转视频
#define kConfigBool_images_mvp_enable_edit_switch_to_video \
ACCConfigKeyDefaultPair(@"images_mvp_enable_edit_switch_to_video", @(NO))

// 图集MVP支持发布引导
#define kConfigBool_enable_images_album_publish_guide \
ACCConfigKeyDefaultPair(@"images_mvp_enable_publish_guide", @(NO))

// 图集默认生成照片电影
#define kConfigBool_image_mvp_defatult_landing_mv \
ACCConfigKeyDefaultPair(@"image_mvp_defatult_landing_mv", @(NO))

// 图集支持模式记忆
#define kConfigBool_image_mvp_support_mode_recall \
ACCConfigKeyDefaultPair(@"image_mvp_support_mode_recall", @(NO))

// 24-默认展示图集模式
#define kConfigBool_image_mvp_default_landing_image_by_age \
ACCConfigKeyDefaultPair(@"image_mvp_default_landing_image_by_age", @(NO))

// 图集分年龄下发默认模式
#define kConfigString_ies_aweme_user_age \
ACCConfigKeyDefaultPair(@"ies_aweme_user_age", @"2")

// 图集编辑页横滑引导
#define kConfigBool_image_mvp_enable_slide_left_guide \
ACCConfigKeyDefaultPair(@"image_mvp_enable_slide_left_guide", @(NO))

// 图集支持取消配乐
#define kConfigBool_image_mode_support_delete_music \
ACCConfigKeyDefaultPair(@"image_mode_support_delete_music", @(NO))

// 图集/社交图文体验优化（图片裁剪、图片位置调整、指示器、进大图音乐暂停）
#define kConfigDict_image_works_experience_optimization \
ACCConfigKeyDefaultPair(@"image_works_experience_optimization", @{})

static NSString * const kConfigInt_image_support_crop = @"image_support_crop";
static NSString * const kConfigBool_image_support_reposition = @"image_support_reposition";
static NSString * const kConfigInt_image_indicator_style = @"image_indicator_style";
static NSString * const kConfigBool_image_enter_browser_pause_music = @"image_enter_browser_pause_music";

// 图文图片支持多画幅裁切
#define kConfigBool_enable_image_multi_crop \
ACCConfigKeyDefaultPair(@"enable_image_multi_crop", @(NO))

// 图文图片多画幅裁切标题：调整、裁剪、裁切
#define kConfigString_image_multi_crop_title \
ACCConfigKeyDefaultPair(@"image_multi_crop_title", @"调整")

// 图文图片多画幅裁切气泡
#define kConfigBool_show_image_multi_crop_bubble \
ACCConfigKeyDefaultPair(@"show_image_multi_crop_bubble", @(NO))

// 支持图集的社交相关优化(图文)
#define kConfigBool_enable_image_album_story \
ACCConfigKeyDefaultPair(@"studio_enable_image_album_story", @(NO))

// 图文支持日常多发
#define kConfigBool_enable_image_album_story_batch_publish \
ACCConfigKeyDefaultPair(@"studio_enable_image_album_story_multi_publish", @(NO))

// 图文编辑页自动轮播时长 秒 浮点
#define kConfigDouble_image_album_story_auto_play_interval \
ACCConfigKeyDefaultPair(@"studio_image_album_story_auto_play_interval", @(2))

// 图文自动播用户拖拽后结束 默认YES，线上目前可能不配
#define kConfigBool_enable_image_album_story_stop_auto_play_after_drag \
ACCConfigKeyDefaultPair(@"studio_image_album_story_enable_stop_auto_play_after_drag", @(YES))

// 图文模式下最大的标题输入字符数
#define kConfigInt_tools_publish_max_words_for_image_album_story \
ACCConfigKeyDefaultPair(@"studio_image_album_story_publish_max_words", @(500))

// 技术开关，图文日常支持批量最后一个才landing
#define kConfigBool_enable_image_album_story_last_publish_task_landing \
ACCConfigKeyDefaultPair(@"studio_image_album_story_enable_last_publish_task_landing", @(YES))

// 图集VE缓存重构
#define kConfigBool_enable_image_album_ve_editor_cache_opt \
ACCConfigKeyDefaultPair(@"image_album_enable_ve_editor_cache_opt", @(NO))

// 图集预加载逻辑重构
#define kConfigBool_enable_image_album_preview_opt \
ACCConfigKeyDefaultPair(@"enable_image_album_preview_opt", @(YES))

// 图集VE线程优化
#define kConfigBool_enable_image_album_ve_image_thread_opt \
ACCConfigKeyDefaultPair(@"enable_image_album_ve_image_thread_opt", @(NO))

// 图集低端机优化，6S以下默认开启，其他机型可配
#define kConfigBool_image_album_current_device_is_low_level_opt_target \
ACCConfigKeyDefaultPair(@"image_album_current_device_is_low_level_opt_target", @(NO))

// 图集debug开关
#define kConfigBool_enable_image_album_debug_tool \
ACCConfigKeyDefaultPair(@"enable_image_album_debug_tool", @(NO))

// 消费侧下载单图图集不出面板，技术开关 默认YES
#define kConfigBool_enable_save_single_image_album_without_panel \
ACCConfigKeyDefaultPair(@"enable_save_single_image_album_without_panel", @(YES))

// 编辑页流转重构
#define kConfigBool_edit_flow_refactor \
ACCConfigKeyDefaultPair(@"studio_edit_flow_refactor", @(NO))

// 上传内容识别经纬度提升覆盖
#define kConfigBool_enable_upload_more_location_informations \
ACCConfigKeyDefaultPair(@"studio_enable_upload_more_location_informations", @(NO))

// 禁用贴纸的VE数值保护
#define kConfigBool_disable_sticker_ve_safeguard \
ACCConfigKeyDefaultPair(@"disable_sticker_ve_safeguard", @(NO))

// 允许录制链使用多段分辨率
#define kConfigBool_enable_record_multi_segment_video_size \
ACCConfigKeyDefaultPair(@"enableRecordMultiSegmentVideoSize", @(NO))

// 允许导入链使用多段分辨率
#define kConfigBool_enable_import_multi_segment_video_size \
ACCConfigKeyDefaultPair(@"enableImportMultiSegmentVideoSize", @(NO))

// 动态时长调整
#define kConfigBool_upload_video_slider_auto_adjust \
ACCConfigKeyDefaultPair(@"uploadVideoSliderAutoAdjust", @(NO))

// 开启影集mv
#define kConfigBool_mv_theme_mode_switch \
ACCConfigKeyDefaultPair(@"mvThemeModeSwitch", @(NO))

// effect开启流水线
#define kConfigBool_use_effect_pipeline_processor \
ACCConfigKeyDefaultPair(@"enableEffectParallelFwk", @(NO))

// 启动开启延后初始化
#define kConfigBool_enable_studio_launch_after_dispatch_optimize \
ACCConfigKeyDefaultPair(@"enableStudioLaunchAfterDispatchOptimize", @(NO))

// 高端机支持1080预览、采样
#define kConfigBool_enable_1080p_capture_preview \
ACCConfigKeyDefaultPair(@"enable1080pCapturePreview", @(NO))

// 自动清理effect磁盘
#define kConfigBool_enable_auto_clear_effect_cache \
ACCConfigKeyDefaultPair(@"enableAutoClearEffectCache", @(NO))

// [settings] 清理缓存 effectPlatform 白名单，默认不清理字体
#define kConfigArray_studio_effectplat_clean_allow_list \
ACCConfigKeyDefaultPair(@"studio_effectplat_clean_allow_list", @[@"textfont"])

// mutiple photos generate ai clip video
#define kConfigBool_enable_multi_photos_to_ai_video \
ACCConfigKeyDefaultPair(@"enableStickPointWhenSelectMultiPhotos", @(NO))

// 朋友页入口是否限制发布类型
#define kConfigBool_restrict_familiar_publish_style \
ACCConfigKeyDefaultPair(@"restrict_familiar_publish_style", @(YES))

// 开启手动管理磁盘
#define kConfigBool_enable_manage_disk \
ACCConfigKeyDefaultPair(@"acc_enableManageDisk", @(NO))

// 开启抖音Sug功能优化
#define kConfigBool_search_sug_completion \
ACCConfigKeyDefaultPair(@"acc_searchSugCompletion", @(NO))

// music select
#define kConfigBool_enable_music_selected_page_network_optims \
ACCConfigKeyDefaultPair(@"acc_enableMusicSelectedPageNetworkOptims", @(NO))

//创作页音乐搜索反转实验
#define kConfigBool_acc_music_select_reverse \
ACCConfigKeyDefaultPair(@"acc_music_select_reverse", @(NO))

#define kConfigBool_enable_music_selected_page_render_optims \
ACCConfigKeyDefaultPair(@"acc_enableMusicSelectedPageRenderOptims", @(NO))

// 相册开启单选/多选的动态切换能力
#define kConfigBool_enable_album_upload_switch_multi_select \
ACCConfigKeyDefaultPair(@"enable_album_upload_switch_multiselect", @(YES))

// 记忆相册多选按钮选择状态
#define kConfigBool_enable_save_album_upload_switch_multi_select_state \
ACCConfigKeyDefaultPair(@"enable_save_album_upload_switch_multi_select_state", @(YES))

// 相册页每行3列
#define kConfigBool_enable_album_upload_three_columns \
ACCConfigKeyDefaultPair(@"enable_album_upload_three_columns", @(NO))

// 相册预览页的下一步始终可点
#define kConfigBool_album_preview_next_always_clickable \
ACCConfigKeyDefaultPair(@"album_preview_next_always_clickable", @(NO))

//story的录制时长限制
#define kConfigBool_story_long_record_time \
ACCConfigKeyDefaultPair(@"acc_story_record_length", @(NO))

//快捷发布的作品是否是public的
#define kConfigBool_shortcut_publish_privacy_friends \
ACCConfigKeyDefaultPair(@"acc_shortcut_publish_permission", @(NO))

//功能文案优化
#define kConfigBool_enable_light_camera_permanent_copy \
ACCConfigKeyDefaultPair(@"acc_enable_light_camera_permanent_copy", @(NO))

// 是否记忆上次landing位置
#define kConfigBool_enable_remember_last_tab \
ACCConfigKeyDefaultPair(@"record_need_remember_landing", @(YES))

// 图片体验优化
#define kConfigBool_enable_lightning_pic_to_video_optimize \
ACCConfigKeyDefaultPair(@"enable_lightning_pic_to_video_optimize", @(NO))

// 按钮录制状态调整
#define kConfigBool_enable_lightning_style_record_button \
ACCConfigKeyDefaultPair(@"enable_lightning_style_record_button", @(NO))

//编辑页是否去除下一步按钮
#define kConfigBool_edit_page_button_style \
ACCConfigKeyDefaultPair(@"acc_edit_page_button_style", @(NO))

typedef NS_ENUM(NSUInteger, ACCAIRecommendType) {
    ACCAIRecommendTypeDefault = 0, // 对照组
    ACCAIRecommendTypeServerFirst = 1, // 预上传打开时优先使用服务端推荐
    ACCAIRecommendTypeBachFirst = 2, // 优先使用bach推荐
};
//编辑页使用bach推荐音乐/话题
#define kConfigBool_edit_page_use_bach_ai_recommend \
ACCConfigKeyDefaultPair(@"enable_vc_bach_recommend", @(ACCAIRecommendTypeDefault))

//编辑页自动带上@和#贴纸
#define kConfigBool_auto_add_sticker_on_edit_page \
ACCConfigKeyDefaultPair(@"acc_with_sticker_on_edit_page", @(NO))

// 进入拍摄器始终landing到快拍模式
#define kConfigBool_always_force_landing_story_tab \
ACCConfigKeyDefaultPair(@"always_force_landing_quick_shoot", @(NO))

// 快捷相册功能打开
#define kConfigBool_enable_quick_upload \
ACCConfigKeyDefaultPair(@"enable_quick_upload", @(NO))

// 快捷相册仅低活用户开始
#define kConfigBool_quick_upload_only_low_activeness \
ACCConfigKeyDefaultPair(@"quick_upload_only_low_activeness", @(NO))

//编辑页+发布页图集3期优化
#define kConfigDict_images_mvp_publish_opt \
ACCConfigKeyDefaultPair(@"images_mvp_publish_opt", @{})

static NSString * const kConfigBool_images_publish_opt_icon_animation = @"images_publish_opt_icon_animation";
static NSString * const kConfigBool_images_publish_opt_new_ui_style = @"images_publish_opt_new_ui_style";
static NSString * const kConfigBool_images_publish_opt_notice_dialog = @"images_publish_opt_notice_dialog";
static NSString * const kConfigBool_images_publish_opt_images_switch = @"images_publish_opt_images_switch";

// 拍照文字是否进快拍
#define kConfigBool_integrate_quick_shoot_subtab \
ACCConfigKeyDefaultPair(@"acc_integrate_quick_shoot_subtab", @(NO))

// 快拍子模式横滑后底部bar是否隐藏
#define kConfigBool_horizontal_scroll_hide_bottom_bar \
ACCConfigKeyDefaultPair(@"horizontal_scroll_hide_bottom_bar", @(NO))

// 是否可以全屏横滑切换子模式
#define kConfigBool_horizontal_scroll_change_subtab \
ACCConfigKeyDefaultPair(@"horizontal_scroll_change_subtab", @(NO))

// 拍照文字是否只允许发布日常
#define kConfigBool_subtab_restrict_publish_type \
ACCConfigKeyDefaultPair(@"subtab_restrict_publish_type", @(NO))

// 冷启相机是否记忆快慢速面板打开状态
#define kConfigBool_hide_bottom_speed_panel \
ACCConfigKeyDefaultPair(@"hide_bottom_speed_panel", @(NO))

// 文字模式是否提供更多背景
#define kConfigBool_text_mode_add_backgrounds \
ACCConfigKeyDefaultPair(@"text_mode_add_backgrounds", @(NO))

// settings
#define kConfigBool_upload_origin_audio_track \
ACCConfigKeyDefaultPair(@"upload_origin_audio_track", @(NO))

// settings
#define kConfigBool_close_upload_origin_frames \
ACCConfigKeyDefaultPair(@"close_vframe_upload", @(NO))

// settings
#define kConfigBool_enable_large_matting_detect_model \
ACCConfigKeyDefaultPair(@"enable_large_matting_detect_model", @(NO))

// settings
#define kConfigBool_enable_large_gesture_detect_model \
ACCConfigKeyDefaultPair(@"enable_large_gesture_detect_model", @(NO))

// settings
#define kConfigBool_enable_watermark_background \
ACCConfigKeyDefaultPair(@"aweme_base_conf.awe_enable_watermark_background", @(NO))

// settings
#define kConfigBool_enable_hq_vframe \
ACCConfigKeyDefaultPair(@"enable_hq_vframe", @(NO))

// settings
#define kConfigBool_forbid_voice_change_on_edit_page \
ACCConfigKeyDefaultPair(@"forbid_voice_change_on_edit_page", @(NO))

// settings
#define kConfigBool_enable_studio_special_plus_button \
ACCConfigKeyDefaultPair(@"enable_studio_special_plus_button", @(YES))

// settings
#define kConfigBool_new_capture_photo_autosave_watermark_image \
ACCConfigKeyDefaultPair(@"studio_save_new_capture_photo", @(YES))

// settings
#define kConfigBool_show_music_feedback_entrance \
ACCConfigKeyDefaultPair(@"show_music_feedback_entrance", @(NO))

// settings
#define kConfigBool_need_report_video_source_info \
ACCConfigKeyDefaultPair(@"need_report_video_source_info", @(YES))

// 1080p高清发布开关默认下发值
#define kConfigBool_use_1080P_default_value \
ACCConfigKeyDefaultPair(@"use_1080P_default_value", @(NO))

#define kConfigBool_enable_1080p_cut_same_video \
ACCConfigKeyDefaultPair(@"acc_enable_1080p_cut_same_video", @(NO))

#define kConfigBool_enable_1080p_moments_video \
ACCConfigKeyDefaultPair(@"acc_enable_1080p_moments_video", @(NO))

#define kConfigBool_enable_1080p_mv_video \
ACCConfigKeyDefaultPair(@"acc_enable_1080p_mv_video", @(NO))

#define kConfigBool_enable_audio_stream_play \
ACCConfigKeyDefaultPair(@"acc_enable_audio_stream_play", @(NO))

// 快拍长按拍摄时长是否为60s
#define kConfigBool_quick_story_long_press_hold_60s \
ACCConfigKeyDefaultPair(@"quick_story_long_press_hold_60s", @(NO))

// 快拍和分段拍拍摄中是否去掉时长
#define kConfigBool_recorder_remove_time_label \
ACCConfigKeyDefaultPair(@"recorder_remove_time_label", @(NO))

// 加号打开相机是否去掉动画
#define kConfigBool_plus_button_no_popup_animation \
ACCConfigKeyDefaultPair(@"plus_button_no_popup_animation", @(NO))

#define kConfigBool_tool_enable_edit_nle_draft \
ACCConfigKeyDefaultPair(@"tool_enable_edit_nle_draft", @(NO))

#define kConfigBool_recorder_auto_use_effect_recommend_music \
ACCConfigKeyDefaultPair(@"recorder_auto_use_effect_recommend_music", @(NO))

#define kConfigBool_edit_auto_use_effect_recommend_music \
ACCConfigKeyDefaultPair(@"edit_auto_use_effect_recommend_music", @(NO))

// 取消继续编辑是否存草稿
#define kConfigBool_save_draft_after_cancel_continue_edit \
ACCConfigKeyDefaultPair(@"awe_studio_backup_save_draft", @(NO))

// 0投稿用户激励UI配置
#define kConfigDict_incentive_ui_config \
ACCConfigKeyDefaultPair(@"incentive_ui_config", @{})

// 相机开启提前
#define kConfigBool_enable_start_capture_in_advance \
ACCConfigKeyDefaultPair(@"enable_start_capture_in_advance", @(NO))

// 后置非人脸场景开启自适应锐化
#define kConfigBool_enable_lens_sharpen \
ACCConfigKeyDefaultPair(@"enable_lens_sharpen", @(NO))

// 禁用录制页不熄屏
#define kConfigBool_disable_idle_timer_handler \
ACCConfigKeyDefaultPair(@"disable_studio_idle_timer_handler", @(NO))

// 使用动态道具icon
#define kConfigBool_enable_sticker_dynamic_icon \
ACCConfigKeyDefaultPair(@"enable_sticker_dynamic_icon", @(NO))

// 道具是否前置自动配乐
#define kConfigBool_recorder_auto_use_effect_recommend_music \
ACCConfigKeyDefaultPair(@"recorder_auto_use_effect_recommend_music", @(NO))

// 道具是否后置自动配乐
#define kConfigBool_edit_auto_use_effect_recommend_music \
ACCConfigKeyDefaultPair(@"edit_auto_use_effect_recommend_music", @(NO))

// 编辑页是否展示隐私设置
#define kConfigBool_show_privacy_settings_in_edit \
ACCConfigKeyDefaultPair(@"show_privacy_settings_in_edit", @(NO))

// 编辑页外显功能是否使用下发的白名单
#define kConfigBool_edit_toolbar_use_white_list \
ACCConfigKeyDefaultPair(@"edit_toolbar_use_white_list", @(NO))

// 发布页重构v1
#define kConfigBool_publish_page_refactor_v1 \
ACCConfigKeyDefaultPair(@"publish_page_refactor_v1", @(NO))

#define kConfigBool_anchor_refactor \
ACCConfigKeyDefaultPair(@"enable_anchor_creation_refactor", @(NO))

#define kConfigBool_commercial_monitor \
ACCConfigKeyDefaultPair(@"disable_commercial_monitor", @(NO))

// 多段道具
#define kConfigBool_enable_multi_seg_prop \
ACCConfigKeyDefaultPair(@"acc_enable_multi_seg_prop", @(YES))

// 开启新剪裁
#define kConfigBool_enable_new_clips \
ACCConfigKeyDefaultPair(@"acc_enable_cut_optimized", @(NO))

#define kConfigBool_disable_clip_fix \
ACCConfigKeyDefaultPair(@"acc_disable_clip_fix", @(NO))

// 使用重构版上传SDK
#define kConfigBool_use_refactored_file_upload_client_sdk \
ACCConfigKeyDefaultPair(@"studio_refactored_file_upload_client_sdk", @(NO))

// 开启EffectPlatformSDK检查算法模型更新耗时优化
#define kConfigBool_enable_algorithm_valid_check_once \
ACCConfigKeyDefaultPair(@"enable_algorithm_valid_check_once", @(NO))

// 开启EffectPlatformSDK重构
#define kConfigBool_enable_new_effect_manager \
ACCConfigKeyDefaultPair(@"enable_new_effect_manager", @(YES))

#define kConfigBool_use_TTNet_for_TTFile_upload_client \
ACCConfigKeyDefaultPair(@"acc_use_TTNet_for_TTFile_upload_client", @(NO))

#define kConfigBool_enable_1080p_photo_to_video \
ACCConfigKeyDefaultPair(@"acc_enable_1080p_photo_to_video", @(NO))

#define ACCConfigBOOL_allow_sticker_delete \
ACCConfigKeyDefaultPair(@"studio_sticker_delete_button", @(NO))

#define ACCConfigBOOL__sticker_delete_new_style \
ACCConfigKeyDefaultPair(@"studio_sticker_new_delete_style", @(NO))

#define ACCConfigInt_default_torch_status \
ACCConfigKeyDefaultPair(@"social_default_torch_status", @(0))

#define ACCConfigBool_enable_torch_auto_mode \
ACCConfigKeyDefaultPair(@"social_include_auto_flash_mode", @(NO))

#define ACCConfigBool_enable_front_torch \
ACCConfigKeyDefaultPair(@"social_support_front_flash_mode", @(NO))

#define ACCConfigDouble_torch_brightness_threshold \
ACCConfigKeyDefaultPair(@"social_torch_brightness_threshold", @(0))

#define kConfigBool_is_torch_perform_immediately \
ACCConfigKeyDefaultPair(@"social_is_enable_open_flash_immediately", @(YES))

#define kConfigDouble_torch_record_wait_duration \
ACCConfigKeyDefaultPair(@"social_torch_record_wait_duration", @(0))

#define ACCConfigBOOL_enable_continuous_flash_and_torch \
ACCConfigKeyDefaultPair(@"social_should_remember_flash_state", @(NO))

#define ACCConfigBool_meteor_mode_on \
ACCConfigKeyDefaultPair(@"aweme_meteor_mode_on", @(NO))

#define ACCConfigBool_tools_record_page_pendant \
ACCConfigKeyDefaultPair(@"tools_record_page_pendant", @(NO))

#define ACCConfigBOOL_enable_share_video_as_story \
ACCConfigKeyDefaultPair(@"social_enable_share_video_as_story", @(NO))

#define ACCConfigBOOL_profile_as_story_enable_silent_publish \
ACCConfigKeyDefaultPair(@"social_profile_as_story_enable_silent_publish", @(NO))

#define ACCConfigBOOL_social_enable_share_video_as_story_permission_optimation \
ACCConfigKeyDefaultPair(@"social_enable_share_video_as_story_permission_optimation", @(NO))

// 评论输入框下转发到日常 checkbox 入口开关
#define kConfigBoolEnableShareCommentToStory \
ACCConfigKeyDefaultPair(@"enable_comment_share_to_daily", @(NO))

// 分享别人的评论到日常 UI 样式
typedef NS_ENUM(NSUInteger, ACCShareCommentToStoryOthersCommentUIStyle) {
    ACCShareCommentToStoryOthersCommentUIStyleDefault, // 默认为0
    ACCShareCommentToStoryOthersCommentUIStyleReplaceReplyEntryAndAddActionsheetEntry, // 替换回复入口和添加 Actionsheet 入口
    ACCShareCommentToStoryOthersCommentUIStyleAddActionsheetEntry, // 添加 Actionsheet 入口
    ACCShareCommentToStoryOthersCommentUIStyleAddShareEntryAndAddActionsheetEntry, // 在回复右边添加转发入口和添加 Actionsheet 入口
};
#define kConfigEnumShareCommentToStoryOthersCommentUIStyle \
ACCConfigKeyDefaultPair(@"comment_share_to_daily_entry", @(ACCShareCommentToStoryOthersCommentUIStyleDefault))

// 分享评论到日常文案，长按菜单的入口
#define kConfigStringCommentShareToDailyOptionTextPressing \
ACCConfigKeyDefaultPair(@"comment_share_to_daily_option_text_pressing", @"转发到日常")

// 分享评论到日常文案，每条评论时间右边的小字入口
#define kConfigStringCommentShareToDailyOptionTextTail \
ACCConfigKeyDefaultPair(@"comment_share_to_daily_option_text_tail", @"转发")

// 视频评论总数大于阈值，才显示回复右边的转发按钮
#define kConfigInt_comment_count_limit_for_show_share_to_story_button \
ACCConfigKeyDefaultPair(@"comment_count_limit_for_show_share_to_story_button", @(20))

// 单个评论的点赞数大于阈值，才显示回复右边的转发按钮
#define kConfigInt_dig_count_limit_for_show_share_to_story_button \
ACCConfigKeyDefaultPair(@"dig_count_limit_for_show_share_to_story_button", @(20))

// 评论并分享到日常文案，评论输入框下入口
#define kConfigStringCommentShareToDailyOptionTextMain \
ACCConfigKeyDefaultPair(@"comment_share_to_daily_option_text_main", @"评论并转发到日常")

// 分享到日常编辑页增加裁剪能力
#define kConfigBool_enable_share_to_story_add_clip_capacity_in_edit_page \
ACCConfigKeyDefaultPair(@"enable_share_to_story_add_clip_capacity_in_edit_page", @(NO))
// 分享到日常编辑页裁剪是否可以超过默认时长
#define kConfigBool_enable_share_to_story_clip_can_exceed_default_duration_in_edit_page \
ACCConfigKeyDefaultPair(@"enable_share_to_story_clip_can_exceed_default_duration_in_edit_page", @(NO))
// 分享到日常编辑页裁剪默认时长(s)
#define kConfigInt_enable_share_to_story_clip_default_duration_in_edit_page \
ACCConfigKeyDefaultPair(@"enable_share_to_story_clip_default_duration_in_edit_page", @(0))
// 分享到日常编辑页增加自动字幕能力
#define kConfigBool_enable_share_to_story_add_auto_caption_capacity_in_edit_page \
ACCConfigKeyDefaultPair(@"enable_share_to_story_add_auto_caption_capacity_in_edit_page", @(NO))

// 长按加号按钮打开相册注册时间限制
#define kConfigInt_creation_threshold_of_icon_upload \
ACCConfigKeyDefaultPair(@"creation_threshold_of_icon_upload", @(3))

#define ACCConfigInt_share_video_enable_cover_as_background_color \
ACCConfigKeyDefaultPair(@"social_share_video_enable_cover_as_background_color", @(1))

#define ACCConfigBOOL_social_share_video_enable_interaction \
ACCConfigKeyDefaultPair(@"social_share_video_enable_interaction", @(NO))

//单位：秒
#define kConfigDouble_share_video_max_duration_input \
ACCConfigKeyDefaultPair(@"social_share_video_max_duration_input", @(60.0 * 30.0))

#define kConfigString_share_as_story_channel_title \
ACCConfigKeyDefaultPair(@"share_as_story_channel_title", @"分享到日常")

#define ACCConfigBOOL_video_republish_background_color \
ACCConfigKeyDefaultPair(@"social_republish_with_date_canvas_bg_type", @(NO))

#define ACCConfigEnum_video_republish_background_color \
ACCConfigKeyDefaultPair(@"social_republish_with_date_canvas_bg_type", @(0))

#define ACCConfigBOOL_enable_video_republish \
ACCConfigKeyDefaultPair(@"social_republish_with_date_show_entrance", @(NO))

#define ACCConfigBOOL_disable_video_download_use_player_cache \
ACCConfigKeyDefaultPair(@"studio_video_download_disable_use_player_cache", @(NO))

// 是否丢弃拍摄页相机首次启动时的黑帧
#define kConfigBool_studio_enable_drop_first_start_capture_frame \
ACCConfigKeyDefaultPair(@"studio_enable_drop_first_start_capture_frame", @(NO))

// 多图进编辑页默认更换配乐
#define kConfigBool_studio_muti_photo_back_album_change_music \
ACCConfigKeyDefaultPair(@"studio_muti_photo_back_album_change_music", @(NO))

// 是否启动AWETransition iOS 15上内存泄漏修复方案
#define kConfigBool_studio_enable_ios15_awetransition_guard \
ACCConfigKeyDefaultPair(@"studio_enable_ios15_awetransition_guard", @(YES))

#define kConfigBool_studio_music_panel_vertical \
ACCConfigKeyDefaultPair(@"music_panel_vertical", @(NO))

#define kConfigBool_studio_music_panel_checkbox \
ACCConfigKeyDefaultPair(@"music_panel_checkbox", @(NO))

#define kConfigBool_studio_music_panel_enable_first_song \
ACCConfigKeyDefaultPair(@"music_panel_enable_first_song", @(NO))

#define kConfigBool_studio_text_recommend \
ACCConfigKeyDefaultPair(@"studio_text_recommend", @(NO))
#define kConfigBool_studio_textmode_lib \
ACCConfigKeyDefaultPair(@"studio_textmode_lib", @(NO))
#define kConfigBool_studio_textsticker_lib \
ACCConfigKeyDefaultPair(@"studio_textsticker_lib", @(NO))
#define kConfigBool_studio_text_recommend_mode \
ACCConfigKeyDefaultPair(@"studio_text_recommend_mode", @(NO))
#define kConfigInt_studio_text_recommend_count \
ACCConfigKeyDefaultPair(@"studio_text_recommend_count", @(20))

#define kConfigBool_studio_enable_shoot_without_login \
ACCConfigKeyDefaultPair(@"studio_enable_shoot_without_login", @(NO))

#define kConfigBool_studio_optimize_prop_search_experience \
ACCConfigKeyDefaultPair(@"studio_optimize_prop_search_experience", @(NO))

#define kConfigBool_studio_record_automatic_select_music \
ACCConfigKeyDefaultPair(@"enable_video_record_auto_music", @(NO))

#define kConfigBool_studio_upload_automatic_select_music \
ACCConfigKeyDefaultPair(@"enable_video_upload_auto_music", @(NO))

#define kConfigBool_studio_enable_duet_import_asset \
ACCConfigKeyDefaultPair(@"enable_duet_import_asset", @(NO))

#define kConfigInt_studio_live_sticker_maxdaycount \
ACCConfigKeyDefaultPair(@"studio_live_sticker_maxdaycount", @(14))

// 主发布页中视频伙伴计划
#define kConfigBool_publish_enable_main_medium_reward \
ACCConfigKeyDefaultPair(@"publish_main_medium_reward", @(NO))
// 主发布页作品同步
#define kConfigInt_publish_main_video_sync \
ACCConfigKeyDefaultPair(@"publish_main_video_sync", @(0))
#define kConfigDict_publish_main_video_sync_tips_config \
ACCConfigKeyDefaultPair(@"publish_main_video_sync_tips_config", @{})

#define kConfigBool_tools_auto_apply_first_hot_prop \
ACCConfigKeyDefaultPair(@"tools_auto_apply_first_hot_prop", @(NO))

#define kConfigBool_studio_adjust_black_mask \
ACCConfigKeyDefaultPair(@"studio_adjust_black_mask", @(NO))

#define kConfigBool_studio_edit_music_panel_optimize \
ACCConfigKeyDefaultPair(@"studio_edit_music_panel_optimize", @(NO))

// 拍摄器内圆角变直角
#define kConfigBool_studio_in_camera_corner_rounded_to_right \
ACCConfigKeyDefaultPair(@"studio_in_camera_corner_rounded_to_right", @(NO))

// 拍摄器外圆角变直角
#define kConfigBool_studio_out_camera_corner_rounded_to_right \
ACCConfigKeyDefaultPair(@"studio_out_camera_corner_rounded_to_right", @(NO))

// 拍照体验优化
#define kConfigBool_studio_enable_take_picture_opt \
ACCConfigKeyDefaultPair(@"studio_enable_take_picture_opt", @(NO))

// 拍照体验优化延后出帧到编辑
#define kConfigBool_studio_enable_take_picture_delay_frame_opt \
ACCConfigKeyDefaultPair(@"studio_enable_take_picture_delay_frame_opt", @(NO))


#define kConfigInt_lite_theme \
ACCConfigKeyDefaultPair(@"rapid_tool_theme_tab", @(0))

#define kConfigInt_lite_theme_version \
ACCConfigKeyDefaultPair(@"rapid_tool_theme_version", @(0))

#define kConfigBool_lite_theme_beg_stay \
ACCConfigKeyDefaultPair(@"rapid_tool_theme_exit_prompt", @(YES))

#define kConfigString_lite_theme_tab_text \
ACCConfigKeyDefaultPair(@"rapid_tool_theme_tab_name", @"主题")

#define kConfigInt_lite_theme_tab_style \
ACCConfigKeyDefaultPair(@"rapid_tool_theme_tab_style", @(0))

#pragma mark - Int

// 是否异步压缩和保存草稿中的图片
#define kConfigBool_studio_enable_draft_async_image_compress \
ACCConfigKeyDefaultPair(@"studio_enable_draft_async_image_compress", @(NO))

// 拍摄编辑页侧边栏框架优化
#define kConfigBool_sidebar_text_disappear \
ACCConfigKeyDefaultPair(@"studio_optim_sidebar_text_disappear", @(NO))

#define kConfigBool_sidebar_record_turn_page \
ACCConfigKeyDefaultPair(@"studio_optim_sidebar_record_turn_page", @(NO))

#define kConfigBool_sidebar_modify_order \
ACCConfigKeyDefaultPair(@"studio_optim_sidebar_modify_order", @(NO))

#define kConfigBool_sidebar_edit_show_all \
ACCConfigKeyDefaultPair(@"studio_optim_sidebar_edit_show_all", @(NO))

// Big Font Mode - Tool
#define kConfigBool_big_font_strategy_tool \
ACCConfigKeyDefaultPair(@"big_font_strategy_tool", @(NO))

#define kConfigBool_enable_preupload_in_edit_page \
ACCConfigKeyDefaultPair(@"enable_preupload_in_edit_page", @(NO))

#pragma mark - Int

// 一键成片入口以及流程
typedef NS_ENUM(NSUInteger, ACCOneClickFlimingEntrance) {
    ACCOneClickFlimingEntranceNone = 0,
    ACCOneClickFlimingEntranceButton = 1, // 有一键成片按钮+不直接进入模板编辑页
    ACCOneClickFlimingEntranceButtonStarightShowComponent = 2,// 有一键成片按钮+直接进入模板编辑页
    ACCOneClickFlimingEntranceNoButton = 3 // 无一键成片按钮+不直接进入模板编辑页
};

#define kConfigInt_smart_video_entrance \
ACCConfigKeyDefaultPair(@"smart_video_entrance", @(0))

typedef NS_ENUM(NSUInteger, ACCOneClickMVEntrance) {
    ACCOneClickMVEntranceNone = 0,
    ACCOneClickMVEntranceButton = 1, // 有一键MV按钮+不直接进入选模板页
    ACCOneClickMVEntranceButtonStarightShowComponent = 2,// 有一键MV按钮+直接进入选模板页
};

#define kConfigInt_smart_mv_entrance \
ACCConfigKeyDefaultPair(@"studio_smart_mv_entrance", @(0))

// 录制采集的分辨率下标
#define kConfigInt_video_record_bitrate_category \
ACCConfigKeyDefaultPair(@"ios_video_category_index", @(0))

// 上传视频码率index
#define kConfigInt_video_upload_bitrate_category \
ACCConfigKeyDefaultPair(@"upload_bitrate_category_index", @(0))

// 上传视频分辨率index
#define kConfigInt_video_upload_size_category \
ACCConfigKeyDefaultPair(@"upload_video_size_index", @(0))

// 录制链编辑使用的分辨率下标
#define kConfigInt_record_edit_video_size_category \
ACCConfigKeyDefaultPair(@"studio_record_edit_video_size_category", @(0))

// 录制链合成使用的分辨率下标
#define kConfigInt_record_export_video_size_category \
ACCConfigKeyDefaultPair(@"studio_record_export_video_size_category", @(0))

// 录制链合成使用的分辨率下标
#define kConfigInt_record_watermark_video_size_category \
ACCConfigKeyDefaultPair(@"studio_record_watermark_video_size_category", @(0))

// 导入链编辑使用的分辨率下标
#define kConfigInt_upload_edit_video_size_category \
ACCConfigKeyDefaultPair(@"studio_upload_edit_video_size_category", @(0))

// 导入链合成使用的分辨率下标
#define kConfigInt_upload_export_video_size_category \
ACCConfigKeyDefaultPair(@"studio_upload_export_video_size_category", @(0))

// 导入链水印使用的分辨率下标
#define kConfigInt_upload_watermark_video_size_category \
ACCConfigKeyDefaultPair(@"studio_upload_watermark_video_size_category", @(0))

// 录制页开启音频采集时机
#define kConfigInt_record_audio_capture_timming_case \
ACCConfigKeyDefaultPair(@"studio_record_audio_capture_timming", @(0))

// 作品发布时展示私信分享
#define kConfigInt_im_publish_share_strategy \
ACCConfigKeyDefaultPair(@"im_publish_share_strategy", @(0))

#define kConfigInt_expose_prop_panel_count \
ACCConfigKeyDefaultPair(@"studio_expose_prop_style_v2_count", @(30))

// 识别推荐道具数量
#define kConfigInt_recognition_prop_count \
ACCConfigKeyDefaultPair(@"studio_recognition_prop_count", @(8))

// 限制裁剪页视频预览的最大帧率
#define kConfigInt_clip_preview_max_fps_rate \
ACCConfigKeyDefaultPair(@"studio_clip_preview_fps_limited", @(60))

// 上传裁剪预览使用的分辨率下标
#define kConfigInt_studio_upload_preview_video_size_category \
ACCConfigKeyDefaultPair(@"studio_upload_preview_video_size_category", @(4))

// 使用NLE创作智能照片电影
#define kConfigInt_smart_movie_algorithm \
ACCConfigKeyDefaultPair(@"smart_movie_algorithm", @(0))

// 道具拍同款时低端机相机采集帧率
#define kConfigInt_studio_prop_record_frame_rate \
ACCConfigKeyDefaultPair(@"studio_prop_record_frame_rate", @(30))

// 加号进拍摄页复用feed音乐道具

typedef NS_ENUM(NSInteger, ACCUseFeedMusicType) {
    ACCUseFeedMusicTypeNone = 0,
    ACCUseFeedMusicTypeA,//show add feed music with ui type A
    ACCUseFeedMusicTypeB,//show add feed music with ui type A
    ACCUseFeedMusicTypeIgnoreUserCountA,//show add feed music with ui type A, ignoring usercount
    ACCUseFeedMusicTypeIgnoreUserCountB,//show add feed music with ui type B, ignoring usercount
};

// Component性能架构优化
typedef NS_OPTIONS(NSUInteger, ACCOptimizePerformanceType) {
    ACCOptimizePerformanceTypeDisable = 0,
    ACCOptimizePerformanceTypeRecorderWithForceLoad = 1 << 1
};

NS_INLINE BOOL ACCOptimizePerformanceTypeContains(ACCOptimizePerformanceType value, ACCOptimizePerformanceType options) {
    return (value & options) == options;
}

#define kConfigInt_component_performance_architecture_optimization_type \
ACCConfigKeyDefaultPair(@"component_performance_architecture_optimization_type", @(0))

#define kConfigInt_component_performance_architecture_forceload_delay \
ACCConfigKeyDefaultPair(@"component_performance_architecture_forceload_delay", @(0))


// 卡点视频音乐优化
#define kConfigInt_ai_clip_music_optim_strategy \
ACCConfigKeyDefaultPair(@"studio_ai_clip_music_optim_strategy", @(0))

// POI贴纸新样式/multi style poi sticker option
#define kConfigInt_multi_poi_sticker_style \
ACCConfigKeyDefaultPair(@"studio_multi_poisticker_style", @(0))

// 首发激励挂件展示引导说明的天数字段
#define kConfigInt_first_creative_pendant_show_days \
ACCConfigKeyDefaultPair(@"first_video_avatar_decoration_time", @(7))

// 进入拍摄器始终landing到快拍模式 - 音乐拍同款
typedef NS_ENUM(NSUInteger, ACCStoryMusicLandingOption) {
    ACCStoryMusicLandingUnspecified, // 无特殊处理
    ACCStoryMusicLandingMultiLengthAlways, // 固定分段拍
    ACCStoryMusicLandingMultiLengthInitially, // 第一次分段拍，后续记忆
};

#define kConfigInt_always_force_landing_quick_shoot_music_option \
ACCConfigKeyDefaultPair(@"always_force_landing_quick_shoot_music_option", @(0))

// 编辑页发布日常的文案
#define kConfigInt_edit_diary_button_text \
ACCConfigKeyDefaultPair(@"creation_edit_diary_button_text", @(0))

// 音乐选择页优化
#define kConfigInt_studio_music_selected_page_optim_strategy \
ACCConfigKeyDefaultPair(@"studio_music_selected_page_optim_strategy", @(0))

// 剪同款选择素材按钮提示文案更改
#define kConfigInt_replace_cutsame_select_hint_text \
ACCConfigKeyDefaultPair(@"cutsame_select_hint_text", @(0))

// 影集名称统一替换
#define kConfigInt_replace_cutsame_name_text \
ACCConfigKeyDefaultPair(@"cutsame_name_text", @(0))

// 进入录制页后再下载道具
#define kConfigInt_download_effect_in_recorder \
ACCConfigKeyDefaultPair(@"tc_download_effect_in_recorder", @(0))

// 【抖音】优化道具列表请求功能
#define kConfigInt_platform_optimize_strategy \
ACCConfigKeyDefaultPair(@"platformOptimizeStrategy", @(0))

// 卡点音乐最大视频时长
#define kConfigInt_AI_video_clip_max_duration \
ACCConfigKeyDefaultPair(@"AIVideoClipMaxDuration", @(20))

// 限制视频编辑的最大帧率
#define kConfigInt_edit_video_maximum_frame_rate_limited \
ACCConfigKeyDefaultPair(@"editVideMaximumFrameRateLimited", @(60)) // VE 要求本地默认值用60 @zhouyi.ysj

// 创作页suggest话题新增icon
#define kConfigInt_enable_challenge_sug_tag \
ACCConfigKeyDefaultPair(@"acc_enable_challenge_sug_tag", @(0))

// 快拍n天可见
#define kConfigInt_story_visible_for_n_days \
ACCConfigKeyDefaultPair(@"acc_familiar_ttl_story_day_num", @(1))

typedef NS_ENUM(NSUInteger, ACCStoryEditorOptimizeType) {
    ACCStoryEditorOptimizeTypeNone,
    ACCStoryEditorOptimizeTypeA,
};

//编辑页右侧tool bar布局优化
#define kConfigInt_editor_toolbar_optimize \
ACCConfigKeyDefaultPair(@"acc_edit_page_ui_adjustment", @(1))

// 编辑页日常强引导类型
typedef NS_ENUM(NSUInteger, ACCEditDiaryStrongGuideStyle) {
    ACCEditDiaryStrongGuideStyleNone = 0, // 无
    ACCEditDiaryStrongGuideStylePop = 1, // 点击按钮后弹出
    ACCEditDiaryStrongGuideStyleTip = 2, // 提示
};

#define kConfigInt_edit_diary_strong_guide_style \
ACCConfigKeyDefaultPair(@"creation_edit_diary_strong_guide_style", @(0))

// 编辑页日常底部样式
typedef NS_ENUM(NSUInteger, ACCEditDiaryBottomStyle) {
    ACCEditDiaryBottomStyleNone = 0, // 无
    ACCEditDiaryBottomStyleRectangle = 1, // 方形
    ACCEditDiaryBottomStyleRound = 2, // 圆形
};
#define kConfigInt_edit_diary_bottom_style \
ACCConfigKeyDefaultPair(@"creation_edit_diary_bottom_style", @(0))

// 编辑页日常底部视频圆角
#define kConfigBool_edit_diary_bottom_corner \
ACCConfigKeyDefaultPair(@"creation_edit_diary_bottom_corner", @(YES))

// 编辑页日常底部分享私信
#define kConfigBool_edit_diary_bottom_share_im \
ACCConfigKeyDefaultPair(@"creation_edit_diary_bottom_share_im", @(NO))

// 编辑页日常底部左边有存草稿
#define kConfigBool_edit_diary_bottom_left_save_draft \
ACCConfigKeyDefaultPair(@"creation_edit_diary_bottom_left_save_draft", @(NO))

// 编辑页日常底部左边有存本地
#define kConfigBool_edit_diary_bottom_left_save_album \
ACCConfigKeyDefaultPair(@"creation_edit_diary_bottom_left_save_album", @(NO))

// 编辑页日常强引导频率
#define kConfigInt_edit_diary_strong_guide_frequency \
ACCConfigKeyDefaultPair(@"creation_edit_diary_strong_guide_frequency", @(0))

// 编辑页日常弱引导频率
typedef NS_ENUM(NSUInteger, ACCEditDiaryGuideFrequency) {
    ACCEditDiaryGuideFrequencyNone = 0, // 无
    ACCEditDiaryGuideFrequencyOnce = 1, // 只一次
    ACCEditDiaryGuideFrequencyDaily = 2, // 每天一次
    ACCEditDiaryGuideFrequencyweekly = 3, // 每周一次
};

#define kConfigInt_anchor_video_preview \
ACCConfigKeyDefaultPair(@"anchor_video_preview", @(0))

#define kConfigInt_edit_diary_weak_guide_frequency \
ACCConfigKeyDefaultPair(@"creation_edit_diary_weak_guide_frequency", @(0))

// 草稿点击落地页为编辑页
#define kConfigBool_creation_draft_landing_edit_view \
ACCConfigKeyDefaultPair(@"creation_draft_landing_edit_view", @(NO))

// 草稿从编辑页返回弹actionSheet
#define kConfigInt_creation_draft_edit_back_click_with_action_sheet \
ACCConfigKeyDefaultPair(@"creation_draft_edit_back_click_with_action_sheet", @(0))

// 快速保存类型
#define kConfigInt_edit_view_quick_save_type \
ACCConfigKeyDefaultPair(@"edit_view_quick_save_type", @(0))

// 快速保存加号引导
#define kConfigBool_quick_save_guide \
ACCConfigKeyDefaultPair(@"quick_save_guide", @(NO))

// 快速保存是否弹出
#define kConfigBool_edit_view_quick_save_and_pop \
ACCConfigKeyDefaultPair(@"edit_view_quick_save_and_pop", @(NO))

// 快速保存强引导
#define kConfigBool_edit_view_quick_save_strong_guide \
ACCConfigKeyDefaultPair(@"edit_view_quick_save_strong_guide", @(NO))

// 快速保存本地带水印
#define kConfigBool_edit_view_quick_save_album_with_watermark \
ACCConfigKeyDefaultPair(@"edit_view_quick_save_album_with_watermark", @(NO))

// 视频详情存本地无水印
#define kConfigBool_my_video_save_album_no_watermark \
ACCConfigKeyDefaultPair(@"my_video_save_album_no_watermark", @(NO))

// 发布后存本地无水印
#define kConfigBool_publish_save_album_no_watermark \
ACCConfigKeyDefaultPair(@"publish_save_album_no_watermark", @(NO))

// 高级设置新增水印开关
#define kConfigBool_self_save_water_mark \
ACCConfigKeyDefaultPair(@"self_save_water_mark", @(NO))

// 高级设置新增水印开关出提示
#define kConfigBool_self_save_water_mark_hint \
ACCConfigKeyDefaultPair(@"self_save_water_mark_hint", @(NO))


// 草稿箱隐藏再拍一个
#define kConfigBool_creation_draft_box_hide_try_again \
ACCConfigKeyDefaultPair(@"creation_draft_box_hide_try_again", @(NO))

// 草稿上下滑
#define kConfigBool_creation_draft_feed_enabled \
ACCConfigKeyDefaultPair(@"creation_draft_feed_enabled", @(NO))

// 草稿上下滑拍同款类型
#define kConfigInt_creation_draft_feed_try_again_type \
ACCConfigKeyDefaultPair(@"creation_draft_feed_try_again_type", @(0))

// 照片忽略metadata处理
#define kConfigBool_edit_view_photo_ignore_metadata \
ACCConfigKeyDefaultPair(@"edit_view_photo_ignore_metadata", @(NO))

// 显示播放全曲入口
#define kConfigInt_social_show_song_entrance \
ACCConfigKeyDefaultPair(@"acc_social_show_song_entrance", @(0))

// 音乐人主页外露榜单入口及支持顺序播放
#define kConfigInt_music_tab_chart_entrance_and_bottom_panel \
ACCConfigKeyDefaultPair(@"music_tab_chart_entrance_and_bottom_panel", @(0))

// settings
#define kConfigInt_http_retry_count \
ACCConfigKeyDefaultPair(@"http_retry_count", @(-1))

// settings
#define kConfigInt_info_sticker_max_count \
ACCConfigKeyDefaultPair(@"info_sticker_max_count", @(30))

// settings
#define kConfigInt_text_sticker_max_count \
ACCConfigKeyDefaultPair(@"text_sticker_max_count", @(30))

// settings
#define kConfigInt_auto_clean_effect_cache_threshold \
ACCConfigKeyDefaultPair(@"clean_effect_cache_threshold", @(360))

// settings
#define kConfigInt_target_clean_effect_cache_target_threshold \
ACCConfigKeyDefaultPair(@"clean_effect_cache_target_threshold", @(180))

// settings
#define kConfigInt_album_image_max_sticker_count \
ACCConfigKeyDefaultPair(@"sticker_count_per_image_album", @(5))

// settings
#define kConfigDict_creative_motivation_task_res \
ACCConfigKeyDefaultPair(@"creative_motivation_task_res", @{})

// settings
#define kConfigInt_duoshan_toast_frequency \
ACCConfigKeyDefaultPair(@"sync_to_duoshan_prop.sync_to_duoshan_toast_frequency", @(0))

// 加号进拍摄页复用feed音乐时长
#define kConfigInt_direct_shoot_reuse_music_duration \
ACCConfigKeyDefaultPair(@"direct_shoot_reuse_music_duration", @(15))

// 加号进拍摄页复用feed音乐使用人数
#define kConfigInt_direct_shoot_reuse_music_use_count \
ACCConfigKeyDefaultPair(@"direct_shoot_reuse_music_use_count", @(50))

#define kConfigInt_recommended_music_videos_mode \
ACCConfigKeyDefaultPair(@"acc_recommended_music_videos_mode", @(0))

// settings
#define kConfigInt_video_max_fans_count \
ACCConfigKeyDefaultPair(@"video_upload_normalizationn_param", @(100000))

#define kConfigInt_publish_draft_style \
ACCConfigKeyDefaultPair(@"tools_draft_button_optimize", @(0))

// 审核抽帧分辨率
#define kConfigInt_studio_media_frame_resolution \
ACCConfigKeyDefaultPair(@"studio_media_frame_resolution", @(360))

// 审核抽帧分辨率
#define kConfigInt_studio_high_frame_resolution \
ACCConfigKeyDefaultPair(@"studio_high_frame_resolution", @(540))

// 拍摄页不上特效帧数，默认3
#define kConfigInt_no_effect_frame_count \
ACCConfigKeyDefaultPair(@"studio_no_effect_frame_count", @(3))

#define kConfigInt_tools_fans_threshold \
ACCConfigKeyDefaultPair(@"tools_user_fans_threshold", @(10))

#define kConfigInt_tools_publish_max_words \
ACCConfigKeyDefaultPair(@"tools_publish_max_words", @(500))

// 编辑页架构优化重开
#define kConfigBool_enable_optimize_arch_performance_in_edit \
ACCConfigKeyDefaultPair(@"enable_optimize_arch_performance_in_edit", @(YES))

// 音乐详情页新结构一键成片模版下发
#define kConfigBool_is_need_music_mv_template \
ACCConfigKeyDefaultPair(@"is_need_music_mv_template", @(NO))

#define kConfigBool_studio_prop_camera_auto_front \
ACCConfigKeyDefaultPair(@"studio_prop_camera_auto_front", @(NO))

#define kConfigBool_studio_prop_camera_auto_front_user_affect \
ACCConfigKeyDefaultPair(@"studio_prop_camera_auto_front_user_affect", @(NO))

// 相册内容显示收藏标记
#define kConfigBool_enable_display_album_favorite \
ACCConfigKeyDefaultPair(@"enable_display_album_favorite", @(NO))

#pragma mark - ENUM

// 音乐开拍Landing优化
typedef NS_ENUM(NSUInteger, ACCMusicShootLandingType) {
    ACCMusicShootLandingTypeDefault,//次级策略
    ACCMusicShootLandingTypeMusicRecordableTime,//根据音乐可拍时长执行landing策略
    ACCMusicShootLandingTypeMinVideoAndMusic,//根据min{视频时长，音乐最大可拍摄}执行landing策略
    ACCMusicShootLandingTypeSyncMusicClip,//拍同款同步剪裁效果，landing同 min{video,music}
};
#define kConfigInt_music_shoot_landing_submode_type \
ACCConfigKeyDefaultPair(@"music_shoot_landing_submode_type", @(ACCMusicShootLandingTypeDefault))

// 音频投稿模式
typedef NS_ENUM(NSUInteger, ACCRecordAudioModeType) {
    ACCRecordAudioModeTypeDefault = 0,//线上
    ACCRecordAudioModeTypeAtTextRight = 1,//入口在文字右边
    ACCRecordAudioModeTypeAtTextRightWithCaption = 2,//入口在文字右边 添加自动识别字幕
    ACCRecordAudioModeTypeAtTextLeft = 3,//入口在文字左边
    ACCRecordAudioModeTypeAtTextLeftWithCaption = 4,//入口在文字左边 添加自动识别字幕
};
#define kConfigInt_enable_voice_publish \
ACCConfigKeyDefaultPair(@"enable_voice_publish", @(ACCRecordAudioModeTypeDefault))

// 编辑页子页面UI优化多组实验
#define kConfigInt_edit_view_ui_optimization \
ACCConfigKeyDefaultPair(@"edit_view_ui_optimization_mode", @(ACCEditViewUIOptimizationTypeDisabled))

// 编辑器支持快速添加特效_简化面板_icon
#define kConfigDict_special_effects_simplified_panel_new_icon \
ACCConfigKeyDefaultPair(@"special_effects_simplified_panel_new_icon", @(NO))
// 编辑器支持快速添加特效_简化面板_应用场景
#define kConfigDict_special_effects_simplified_panel_scenario \
ACCConfigKeyDefaultPair(@"special_effects_simplified_panel_scenario", @(0))

typedef NS_ENUM(NSUInteger, ACCEditViewUIOptimizationType) {
    ACCEditViewUIOptimizationTypeDisabled,//不优化
    ACCEditViewUIOptimizationTypeSaveCancelBtn,//「取消」「保存」下移，播放不变
    ACCEditViewUIOptimizationTypePlayBtn,//「取消」「保存」下移，播放下移
    ACCEditViewUIOptimizationTypeReplaceIconWithText,//「取消」「保存」下移且变icon，播放下移
};

// 视频评论视频
typedef NS_ENUM(NSUInteger, ACCVideoReplyStickerType) {
    ACCVideoReplyStickerTypeDisabled, // 无生产能力，无消费能力
    ACCVideoReplyStickerTypeOnlyConsumption, // 无生产能力，有消费能力
    ACCVideoReplyStickerTypeCreationAndConsumption, // 有生产能力，有消费能力
};

// 拍摄链路设计优化5期
typedef NS_OPTIONS(NSUInteger, ACCViewFrameOptimize) {
    ACCViewFrameOptimizeNone = 0,
    ACCViewFrameOptimizeFullDisplay = 1 << 0,
    ACCViewFrameOptimizeHideStatusBar = 1 << 1,
    ACCViewFrameOptimizeUpload = 1 << 2
};

NS_INLINE BOOL ACCViewFrameOptimizeContains(ACCViewFrameOptimize value, ACCViewFrameOptimize options) {
    return (value & options) == options;
}

#define kConfigInt_view_frame_optimize_type \
ACCConfigKeyDefaultPair(@"view_frame_optimize_type", @(ACCViewFrameOptimizeNone))

// 音乐拍同款入口进入拍摄器支持道具推荐

// 推荐侧下发策略
typedef NS_ENUM(NSUInteger, ACCServerMusicRecommendPropMode) {
    ACCServerMusicRecommendPropModeNone = 0,
    ACCServerMusicRecommendPropModeA = 1,
    ACCServerMusicRecommendPropModeB = 2,
    ACCServerMusicRecommendPropModeC = 3,
    ACCServerMusicRecommendPropModeD = 4,
    ACCServerMusicRecommendPropModeE = 5,
    ACCServerMusicRecommendPropModeF = 6,
};

// 拍摄、编辑页按钮Y值调整
#define kConfigBoolEnableYValueOfRecordAndEditPageUIAdjustment \
ACCConfigKeyDefaultPair(@"enable_record_and_edit_page_ui_adjustment", @(NO))
#define kYValueOfRecordAndEditPageUIAdjustment (ACCConfigBool(kConfigBoolEnableYValueOfRecordAndEditPageUIAdjustment) ? 0 : 20)

// 是否开启加号按钮长按打开相册页功能
#define kConfigBoolEnableOpenAlbumPageThroughAddButton \
ACCConfigKeyDefaultPair(@"enable_open_album_page_through_add_button", @(NO))

// 加号按钮长按有效最小时长(ms)
#define kConfigIntAddButtonLongPressMinimumPressDuration \
ACCConfigKeyDefaultPair(@"add_button_long_press_minimum_press_duration", @(300))

#define kConfigInt_server_music_recommend_prop_mode \
ACCConfigKeyDefaultPair(@"music_record_same_recommend_prop_mode", @(ACCServerMusicRecommendPropModeNone))

// 支持脏镜头检测
typedef NS_ENUM(NSUInteger, ACCDirtyCameraDetectMode) {
    ACCDirtyCameraDetectModeOff = 0,
    ACCDirtyCameraDetectModeWithoutToast = 1,
    ACCDirtyCameraDetectModeWithToast = 2,
    ACCDirtyCameraDetectModeWithToastAndMemory = 3,
};

#define kConfigInt_dirty_camera_detection_mode \
ACCConfigKeyDefaultPair(@"dirty_camera_detection_mode", @(ACCDirtyCameraDetectModeOff))

// 抖音极速版融合大包后投稿链路调整
typedef NS_ENUM(NSUInteger, ACCDouyinLiteMergeType) {
    ACCDouyinLiteMergeTypeDefault = 0,
    ACCDouyinLiteMergeTypeEditPublishWithoutQuickShoot = 1,
    ACCDouyinLiteMergeTypeEditPublishWithQuickShoot = 2,
};

//极速版红包视频
typedef NS_ENUM(NSUInteger, ACCDouyinLiteRedPackageStyle) {
    ACCDouyinLiteRedPackageStyleDefault = 0,//极速版无红包视频能力
    ACCDouyinLiteRedPackageStyleOne = 1,//极速版红包视频样式1
    ACCDouyinLiteRedPackageStyleTwo = 2,//极速版无红包视样式2
};

#define kConfigInt_douyin_lite_merge_type \
ACCConfigKeyDefaultPair(@"douyin_lite_merge_type", @(0))

#define kConfigInt_douyin_lite_red_package_type \
ACCConfigKeyDefaultPair(@"rapid_tools_is_support_red_pack_video", @(0))

// 道具推荐音乐

//Recommend music for prop effect, PRD link :https://bytedance.feishu.cn/docs/doccnnCd48Q7v7boZJQFovsOUzh#
typedef NS_ENUM(NSUInteger, ACCRecommendMusicByProp) {
    ACCRecommendMusicByPropDefault = 0,
    ACCRecommendMusicByPropA = 1, // Only weakly bind music
    ACCRecommendMusicByPropB = 2, // Weakly bind music + recommended music (Strategy for recommendation is based on music 'vv' rank)
    ACCRecommendMusicByPropC = 3, // Weakly bind music + recommended music (Strategy for recommendation, low threshold)
    ACCRecommendMusicByPropD = 4, // Weakly bind music + recommended music (Strategy for recommendation, medium threshold)
    ACCRecommendMusicByPropE = 5, // Weakly bind music + recommended music (Strategy for recommendation, high threshold)
};

#define kConfigInt_recommend_music_by_effect \
ACCConfigKeyDefaultPair(@"recommend_music_by_effect", @(ACCRecommendMusicByPropDefault))

// 编辑搜索贴纸
typedef NS_ENUM(NSUInteger, ACCEditSearchStickerType) {
    ACCEditSearchStickerTypeDisable,
    ACCEditSearchStickerTypeManully,
    ACCEditSearchStickerTypeAuto
};

#define kConfigInt_search_sticker_type \
ACCConfigKeyDefaultPair(@"studio_show_searchsticker", @(ACCEditSearchStickerTypeDisable))

// 切换effectcam道具面板

typedef NS_ENUM(NSUInteger, ACCStickerSortOption) {
    ACCStickerSortOptionDefault,
    ACCStickerSortOptionRD,
    ACCStickerSortOptionIntegration,
    ACCStickerSortOptionAmaizing,
    ACCStickerSortOptionCreator
};

#define kConfigInt_effect_stickers_panel_option \
ACCConfigKeyDefaultPair(@"effect_effectcam_Stickers_switch_panel", @(ACCStickerSortOptionRD))

// Feed直播预告贴纸
#define kConfigBool_feed_livesticker_type \
ACCConfigKeyDefaultPair(@"feed_livesticker_type", @(NO))
#define kConfigInt_feed_live_sticker_style \
ACCConfigKeyDefaultPair(@"feed_live_sticker_style", @(0))

// 音乐卡片样式
#define kConfigInt_music_card_style \
ACCConfigKeyDefaultPair(@"acc_musicCardStyle", @(AWEStudioMusicCardStyleDefault))

// nearby
typedef NS_ENUM(NSUInteger, ACCPreferPublishToNearbyType) {
    ACCPreferPublishToNearbyTypeNone = 0,
    ACCPreferPublishToNearbyTypeExposure = 1,
    ACCPreferPublishToNearbyTypeFold = 2,
};

#define kConfigInt_prefer_publish_nearby_cell_type \
ACCConfigKeyDefaultPair(@"acc_preferPublishNearbyCellType", @(ACCPreferPublishToNearbyTypeNone))

//
typedef NS_ENUM(NSUInteger, ACCAllowPublishToNearbyType) {
    ACCAllowPublishToNearbyTypeNone = 0,//线上
    ACCAllowPublishToNearbyTypeDefaultOpenWithLanding = 1,//默认开启+开启后landing到同城
    ACCAllowPublishToNearbyTypeDefaultOpenWithNoLanding = 2,//默认开启+landing同线上
    ACCAllowPublishToNearbyTypeDefaultCloseWithLanding = 3,//默认关闭+开启后landing到同城
    ACCAllowPublishToNearbyTypeDefaultCloseWithNoLanding = 4,//默认关闭+landing同线上
};

#define kConfigInt_enable_record_left_slide_dismiss \
ACCConfigKeyDefaultPair(@"acc_enableRecordLeftSlideDismiss", @(NO))

#define kConfigInt_enable_homepage_left_extension \
ACCConfigKeyDefaultPair(@"acc_enable_homepage_left_extension", @(NO))

#define kConfigInt_enable_camera_switch_haptic \
ACCConfigKeyDefaultPair(@"acc_haptic_refinements_camera_switch_enabled", @(NO))

#define kConfigInt_enable_record_touchup_haptic \
ACCConfigKeyDefaultPair(@"acc_haptic_refinements_record_touchup_enabled", @(NO))

#define kConfigInt_enable_haptic \
ACCConfigKeyDefaultPair(@"acc_haptic_refinements_enabled", @(NO))

// 文本朗读二期多音色选择
typedef NS_ENUM(NSUInteger, ACCTextReaderPhase2Type) {
    ACCTextReaderPhase2TypeDisable,
    ACCTextReaderPhase2TypeAllowAll,
    ACCTextReaderPhase2TypeNotShowInToolBar,
    ACCTextReaderPhase2TypeSameDuration
};

#define kConfigInt_text_reader_multiple_sound_effects \
ACCConfigKeyDefaultPair(@"text_reader_allowing_choose_sound_effects", @(ACCTextReaderPhase2TypeDisable))

// 文本朗读二期多音色选择
typedef NS_ENUM(NSUInteger, ACCMusicLoopMode) {
    ACCMusicLoopModeOff = 0,
    ACCMusicLoopModeDeafultLoop = 1,
    ACCMusicLoopModeDefaultNonloop = 2,
};

#define kConfigInt_manually_music_loop_mode \
ACCConfigKeyDefaultPair(@"support_manually_set_music_loop", @(ACCMusicLoopModeOff))

// 合拍提示使用/自动带上原视频的道具
typedef NS_ENUM(NSUInteger, ACCDuetWithEffectPropType) {
    ACCDuetWithEffectPropTypeDefault = 0,
    ACCDuetWithEffectPropTypeAutoApply = 1,
    ACCDuetWithEffectPropTypeTipsBubble = 2
};

#define kConfigInt_duet_with_effect_or_show_tips_bubble \
ACCConfigKeyDefaultPair(@"auto_apply_effect_in_duet", @(ACCDuetWithEffectPropTypeDefault))

// 中断续传弹窗样式
typedef NS_ENUM(NSUInteger, ACCBackupEditsPopupStyle) {
    ACCBackupEditsPopupStyleDefault = 0,
    ACCBackupEditsPopupStyleOne,
    ACCBackupEditsPopupStyleTwo,
};

#define kConfigInt_backup_popup_style \
ACCConfigKeyDefaultPair(@"awe_studio_backup_popup_style", @(ACCBackupEditsPopupStyleDefault))

// 道具面板支持搜索功能
typedef NS_ENUM(NSUInteger, ACCPropPanelSearchEntranceType) {
    ACCPropPanelSearchEntranceTypeNone = 0,
    ACCPropPanelSearchEntranceTypeTab,
    ACCPropPanelSearchEntranceTypeButton,
};

#define kConfigInt_new_search_effect_config \
ACCConfigKeyDefaultPair(@"new_search_effect_config", @(ACCPropPanelSearchEntranceTypeNone))

// 相册展示排序风格
typedef NS_ENUM(NSInteger, ACCAlbumAssetSortStyle) {
    ACCAlbumAssetSortStyleDefault = 0,//sort by create date
    ACCAlbumAssetSortStyleRecent = 1,//sort by recent
};

#define kConfigInt_album_asset_sort_style \
ACCConfigKeyDefaultPair(@"album_asset_sort_style_v2", @(ACCAlbumAssetSortStyleDefault))

#define kConfigBool_enable_album_data_multithread_opt \
ACCConfigKeyDefaultPair(@"enable_album_data_multithread_opt", @(NO))

// 道具面板支持探索功能
typedef NS_ENUM(NSUInteger, ACCPropPanelExploreType) {
    ACCPropPanelExploreTypeNone = 0,
    ACCPropPanelExploreTypeV1 = 1,
    ACCPropPanelExploreTypeV2 = 2,
    ACCPropPanelExploreTypeV3 = 3,
};

#define kConfigInt_sticker_explore_type \
ACCConfigKeyDefaultPair(@"sticker_explore_type", @(ACCPropPanelExploreTypeNone))

typedef NS_ENUM(NSUInteger, ACCPublishTitleOptType) {
    ACCPublishTitleOptTypeNone,
    ACCPublishTitleOptTypeLongExpand,
    ACCPublishTitleOptTypeLongNoExpand,
};

#define kACCConfigInt_publish_text_long_type \
ACCConfigKeyDefaultPair(@"publish_long_text_type", @(ACCPublishTitleOptTypeNone))

#define kConfigBool_publish_disable_continuous_enter \
ACCConfigKeyDefaultPair(@"publish_disable_continuous_enter", @(NO))

typedef NS_ENUM(NSUInteger, ACCPublishTitleExpandType) {
    ACCPublishTitleExpandTypeNone,
    ACCPublishTitleExpandTypeOverflow,
    ACCPublishTitleExpandTypeInput,
};

#define kACCConfigInt_publish_enable_show_expand_icon \
ACCConfigKeyDefaultPair(@"publish_enable_show_expand_icon", @(ACCPublishTitleExpandTypeNone))

// 配乐体验大反转
typedef NS_ENUM(NSUInteger, ACCMusicReverseType) {
    ACCMusicReverseTypeNone,
    ACCMusicReverseTypeHotList,
    ACCMusicReverseTypeBanSelectMusicPanel,
};

#define kACCConfigInt_studio_edit_page_reverse_add_music \
ACCConfigKeyDefaultPair(@"studio_edit_page_reverse_add_music", @(ACCMusicReverseTypeNone))

typedef NS_ENUM(NSUInteger, ACCLiteShootGuideType) {
    ACCLiteShootGuideTypeNone,
    ACCLiteShootGuideTypeVideoGuide,
    ACCLiteShootGuideTypeAlgorithm,
    ACCLiteShootGuideTypeVideoGuideAlgorithm
};

#define kConfigInt_lite_shoot_guide \
ACCConfigKeyDefaultPair(@"lite_low_quality_shoot", @(ACCLiteShootGuideTypeNone))

// 拍摄器智能识别优化
typedef NS_ENUM(NSUInteger, ACCRecognitionOptimizeType) {
    ACCRecognitionOptimizeTypeNone,
    ACCRecognitionOptimizeTypeNOAutoScan,
    ACCRecognitionOptimizeTypeAutoScanOptimize,
};

#define kACCConfigInt_tools_camera_smart_recognition_optimize \
ACCConfigKeyDefaultPair(@"tools_camera_smart_recognition_optimize", @(ACCRecognitionOptimizeTypeNone))

//热点关联优化界面
typedef NS_ENUM(NSUInteger, ACCHotSpotRelatePageType) {
    ACCHotSpotRelatePageTypeNative = 0,
    ACCHotSpotRelatePageTypeFrontEnd = 1,
};

#define kACCConfigInt_enable_hot_spot_relate_second_version \
ACCConfigKeyDefaultPair(@"enable_hot_spot_relate_second_version", @(ACCHotSpotRelatePageTypeNative))

#pragma mark - String

// 使用动态下发的groot贴纸识别兜底图
#define kConfigString_dynamic_groot_placeholder_image_url \
ACCConfigKeyDefaultPair(@"groot_placeholder_image_url", @{})

// 使用动态下发的码率配置
#define kConfigString_dynamic_bitrate_json_string \
ACCConfigKeyDefaultPair(@"studioDynamicBitrateJsonString", @"")

// 使用动态下发的高清码率配置
#define kConfigString_vesdk_dynamic_hd_bitrate_json \
ACCConfigKeyDefaultPair(@"studio_vesdk_dynamic_hd_bitrate_json", @"")

// 画质增强模型名称
#define kConfigString_lens_hdr_model_name \
ACCConfigKeyDefaultPair(@"lens_hdr_model_name", @"lens_hdr")

// 图集编辑lens画质增强模型名称串
#define kConfigString_image_album_lens_hdr_model_name \
ACCConfigKeyDefaultPair(@"image_album_lens_hdr_model_name", @"lens_hdr")

// 分段拍文案修改实验
#define kConfigString_split_shoot_tab_name \
ACCConfigKeyDefaultPair(@"split_shoot_tab_name", @"")

// 快拍编辑页发日常的默认按钮文案
#define kConfigString_edit_post_direct_text \
ACCConfigKeyDefaultPair(@"story_v3_config.creation_edit_post_direct_text", @"creation_edit_post_diary")

#define kConfigString_javisChannel \
ACCConfigKeyDefaultPair(@"javisChannel", @"")

#define kConfigString_quick_save_guide_str \
ACCConfigKeyDefaultPair(@"quick_save_guide_str", @"")

#define kConfigString_ai_recommend_music_list_default_uri \
ACCConfigKeyDefaultPair(@"aweme_music_ailab.song_uri", @"")

#define kConfigString_record_text_tab_name \
ACCConfigKeyDefaultPair(@"text_record_tab_name", @"文字")

#define kConfigString_story_record_mode_text \
ACCConfigKeyDefaultPair(@"story_v3_config.creation_shoot_snap_text", @"creation_shoot_snap")

#define kConfigString_publish_story_ttl_action_text \
ACCConfigKeyDefaultPair(@"story_v3_config.story_ttl_dialog_text", @"creation_edit_post_diary")

#define kConfigString_mv_1080p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_mv_resolution_config.1080p_mv_ve_synthesis_settings", @"")

#define kConfigString_mv_720p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_mv_resolution_config.720p_mv_ve_synthesis_settings", @"")

#define kConfigString_photo_to_video_1080p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_photos_resolution_config.1080p_photos_ve_synthesis_settings", @"")

#define kConfigString_photo_to_video_720p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_photos_resolution_config.720p_photos_ve_synthesis_settings", @"")

#define kConfigString_cut_same_1080p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_cut_same_resolution_config.1080p_cut_same_ve_synthesis_settings", @"")

#define kConfigString_cut_same_720p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_cut_same_resolution_config.720p_cut_same_ve_synthesis_settings", @"")

#define kConfigString_moments_1080p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_moments_resolution_config.1080p_moments_ve_synthesis_settings", @"")

#define kConfigString_moments_720p_bitrate \
ACCConfigKeyDefaultPair(@"acc_avtools_ios_moments_resolution_config.720p_moments_ve_synthesis_settings", @"")

#define kConfigString_fe_config_collection_music_faq_schema \
ACCConfigKeyDefaultPair(@"fe_config_collection.music_faq.schema", @"")

#define kConfigString_mv_decorator_resource \
ACCConfigKeyDefaultPair(@"aweme_activity_setting.mv_decorator_resource", @"")

#define kConfigString_effect_json_config \
ACCConfigKeyDefaultPair(@"effect_sdk_config_settings", @"")

#define kConfigString_publish_video_default_description \
ACCConfigKeyDefaultPair(@"video_description", @"")

#define kConfigString_edit_post_button_default_text \
ACCConfigKeyDefaultPair(@"creation_edit_post_direct_one_text", @"发日常")

#define kConfigString_disable_edit_next_toast \
ACCConfigKeyDefaultPair(@"story_v3_config.story_disable_edit_next", @"story_disable_edit_next")

#define kConfigString_super_entrance_effect_applyed_bubble_string \
ACCConfigKeyDefaultPair(@"acc_super_entrance_effect_applyed_bubble_string", @"")

#define kConfigString_static_canvas_photo_bitrate \
ACCConfigKeyDefaultPair(@"acc_static_canvas_photo_bitrate", @"")

#define kConfigString_dynamic_canvas_photo_bitrate \
ACCConfigKeyDefaultPair(@"acc_dynamic_canvas_photo_bitrate", @"")

#define kConfigString_meteor_mode_guide_url \
ACCConfigKeyDefaultPair(@"aweme_meteor_mode_guide_url", @"")

#define kConfigBool_white_lightning_shoot_button \
ACCConfigKeyDefaultPair(@"acc_white_lightning_shoot_button", @(NO))

#define kConfigBool_longtail_shoot_animation \
ACCConfigKeyDefaultPair(@"acc_longtail_shoot_animation", @(NO))

#define kConfigString_capture_authorization_help_url \
ACCConfigKeyDefaultPair(@"acc_capture_authorization_help_url", @"aweme://webview/?url=https%3A%2F%2Faweme.snssdk.com%2Ffalcon%2Frn_main_web%2Ffeedback%2Fdetail%3Fid%3D1258%26hide_nav_bar%3D1&hide_nav_bar=1")

// 中断续传弹窗文案
#define kConfigString_backup_popup_title \
ACCConfigKeyDefaultPair(@"awe_studio_backup_popup_title", @"确定")

// 技术开关 是否允许文字贴纸feed区交互(暂未配置在AB平台上,在观察几个版本后删除)
#define kConfigBool_enable_text_sticker_feed_interaction \
ACCConfigKeyDefaultPair(@"studio_text_sticker_feed_enable_interaction", @(YES))

// 技术开关 文字贴纸二期优化，(暂未配置在AB平台上,在观察几个版本后删除)
#define kConfigBool_enable_text_sticke_optimize \
ACCConfigKeyDefaultPair(@"studio_enable_text_sticke_optimize", @(YES))

#define kConfigString_scan_prop_id \
ACCConfigKeyDefaultPair(@"scan_prop_id", @"")

#define kConfigBool_can_show_album_on_scan_qr_code_page \
ACCConfigKeyDefaultPair(@"can_show_album_on_scan_qr_code_page", @(YES))

// Karaoke
#define kConfigBool_karaoke_enabled \
ACCConfigKeyDefaultPair(@"karaoke_enabled", @(NO))

// Karaoke Default Record Mode
#define kConfigInt_karaoke_record_default_mode \
ACCConfigKeyDefaultPair(@"karaoke_record_default_mode", @(0))

// Karaoke open original sound
#define kConfigBool_karaoke_use_original_sound \
ACCConfigKeyDefaultPair(@"karaoke_use_original_sound", @(NO))

// K歌开启智能领唱
#define kConfigBool_karaoke_open_oa_switch \
ACCConfigKeyDefaultPair(@"karaoke_open_oa_switch", @(NO))

// K歌-拍摄页选择可K音乐后展示跟唱
#define kConfigBool_karaoke_entrance_after_select_music \
ACCConfigKeyDefaultPair(@"karaoke_entrance_after_select_music", @(NO))

// K歌-使用快拍交互
#define kConfigBool_karaoke_use_lightning \
ACCConfigKeyDefaultPair(@"karaoke_use_lightning", @(NO))

// K歌-选择页支持搜索sug
#define kConfigBool_karaoke_enable_search_sug \
ACCConfigKeyDefaultPair(@"karaoke_enable_search_sug", @(YES))

// K歌-推荐tab使用大卡
#define kConfigBool_karaoke_recommend_use_big_card \
ACCConfigKeyDefaultPair(@"karaoke_recommend_use_big_card", @(YES))

// K歌-推荐tab自动播放
#define kConfigBool_karaoke_recommend_auto_play \
ACCConfigKeyDefaultPair(@"karaoke_recommend_auto_play", @(YES))

// K歌-选择页新UI
#define kConfigBool_karaoke_select_music_new_style \
ACCConfigKeyDefaultPair(@"karaoke_select_music_new_style", @(NO))

// K歌-展示合唱tab
#define kConfigBool_karaoke_show_duet_sing_tab \
ACCConfigKeyDefaultPair(@"karaoke_show_duet_sing_tab", @(NO))

// K歌-合唱tab使用单列
#define kConfigBool_karaoke_duet_sing_single_column \
ACCConfigKeyDefaultPair(@"karaoke_duet_sing_single_column", @(NO))

// K歌-合唱支持耳返
#define kConfigBool_karaoke_ios_duet_ear_back \
ACCConfigKeyDefaultPair(@"karaoke_ios_duet_ear_back", @(NO))

// 拍摄页长按支持扫一扫
#define kConfigBool_tools_record_support_scan_qr_code \
ACCConfigKeyDefaultPair(@"tools_record_support_scan_qr_code", @(NO))

#define kConfigString_tools_flower_activity_id \
ACCConfigKeyDefaultPair(@"tools_flower_activity_id", @"11282133")

// 开启合拍横屏视频布局优化
#define kConfigInt_duet_landscape_video_layout_type \
ACCConfigKeyDefaultPair(@"studio_record_duet_landscape_video_layout_type", @(0))

// 视频评论视频
#define kConfigInt_video_reply_sticker \
ACCConfigKeyDefaultPair(@"video_reply_sticker", @(0))

// 视频评论视频贴纸样式优化
#define kConfigInt_video_reply_sticker_type \
ACCConfigKeyDefaultPair(@"video_reply_sticker_type", @(0))

// 视频回复评论优化：发布后的Landing到评论区
#define kConfigBool_video_comment_stay_comment_after_publish \
ACCConfigKeyDefaultPair(@"video_comment_stay_comment_after_publish", @(NO))

// 视频回复评论二期：发布页新增“是否展示在我的作品中”设置
#define kConfigBool_comment_my_work_list_setting_ab \
ACCConfigKeyDefaultPair(@"comment_my_work_list_setting_ab", @(NO))

// 视频回复评论二期：视频回复评论发布页文案异化
#define kConfigBool_comment_reply_new_title \
ACCConfigKeyDefaultPair(@"comment_reply_new_title", @(NO))

// 视频回复评论二期：贴纸样式优化，1代表优化的贴纸样式一
#define kConfigInt_comment_sticker_type \
ACCConfigKeyDefaultPair(@"comment_sticker_type", @(1))

// 合拍应用默认道具fix，改为应用实际道具(技术开关暂未配置，后续无问题删除)
#define kConfigBool_duet_first_layout_optimize \
ACCConfigKeyDefaultPair(@"studio_record_duet_first_layout_optimize", @(YES))

// 合拍上下布局原视频在上model key(暂未配置，防止后续版本有改动)
#define kConfigString_duet_original_up_layout_model_key \
ACCConfigKeyDefaultPair(@"studio_record_duet_original_up_layout_model_key", @"new_down")

// 合拍上下布局原视频在下model key(暂未配置，防止后续版本有改动)
#define kConfigString_duet_original_down_layout_model_key \
ACCConfigKeyDefaultPair(@"studio_record_duet_original_down_layout_model_key", @"new_up")

// 合拍使用 API 检查权限
#define kConfigBool_duet_use_server_permission_check \
ACCConfigKeyDefaultPair(@"duet_use_server_permission_check", @NO)

// 音乐详情页分享到日常
#define kConfigBool_music_detail_enable_share_to_story \
ACCConfigKeyDefaultPair(@"studio_music_detail_enable_share_to_story", @(NO))

// 技术需求 音乐分享到日常资源后置下载
#define kConfigBool_music_story_enable_download_after_to_edit_page \
ACCConfigKeyDefaultPair(@"studio_music_story_enable_download_after_to_edit_page", @(NO))

// 音乐详情页分享到日常的按钮标题(暂未配置，后续可能会改)
#define kConfigString_music_detail_share_to_story_title \
ACCConfigKeyDefaultPair(@"studio_music_detail_share_to_story_title", @"分享到日常")

// 音乐详情页分享到日常的视频标题
#define kConfigString_music_detail_share_to_story_video_text \
ACCConfigKeyDefaultPair(@"studio_music_detail_share_to_story_video_text", @"#音乐心情")

// 音乐日常最大视频时长
#define kConfigDouble_music_detail_share_to_story_video_max_duration \
ACCConfigKeyDefaultPair(@"studio_music_detail_share_to_story_video_max_duration", @(0))

// 音乐日常最小视频时长
#define kConfigDouble_music_detail_share_to_story_video_min_duration \
ACCConfigKeyDefaultPair(@"studio_music_detail_share_to_story_video_min_duration", @(0))

// 音乐详情页分享到日常的封面切图资源名(暂未配置，防止后续可能会改)
#define kConfigString_music_story_cover_effect_image_resource_name \
ACCConfigKeyDefaultPair(@"studio_music_story_cover_effect_image_resource_name", @"single.png")

// 音乐详情页分享到日常的PGC封面effect资源(暂未配置，防止后续可能会改)
#define kConfigString_music_story_pgc_cover_effect_id \
ACCConfigKeyDefaultPair(@"studio_music_story_pgc_cover_effect_id", @"1140748")

// 音乐详情页分享到日常的UGC封面effect资源(暂未配置，防止后续可能会改)
#define kConfigString_music_story_ugc_cover_effect_id \
ACCConfigKeyDefaultPair(@"studio_music_story_ugc_cover_effect_id", @"1140750")

// 音乐详情页分享到日常的封面动画effect资源(暂未配置，防止后续可能会改)
#define kConfigString_music_story_cover_animation_effect_id \
ACCConfigKeyDefaultPair(@"studio_music_story_cover_animation_effect_id", @"1141098")

// 音乐详情页分享到日常的音乐歌词effect资源(暂未配置，防止后续可能会改)
#define kConfigString_music_story_lyrics_animation_effect_id \
ACCConfigKeyDefaultPair(@"studio_music_story_lyrics_effect_id", @"1140832")

// 发布前增加合拍权限设置
#define kConfigBool_add_duet_permission_before_publish \
ACCConfigKeyDefaultPair(@"add_duet_permission_before_publish", @(YES))

// 发布前合拍权限设置记住上次设置
#define kConfigBool_duet_permission_remember_last_settings \
ACCConfigKeyDefaultPair(@"duet_permission_remember_last_settings", @(NO))

// 发布前增加下载权限设置
#define kConfigBool_add_download_permission_before_publish \
ACCConfigKeyDefaultPair(@"add_download_permission_before_publish", @(YES))

// 发布前下载权限设置记住上次设置
#define kConfigBool_download_permission_remember_last_settings \
ACCConfigKeyDefaultPair(@"download_permission_remember_last_settings", @(NO))
// 使用EffectCam道具
#define kConfigBool_use_effect_cam_key \
ACCConfigKeyDefaultPair(@"acc_useEffectCamKey", @(NO))
// 使用其他业务线道具
#define kConfigBool_use_other_effect_access_key \
ACCConfigKeyDefaultPair(@"use_other_effect_access_key", @(NO))

// 离线视频重复上传
#define kConfigBool_publish_offline_video_skip_upload \
ACCConfigKeyDefaultPair(@"publish_offline_video_skip_upload", @(NO))

// 使用其他业务线道具 access Key
#define kConfigString_effect_input_accessKey \
ACCConfigKeyDefaultPair(@"input_access_key", @"")
// 使用线上模型环境
#define kConfigBool_use_online_algrithm_model_environment \
ACCConfigKeyDefaultPair(@"use_online_algrithm_model_environment", @(YES))

//放开相册上传限制
#define kConfigDict_album_upload_duration_limit \
ACCConfigKeyDefaultPair(@"album_upload_duration_limit", @(NO))

//放开相册上传视频时长限制
#define kConfigNum_album_upload_photo_ratio \
ACCConfigKeyDefaultPair(@"album_upload_photo_ratio", @0.0)

// @朋友接入aiLab推荐序
#define kConfigBool_post_at_ailab \
ACCConfigKeyDefaultPair(@"post_at_ailab", @(NO))

// @朋友使用缓存
#define kConfigBool_is_mention_cache_ailab_data \
ACCConfigKeyDefaultPair(@"is_mention_cache_ailab_data", @(NO))

// 相册启动优化
typedef NS_OPTIONS(NSUInteger, ACCAlbumLandingOptimizeType) {
    ACCAlbumLandingOptimizeTypeDisable = 0,
    ACCAlbumLandingOptimizeTypeLanding = 1 << 0,
    ACCAlbumLandingOptimizeTypeCache = 1 << 1,
    ACCAlbumLandingOptimizeTypeAll = ACCAlbumLandingOptimizeTypeLanding | ACCAlbumLandingOptimizeTypeCache
};

// 拍摄进优化
typedef NS_OPTIONS(NSUInteger, ACCRecordToEditOptimizeType) {
    ACCRecordToEditOptimizeTypeDisable = 0,
    ACCRecordToEditOptimizeTypeStopCapture = 1 << 0,
    ACCRecordToEditOptimizeTypePauseRecord = 1 << 1,
    ACCRecordToEditOptimizeTypeAll = ACCRecordToEditOptimizeTypeStopCapture | ACCRecordToEditOptimizeTypePauseRecord
};

#define kConfigInt_album_landing_optimize_type \
ACCConfigKeyDefaultPair(@"studio_album_landing_optimize", @(0))

// 编辑 NLE
#define kConfigBool_studio_edit_use_nle \
ACCConfigKeyDefaultPair(@"studio_edit_use_nle", @(NO))

// 固定单图videoSize，防止被误修改(线上已经出现多起发布后模糊以及拉伸等问题) 暂未配置，配个开关防止有其他影响
#define kConfigBool_enable_fixed_canvas_video_size \
ACCConfigKeyDefaultPair(@"studio_enable_fixed_canvas_video_size", @(YES))

// 单图画布视频发布优化(发布、保存为图片格式)
#define kConfigBool_enable_canvas_photo_publish_optimize \
ACCConfigKeyDefaultPair(@"studio_enable_canvas_to_image_album", @(NO))

#define kConfigBool_enable_canvas_photo_publish_optimize_text_sticker_add \
ACCConfigKeyDefaultPair(@"studio_enable_canvas_to_image_with_text_sticker_add", @(NO))


// 技术开关，aweme相关的埋点加上studio的埋点，默认YES，不会配，因为涉及埋点项比较多，防止有问题
#define kConfigBool_enable_aweme_track_add_studio_creation_info \
ACCConfigKeyDefaultPair(@"studio_enable_aweme_track_add_studio_creation_info", @(YES))

/// K 歌音频算法优化
#define kConfigBool_karaoke_record_audio_da \
ACCConfigKeyDefaultPair(@"karaoke_record_audio_da", @(NO))

#define kConfigBool_karaoke_record_audio_aec \
ACCConfigKeyDefaultPair(@"karaoke_record_audio_aec", @(NO))

#define kConfigBool_karaoke_record_audio_le \
ACCConfigKeyDefaultPair(@"karaoke_record_audio_le", @(NO))

/// 选音乐开麦音频算法优化
#define kConfigBool_music_record_audio_da \
ACCConfigKeyDefaultPair(@"music_record_audio_da", @(NO))

#define kConfigBool_music_record_audio_aec \
ACCConfigKeyDefaultPair(@"music_record_audio_aec", @(NO))

#define kConfigBool_music_record_audio_le \
ACCConfigKeyDefaultPair(@"music_record_audio_le", @(NO))

/// 合拍音频算法优化
#define kConfigBool_duet_record_audio_da \
ACCConfigKeyDefaultPair(@"duet_record_audio_da", @(NO))

/// 合唱音频算法优化
#define kConfigBool_duet_sing_record_audio_da \
ACCConfigKeyDefaultPair(@"duet_sing_record_audio_da", @(NO))

#define kConfigBool_duet_record_audio_aec \
ACCConfigKeyDefaultPair(@"duet_record_audio_aec", @(NO))

#define kConfigBool_duet_record_audio_le \
ACCConfigKeyDefaultPair(@"duet_record_audio_le", @(NO))

/// 直接开拍音频算法优化
#define kConfigBool_shoot_record_audio_le \
ACCConfigKeyDefaultPair(@"shoot_record_audio_le", @(NO))

#define kConfigInt_record_target_lufs \
ACCConfigKeyDefaultPair(@"record_target_lufs", @(0))

#define kConfigInt_edit_flower_test_tool \
ACCConfigKeyDefaultPair(@"edit_flower_test_tool", @(NO))

#define kConfigDic_flower_edit_red_packet_config \
ACCConfigKeyDefaultPair(@"tools_red_packet_settings", @{})

#define kConfigDic_flower_edit_red_packet_drill_config \
ACCConfigKeyDefaultPair(@"tools_red_packet_drill_settings", @{})

// ACCRecordCompleteComponent 不监听 pauseRecord，AB
#define kConfigBool_acc_complete_only_once \
ACCConfigKeyDefaultPair(@"acc_complete_only_once", @(-12))

// 是否开启单图导入loading黑帧优化
#define kConfigBool_single_photo_upload_optimization \
ACCConfigKeyDefaultPair(@"studio_single_photo_upload_optimization", @(NO))

// 是否开启转发到日常视频去除黑边功能
#define kConfigBool_enable_share_crop_black_area \
ACCConfigKeyDefaultPair(@"enable_share_crop_black_area", @(NO))

#define kConfigInt_record_to_edit_optimize_type \
ACCConfigKeyDefaultPair(@"studio_record_to_edit_optimize", @(0))

// 同城圈子：回答问题加圈的背景色和贴纸模版
#define kConfigArray_circle_templates \
ACCConfigKeyDefaultPair(@"circle_config.circle_templates", @[])

typedef NS_ENUM(NSUInteger, ACCVideoCreationUsingPlayerCache) {
    ACCVideoCreationUsingPlayerCacheNone = 0,
    ACCVideoCreationUsingPlayerCacheOld = 1, // 旧缓存代码，一次性
    ACCVideoCreationUsingPlayerCacheNew = 2, // 新缓存代码，一次性
    ACCVideoCreationUsingPlayerCacheWaitingResult = 3, // 新缓存代码，等待
};

#define kConfigInt_enable_video_creation_using_player_cache \
ACCConfigKeyDefaultPair(@"enable_video_creation_using_player_cache", @(ACCVideoCreationUsingPlayerCacheNone))


#define kConfigInt_autocaption_samplerate_config \
ACCConfigKeyDefaultPair(@"autocaption_samplerate_config", @(16))

#define kConfigInt_autocaption_bitrate_config \
ACCConfigKeyDefaultPair(@"autocaption_bitrate_config", @(0))

/// -------------------- 断点续传 --------------------
#define kConfigBool_enable_publish_when_net_weak \
ACCConfigKeyDefaultPair(@"enable_publish_when_net_weak",@NO)

#define kConfigBool_enable_resume_publish \
ACCConfigKeyDefaultPair(@"enable_resume_publish",@NO)

// 图集发布中重启APP后允许恢复重试,技术开关，观察几个版本
#define kConfigBool_enable_image_album_publish_persist_retry \
ACCConfigKeyDefaultPair(@"studio_enable_image_album_publish_persist_retry",@(YES))

typedef NS_ENUM(NSUInteger, ACCResumePublishToastStyle) {
    ACCResumePublishToastStyleLegacy = 0,
    ACCResumePublishToastStyleNew1 = 1,
    ACCResumePublishToastStyleNew2 = 2
};
#define kConfigInt_resume_publish_style \
ACCConfigKeyDefaultPair(@"resume_publish_style", @(ACCResumePublishToastStyleLegacy))

#define kConfigDouble_publish_fail_toast_display_duration \
ACCConfigKeyDefaultPair(@"publish_fail_toast_display_duration", @0)

#define kConfigDouble_publish_fail_toast_display_interval \
ACCConfigKeyDefaultPair(@"publish_fail_toast_display_interval", @0)
#define kConfigDouble_publish_progress_view_enable_cancel_interval \
ACCConfigKeyDefaultPair(@"publish_progress_view_enable_cancel_interval", @0)

#define kConfigDouble_publish_timeout \
ACCConfigKeyDefaultPair(@"publish_timeout", @0)

#define kConfigInt_publish_retry_limit \
ACCConfigKeyDefaultPair(@"publish_retry_limit", @20)

// IM相册编辑超长图片可能黑屏或崩溃,实验添加保护逻辑
#define kConfigInt_im_edit_long_picture_extension_horizontal \
ACCConfigKeyDefaultPair(@"im_edit_long_picture_extension_horizontal", @0)
/// -------------------- 断点续传 --------------------

// 拍照支持动图-总开关: 开启true，关闭false
#define kConfigBool_live_photo_enable \
ACCConfigKeyDefaultPair(@"live_photo_enable", @(NO))

// 拍照支持动图-tab位置: 0动图-拍照-拍视频，1拍照-动图-拍视频
typedef NS_ENUM(NSUInteger, ACCLivePhotoTabPosition) {
    ACCLivePhotoTabPositionLeft  = 0,
    ACCLivePhotoTabPositionRight = 1,
};
#define kConfigInt_live_photo_tab_position \
ACCConfigKeyDefaultPair(@"live_photo_tab_position", @(ACCLivePhotoTabPositionLeft))

// 拍照支持动图-视频时长: Int；10 10秒 ，16 16秒
#define kConfigInt_live_photo_video_duration \
ACCConfigKeyDefaultPair(@"live_photo_video_duration", @10)

// 拍照支持动图-录制时长: 1表示1秒
#define kConfigDouble_live_photo_record_duration \
ACCConfigKeyDefaultPair(@"live_photo_record_duration", @1.0)

// 拍照支持动图-拍帧间隔(ms): 30表示30ms
#define kConfigInt_live_photo_frames_per_duration \
ACCConfigKeyDefaultPair(@"live_photo_frames_per_duration", @30)

// 拍照支持动图-视频风格:
#define kConfigInt_live_photo_video_style \
ACCConfigKeyDefaultPair(@"live_photo_video_style", @1/*ACCLivePhotoTypeBoomerang*/)

// 小游戏/小程序投稿数据修复
#define kConfigBool_studio_enable_mprecord_da_fix \
ACCConfigKeyDefaultPair(@"studio_enable_mprecord_da_fix", @YES)

// 低端机降级
#define kConfigDict_biz_downgrade_config \
ACCConfigKeyDefaultPair(@"acc_biz_downgrade_config", @{})

#define kConfigBool_enable_editor_tags \
ACCConfigKeyDefaultPair(@"enable_edit_tag", @(NO))

typedef NS_ENUM(NSUInteger, ACCReEditPublishVideoStyle) {
    ACCReEditPublishVideoStyleLegacy = 0,
    ACCReEditPublishVideoStyle1 = 1,
    ACCReEditPublishVideoStyle2 = 2
};
#define kConfigInt_tools_reedit_publish_video_style \
ACCConfigKeyDefaultPair(@"tools_reedit_publish_video_style", @(ACCReEditPublishVideoStyleLegacy))

#define kConfigString_edit_aweme_bottom_hint \
ACCConfigKeyDefaultPair(@"edit_aweme_bottom_hint", @"每日最多修改1次，发布超过30天后不可修改")

#pragma mark - 同城反转实验 - Start

/// 同城本地投稿链路优化大反转实验
#define kConfigBool_nearby_publish_reverse \
ACCConfigKeyDefaultPair(@"acc_nearby_publish_reverse",@NO)

/// 同城tab大反转实验
#define kConfigBool_nearby_tab_reverse \
ACCConfigKeyDefaultPair(@"acc_nearby_tab_reverse",@NO)

/// 同城生活服务大反转实验
#define kConfigBool_nearby_life_service_reverse \
ACCConfigKeyDefaultPair(@"acc_life_service_reverse", @NO)

/// 同城全屏反转实验
#define kConfigBool_nearby_full_screen_reverse \
ACCConfigKeyDefaultPair(@"acc_nearby_full_screen_reverse", @NO)

#pragma mark - 同城反转实验 - End

/// 同城tab是否在底导航2tab位置
#define kConfigBool_nearby_in_second_tab \
ACCConfigKeyDefaultPair(@"acc_nearby_in_second_tab", @NO)

// 带poi投稿landing至同城
#define kConfigDict_poi_publish_landing_nearby \
ACCConfigKeyDefaultPair(@"poi_publish_landing_nearby", @{})

// 投稿优先landing到同城选项
#define kConfigBool_priority_nearby_local_expose \
ACCConfigKeyDefaultPair(@"priority_nearby_local_expose", @NO)

// 启动相机添加尾帧蒙层
#define kConfigBool_enable_cover_frame_when_start_capture \
ACCConfigKeyDefaultPair(@"enable_cover_frame_when_start_capture", @(NO))

// 草稿废弃资源清理
#define kConfigBool_studio_draft_resrouce_clean_optimize \
ACCConfigKeyDefaultPair(@"studio_draft_resrouce_clean_optimize", @YES)

//打开锚点通参解析逻辑
#define kConfigBool_studio_enable_commercial_anchor_parsing_entry \
ACCConfigKeyDefaultPair(@"studio_enable_commercial_anchor_parsing_entry", @YES)

#define kConfigString_effect_platform_channel \
ACCConfigKeyDefaultPair(@"effect_platform_channel", @"")

#define kConfigBool_delete_quick_story_backup_draft \
ACCConfigKeyDefaultPair(@"delete_quick_story_backup_draft", @YES)

#pragma mark - 拍摄器合拍合唱tab

// 合拍合唱页面入口文案
#define kConfigString_familiar_duet_sing_entry_text \
ACCConfigKeyDefaultPair(@"familiar_duet_sing_entry_text", @"合拍")

// 合拍合唱页面默认landing tab
typedef NS_ENUM(NSInteger, ACCDuetSingLadingTab) {
    ACCDuetSingLadingTabNone = 0,// 无合拍tab
    ACCDuetSingLadingTabDuetTab = 1,// landing合拍tab
    ACCDuetSingLadingTabSingTab = 2,// landing合唱tab
};
#define kConfigInt_familiar_duet_sing_default_landing_tab \
ACCConfigKeyDefaultPair(@"familiar_duet_sing_default_landing_tab", @(0))

// 合拍合唱页面展示视频类型
typedef NS_ENUM(NSInteger, ACCDuetSingVideoType) {
    ACCDuetSingVideoTypeOriginal = 0,// 合拍页面视频源为原视频
    ACCDuetSingVideoTypeDuet = 1,// 合拍页面视频源为合拍视频
};
#define kConfigInt_familiar_duet_sing_video_type_in_pool \
ACCConfigKeyDefaultPair(@"familiar_duet_sing_video_type_in_pool", @(0))

// 合唱页面投稿是否自动佩戴道具
#define kConfigBool_familiar_duet_sing_wear_sticker_auto \
ACCConfigKeyDefaultPair(@"familiar_duet_sing_wear_sticker_auto", @(NO))

// 发布重构二期
#define kConfigBool_tools_post_page_refactor_v2 \
ACCConfigKeyDefaultPair(@"tools_post_page_refactor_v2", @NO)

#define kConfigBool_tools_opt_image_album_and_input_cell \
ACCConfigKeyDefaultPair(@"tools_opt_image_album_and_input_cell", @NO)

#define kConfigBool_poi_tag_enable_global_search \
ACCConfigKeyDefaultPair(@"poi_tag_enable_global_search", @NO)

#define kConfigBool_poi_tag_enable_global_search \
ACCConfigKeyDefaultPair(@"poi_tag_enable_global_search", @NO)

#define kConfigBool_editor_tags_max_count_per_image \
ACCConfigKeyDefaultPair(@"editor_tags_max_count_per_image", @3)
#define kConfigBool_editor_tags_max_count_total \
ACCConfigKeyDefaultPair(@"editor_tags_max_count_total", @10)
#define kConfigInt_tag_custom_tag_length_limit \
ACCConfigKeyDefaultPair(@"tag_custom_tag_length_limit", @15)
#define kConfigArray_tag_creation_tab_order \
ACCConfigKeyDefaultPair(@"tag_creation_tab_order", @[])
#define kConfigBool_poi_tag_enable_global_search \
ACCConfigKeyDefaultPair(@"poi_tag_enable_global_search", @NO)

#define kConfigString_publish_page_video_default_description \
ACCConfigKeyDefaultPair(@"publish_page_video_default_description", @"")

#define kConfigBool_improve_video_quality_by_upload_speed \
ACCConfigKeyDefaultPair(@"improve_video_quality_by_upload_speed", @NO)

#define kConfigDouble_improve_video_quality_upload_speed_limit \
ACCConfigKeyDefaultPair(@"improve_video_quality_upload_speed_limit", @0)

#define kConfigArray_new_year_recommend_wish \
ACCConfigKeyDefaultPair(@"new_year_recommend_wish", @[])

#define kConfigDict_new_year_wish_default_font_setting \
ACCConfigKeyDefaultPair(@"new_year_wish_default_font_setting", @{})

// NLE AVAsset Optimization
#define kConfigBool_disable_nle_asset_optimization \
ACCConfigKeyDefaultPair(@"disable_nle_asset_optimization", @NO)

#define kConfigArray_improve_video_quality_upload_speed_settings \
ACCConfigKeyDefaultPair(@"improve_video_quality_upload_speed_settings", @[])

// 云相册总开关
#define kConfigBool_creation_cloud_album_enabled \
ACCConfigKeyDefaultPair(@"creation_cloud_album_enabled", @NO)
// 云相册文件上传限制
#define kConfigDict_creation_cloud_album_upload_file_limit \
ACCConfigKeyDefaultPair(@"creation_cloud_album_upload_file_limit", @{})

// 云相册紧急开关
#define kConfigDict_creation_cloud_album_emergency_switch \
ACCConfigKeyDefaultPair(@"creation_cloud_album_emergency_switch", @{})

// 云相册本息相册封面默认图
#define kConfigDict_creation_cloud_album_cover_use_default \
ACCConfigKeyDefaultPair(@"creation_cloud_album_cover_use_default", @NO)

// 云相册开通协议
#define kConfigDict_creation_cloud_album_agreement \
ACCConfigKeyDefaultPair(@"creation_cloud_album_agreement", @{})

// 云相册预览开关
#define kConfigBool_creation_cloud_album_detail_preview \
ACCConfigKeyDefaultPair(@"creation_cloud_album_detail_preview", @YES)

// 云相册作品页引导
#define kConfigBool_creation_cloud_album_show_top_tips \
ACCConfigKeyDefaultPair(@"creation_cloud_album_show_top_tips", @NO)

/// 编辑与发布页挽留弹窗样式
typedef NS_ENUM(NSUInteger, ACCRecordEditBegForStayPrompStyle) {
    ACCRecordEditBegForStayPrompStyleOnline = 0, // 线上样式，各场景自己判断
    ACCRecordEditBegForStayPrompStyleSheet = 1, // 底部弹窗
    ACCRecordEditBegForStayPrompStylePopover = 2, //气泡
    ACCRecordEditBegForStayPrompStyleAlert = 3 //中间弹窗
};
#define kConfigInt_creative_edit_record_beg_for_stay_prompt_style \
ACCConfigKeyDefaultPair(@"creative_edit_record_beg_for_stay_prompt_style", @(ACCRecordEditBegForStayPrompStyleOnline))

/// 发布与编辑页时，挽留弹窗的选项
typedef NS_OPTIONS(NSUInteger, ACCRecordEditBegForStayOption) {
    ACCRecordEditBegForStayOptionNone = 0, // 不显示
    ACCRecordEditBegForStayOptionReshoot = 1 << 0, //重新拍摄
    ACCRecordEditBegForStayOptionSaveDraft = 1 << 1, //存草稿
    ACCRecordEditBegForStayOptionQuickPublish = 1 << 2, // 发日常
};

/// 拍摄页挽留 需显示的选项
#define kConfigInt_creative_record_beg_for_stay_option \
ACCConfigKeyDefaultPair(@"creative_record_beg_for_stay_option", @(ACCRecordEditBegForStayOptionReshoot | ACCRecordEditBegForStayOptionQuickPublish))

/// 编辑页编辑前 (特殊场景：现网存在弹窗的场景下，特指mv、一键成片等) 需显示的选项
#define kConfigInt_creative_edit_before_editing_beg_for_stay_option_for_special \
ACCConfigKeyDefaultPair(@"creative_edit_before_editing_beg_for_stay_option_for_special", @(ACCRecordEditBegForStayOptionNone))

/// 编辑页编辑前 需显示的选项
#define kConfigInt_creative_edit_before_editing_beg_for_stay_option \
ACCConfigKeyDefaultPair(@"creative_edit_before_editing_beg_for_stay_option", @(ACCRecordEditBegForStayOptionNone))

/// 编辑页编辑后 需显示的选项
#define kConfigInt_creative_edit_after_editing_beg_for_stay_option \
ACCConfigKeyDefaultPair(@"creative_edit_after_editing_beg_for_stay_option", @(ACCRecordEditBegForStayOptionQuickPublish))

#define kConfigBool_enable_resume_upload_on_disk \
ACCConfigKeyDefaultPair(@"enable_resume_upload_on_disk", @NO)

#define kConfigBool_tools_remote_resource_fix_key \
ACCConfigKeyDefaultPair(@"tools_remote_resource_fix_key", @(YES))

#define kConfigBool_tools_flower_show_card_gather_entrance \
ACCConfigKeyDefaultPair(@"tools_flower_show_card_gather_entrance", @(YES))

// 发布页mention用户提示
#define kConfigString_mention_search_remind_setting \
ACCConfigKeyDefaultPair(@"mention_search_remind_setting", @"")

#endif /* ACCConfigKeyDefines_h */
