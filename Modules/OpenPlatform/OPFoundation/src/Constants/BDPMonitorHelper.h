//
//  BDPMonitorHelper.h
//  TTMonitor
//
//  Created by yinyuan on 2018/12/10.
//

/**
 *  端监控工具类，定义SDK常用的常量和帮助接口
 */

#ifndef BDPMonitorHelper_h
#define BDPMonitorHelper_h

//#import "BDPMonitorEvent.h"
#import "BDPTracingManager.h"
/*---------------------------------------------*/
//               定义 Event Name
/*---------------------------------------------*/
// event_name -> kEventName_event_name
#define BDP_DEFINE_EVENT_NAME(event_name) \
        static NSString * const kEventName_##event_name = @"" #event_name;
BDP_DEFINE_EVENT_NAME(mp_lib_update_request)                        // jssdk lib 更新请求
BDP_DEFINE_EVENT_NAME(mp_lib_download)                              // jssdk lib 下载
BDP_DEFINE_EVENT_NAME(mp_login_result)                              // 登陆接口监控
BDP_DEFINE_EVENT_NAME(mp_check_session_result)                      // checkSession 监控
BDP_DEFINE_EVENT_NAME(mp_user_info_result)                          // getUserInfo 监控
BDP_DEFINE_EVENT_NAME(mp_page_crash)                                // 页面crash及恢复监控
BDP_DEFINE_EVENT_NAME(mp_page_crash_overload)                       // 页面闪退重试次数超过限制（iOS：最多{BDPAppPageConsts.kReloadMaxCount}次）
BDP_DEFINE_EVENT_NAME(mp_set_storage_size)                          // setStorage size监控
BDP_DEFINE_EVENT_NAME(mp_save_file_size)                            // saveFile size监控
BDP_DEFINE_EVENT_NAME(mp_offline_zip_update)                        // offline zip 更新监控
BDP_DEFINE_EVENT_NAME(mp_modal_webview_load)                        // modal webview加载监控
BDP_DEFINE_EVENT_NAME(mp_custom_navigation_bar)                     // 自定义导航栏监控
BDP_DEFINE_EVENT_NAME(mp_h5_crash)                                  // h5小程序crash及恢复监控
BDP_DEFINE_EVENT_NAME(create_tmp_dir_result)                        // 小程序重启创建tmp目录结果

BDP_DEFINE_EVENT_NAME(mp_app_preload_start)                         // 预加载开始时
BDP_DEFINE_EVENT_NAME(mp_app_preload_result)                        // 预加载结束时
BDP_DEFINE_EVENT_NAME(mp_app_preload_release)                       // 预加载未利用被释放

BDP_DEFINE_EVENT_NAME(mp_app_launch_start)                          // 点击启动小程序时
BDP_DEFINE_EVENT_NAME(mp_app_launch_start_detail)                   // 启动小程序时进程内已经初始化就绪时，上报小程序启动相关的一些环境参数（尽量早）
BDP_DEFINE_EVENT_NAME(mp_app_container_start)                       // 小程序的容器(Activity/ViewController/React.Component)开始加载
BDP_DEFINE_EVENT_NAME(mp_app_container_loaded)                      // 小程序的容器(Activity/ViewController/Window)加载完成 ViewController init完成；
BDP_DEFINE_EVENT_NAME(mp_app_container_setuped)                     // 小程序容器中的view创建和初始化完成
BDP_DEFINE_EVENT_NAME(mp_app_launch_result)                         // 小程序加载完成时

/// meta开始请求
BDP_DEFINE_EVENT_NAME(mp_meta_request_start)
/// meta请求结果
BDP_DEFINE_EVENT_NAME(mp_meta_request_result)

BDP_DEFINE_EVENT_NAME(mp_install_update_start)                      // 安装/更新过程开始
BDP_DEFINE_EVENT_NAME(mp_load_meta_start)                           // 小程序开始加载meta（从网络或者缓存）
BDP_DEFINE_EVENT_NAME(mp_load_meta_result)                          // 小程序加载meta结束
BDP_DEFINE_EVENT_NAME(mp_load_package_start)                        // 小程序开始加载包（从网络或者缓存）
BDP_DEFINE_EVENT_NAME(mp_load_package_result)                       // 小程序加载包结束
BDP_DEFINE_EVENT_NAME(mp_install_update_result)                     // 安装/更新过程完成        

BDP_DEFINE_EVENT_NAME(mp_app_load_start)                            // 小程序开始加载（不包括下包）

BDP_DEFINE_EVENT_NAME(mp_jscore_load_start)                         // jscore开始创建
BDP_DEFINE_EVENT_NAME(mp_jscore_load_result)                        // jscore创建完成
BDP_DEFINE_EVENT_NAME(mp_jscore_lib_load_start)                     // jscore基础库开始加载
BDP_DEFINE_EVENT_NAME(mp_jscore_lib_load_result)                    // jscore基础库加载结束
BDP_DEFINE_EVENT_NAME(mp_jscore_app_load_start)                     // jscore小程序代码开始加载
BDP_DEFINE_EVENT_NAME(mp_jscore_app_load_result)                    // jscore app.js 代码执行完成
BDP_DEFINE_EVENT_NAME(mp_jscore_load_dom_ready)                     // jscore加载小程序代码前端onDocumentReady事件调用

BDP_DEFINE_EVENT_NAME(mp_webview_load_start)                        // webview开始创建
BDP_DEFINE_EVENT_NAME(mp_webview_load_result)                       // webview创建完成
BDP_DEFINE_EVENT_NAME(mp_webview_lib_load_start)                    // webview基础库开始加载
BDP_DEFINE_EVENT_NAME(mp_webview_lib_load_result)                   // webview基础库加载结束
BDP_DEFINE_EVENT_NAME(mp_webview_app_load_start)                    // webview 小程序代码开始加载（ page-frame.js）
BDP_DEFINE_EVENT_NAME(mp_webview_app_load_result)                   // webview page-frame.js load 完成的事件
BDP_DEFINE_EVENT_NAME(mp_webview_page_load_start)                   // webview 小程序页面代码开始加载（ ${path}-frame.js）
BDP_DEFINE_EVENT_NAME(mp_webview_page_load_result)                  // webview 小程序页面代码加载完成（ ${path}-frame.js）
BDP_DEFINE_EVENT_NAME(mp_webview_load_exception)                    // webview加载代码异常（可能不止一次）
BDP_DEFINE_EVENT_NAME(mp_webview_load_dom_ready)                    // webview DomReady

BDP_DEFINE_EVENT_NAME(mp_lifecycle_page_start)                      // 点击跳转页面事件
BDP_DEFINE_EVENT_NAME(mp_lifecycle_page_onready)                    // Page.onReady 事件

BDP_DEFINE_EVENT_NAME(mp_prefetch_config)                           // 记录prefetch的配置
BDP_DEFINE_EVENT_NAME(mp_request_start)                             // tt.request请求开始
BDP_DEFINE_EVENT_NAME(mp_request_result)                            // tt.request请求结束
BDP_DEFINE_EVENT_NAME(mp_request_upload_start)                      // createUploadTask请求开始
BDP_DEFINE_EVENT_NAME(mp_request_upload_result)                     // createUploadTask请求结束
BDP_DEFINE_EVENT_NAME(mp_request_download_start)                    // createDownloadTask请求开始
BDP_DEFINE_EVENT_NAME(mp_request_download_result)                   // createDownloadTask请求结束
BDP_DEFINE_EVENT_NAME(mp_socket_result)                             // connectSocket 建连成功或失败
BDP_DEFINE_EVENT_NAME(mp_api_request_prefetch_dev)                      // prefetch 埋点

BDP_DEFINE_EVENT_NAME(mp_blank_screen_close)                         // 非正常退出时需要清理热启动缓存
BDP_DEFINE_EVENT_NAME(mp_blank_screen_detect)                        // 非正常退出时白屏监测结果

BDP_DEFINE_EVENT_NAME(mp_app_event_link)                            // 专门用于串联多个trace_id 的事件
BDP_DEFINE_EVENT_NAME(op_h5_api_error)                              // H5应用API调用失败
BDP_DEFINE_EVENT_NAME(op_h5_api_auth)                               // H5应用API授权
BDP_DEFINE_EVENT_NAME(op_h5_launch_result)                          // H5启动结果
BDP_DEFINE_EVENT_NAME(op_h5_share_result)                           // H5分享结果
BDP_DEFINE_EVENT_NAME(op_h5_webview_error)                          // H5应用webview内部错误
BDP_DEFINE_EVENT_NAME(mp_share_start)                               // 小程序分享开始
BDP_DEFINE_EVENT_NAME(mp_share_result)                              // 小程序分享结束

BDP_DEFINE_EVENT_NAME(op_app_badge_report_node)                     // 调用应用角标 reportBadge 
BDP_DEFINE_EVENT_NAME(op_app_auth_setting)                          // 拉取auth数据

BDP_DEFINE_EVENT_NAME(op_api_invoke)                                // api链路埋点

BDP_DEFINE_EVENT_NAME(op_client_api_block_list_when_background)     // 小程序在后台时API积压埋点

BDP_DEFINE_EVENT_NAME(op_client_api_downgrade)                      // PluginManager不支持的API事件埋点

// 加埋点/改埋点请先前往表格添加 https://bytedance.feishu.cn/sheets/shtcnVgzvlB9QuJLhcuKuZdeMde#a294c8

/*---------------------------------------------*/
//              定义常用 Event Key
/*---------------------------------------------*/
// event_key -> kEventKey_event_key
#define BDP_DEFINE_EVENT_KEY(event_key) \
        static NSString * const kEventKey_##event_key = @"" #event_key;

BDP_DEFINE_EVENT_KEY(app_id)                                        // app id
BDP_DEFINE_EVENT_KEY(app_type)                                      // app_type
BDP_DEFINE_EVENT_KEY(identifier)                                    // identifier
BDP_DEFINE_EVENT_KEY(block_id)                                      // block_id
BDP_DEFINE_EVENT_KEY(block_host)                                    // block_host
BDP_DEFINE_EVENT_KEY(api_name)                                      // api_name
BDP_DEFINE_EVENT_KEY(use_merge_js_sdk)                              // use_merge_js_sdk

BDP_DEFINE_EVENT_KEY(application_id)                                // application id
BDP_DEFINE_EVENT_KEY(card_id)                                       // card id
BDP_DEFINE_EVENT_KEY(app_ids)                                       // app ids
BDP_DEFINE_EVENT_KEY(card_ids)                                      // card ids
BDP_DEFINE_EVENT_KEY(identifiers)                                   // identifiers
BDP_DEFINE_EVENT_KEY(app_name)                                      // app name
BDP_DEFINE_EVENT_KEY(app_version)                                   // app version（包版本）
BDP_DEFINE_EVENT_KEY(application_version)                           // application version（应用版本）
BDP_DEFINE_EVENT_KEY(compile_version)                               // compile version
BDP_DEFINE_EVENT_KEY(trace_id)                                      // trace id
BDP_DEFINE_EVENT_KEY(pkg_url)                                       // URL to download package
BDP_DEFINE_EVENT_KEY(error_code)                                    // error_code
BDP_DEFINE_EVENT_KEY(error_msg)                                     // error_msg
BDP_DEFINE_EVENT_KEY(time)                                          // time
BDP_DEFINE_EVENT_KEY(method)                                        // method
BDP_DEFINE_EVENT_KEY(package_name)                                  // package_name
BDP_DEFINE_EVENT_KEY(js_version)                                    // jssdk version
BDP_DEFINE_EVENT_KEY(js_grey_hash)                                  // jssdk grey_hash
BDP_DEFINE_EVENT_KEY(scene)                                         // scene
BDP_DEFINE_EVENT_KEY(scene_type)                                         // scene_type
BDP_DEFINE_EVENT_KEY(sub_scene)                                     // sub_scene
BDP_DEFINE_EVENT_KEY(version_type)                                  // version_type
BDP_DEFINE_EVENT_KEY(new_container)                                 // 是否是新容器(新容器全量上线后删除)
BDP_DEFINE_EVENT_KEY(evn_type)                                      // evn_type
BDP_DEFINE_EVENT_KEY(net_status)                                    // net_status
BDP_DEFINE_EVENT_KEY(is_buildin)                                    // is_buildin

// 自定义 Event key
BDP_DEFINE_EVENT_KEY(result_type)
BDP_DEFINE_EVENT_KEY(request_id)
BDP_DEFINE_EVENT_KEY(js_engine_type)
//  加载类型
BDP_DEFINE_EVENT_KEY(load_type)

//  meta
BDP_DEFINE_EVENT_KEY(meta)


/*---------------------------------------------*/
//              定义常用 Event Value
/*---------------------------------------------*/
// event_value -> kEventKey_event_value
#define BDP_DEFINE_EVENT_VALUE(event_value) \
        static NSString * const kEventValue_##event_value = @"" #event_value;
BDP_DEFINE_EVENT_VALUE(success)                                     // 成功
BDP_DEFINE_EVENT_VALUE(fail)                                        // 失败
BDP_DEFINE_EVENT_VALUE(timeout)                                     // 超时



#endif /* BDPMonitorHelper_h */
