//
//  EMAMonitorHelper.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/3/3.
//

#ifndef EMAMonitorHelper_h
#define EMAMonitorHelper_h

#import "BDPMonitorHelper.h"

/*---------------------------------------------*/
//                  常用帮助函数
/*---------------------------------------------*/


/*---------------------------------------------*/
//               定义 Event Name
/*---------------------------------------------*/
// event_name -> kEventName_event_name
BDP_DEFINE_EVENT_NAME(mp_engine_start)                              // 引擎启动时（如果有账户/租户切换应当清理环境并重新启动）
BDP_DEFINE_EVENT_NAME(mp_engine_stop)                               // 引擎退出时（账户退出/切换/切换租户会触发）
BDP_DEFINE_EVENT_NAME(ema_image_preview)                            // 图片预览
BDP_DEFINE_EVENT_NAME(mp_about)                                     // 关于
BDP_DEFINE_EVENT_NAME(mp_enter_chat)                                // 进入聊天页成功率 监控
BDP_DEFINE_EVENT_NAME(mp_enter_profile)                             // 进入个人页成功率 监控
BDP_DEFINE_EVENT_NAME(mp_enter_bot)                                 // 进入Bot页成功率 监控
BDP_DEFINE_EVENT_NAME(mp_organization_api_invoke)                   // 调用组织权限api 监控
BDP_DEFINE_EVENT_NAME(mp_amap_location)                             // 高德定位SDK成功率
BDP_DEFINE_EVENT_NAME(mp_db_merge)                                  // DB迁移监控，迁移完成后可移除
BDP_DEFINE_EVENT_NAME(mp_fetch_openid)                              // 通过larkID获取openID
BDP_DEFINE_EVENT_NAME(mp_fetch_openchatid)                          // 通过chatID获取openChatID
BDP_DEFINE_EVENT_NAME(mp_push_meta_hit)                             // meta更新push命中率成功率
BDP_DEFINE_EVENT_NAME(mp_update_config)                             // updateConfig接口监控
BDP_DEFINE_EVENT_NAME(mp_check_session)                             // checkSession接口监控
BDP_DEFINE_EVENT_NAME(mp_sync_client_auth)                          // 同步用户个人资源授权信息接口监控
BDP_DEFINE_EVENT_NAME(mp_app_launch_detail)                         // 启动全流程埋点
BDP_DEFINE_EVENT_NAME(mp_launch_package_result)                     // 启动新包率埋点
BDP_DEFINE_EVENT_NAME(mp_report_analytics)                          // reportAnalytics 接口

/*---------------------------------------------*/
//              定义常用 Event Key
/*---------------------------------------------*/
// event_key -> kEventKey_event_key
BDP_DEFINE_EVENT_KEY(context_id)                                    // context_id
BDP_DEFINE_EVENT_KEY(user_id)                                       // user_id
BDP_DEFINE_EVENT_KEY(tenant_id)                                     // tenant_id


/*---------------------------------------------*/
//              定义常用 Event Value
/*---------------------------------------------*/
// event_value -> kEventKey_event_value
// 多媒体相关
BDP_DEFINE_EVENT_NAME(op_api_choose_image)                          // 选择图片
BDP_DEFINE_EVENT_NAME(op_api_choose_video)                          // 选择视频
BDP_DEFINE_EVENT_NAME(op_api_preview_image)                         // 预览图片
BDP_DEFINE_EVENT_NAME(op_api_compress_image)                        // 压缩图片
BDP_DEFINE_EVENT_NAME(op_api_get_image_info)                        // 获取图片信息
BDP_DEFINE_EVENT_NAME(op_api_save_image)                            // 保存图片
BDP_DEFINE_EVENT_NAME(op_api_save_video)                            // 保存视频
BDP_DEFINE_EVENT_NAME(op_api_get_trigger_code)                      // 获取triggerCode
BDP_DEFINE_EVENT_NAME(op_api_send_card)                             // 发送卡片
BDP_DEFINE_EVENT_NAME(op_api_get_block_source_detail)               // 获取blockSourceDetail


#endif /* EMAMonitorHelper_h */
