// Copyright 2021 The Lynx Authors. All rights reserved
#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_CLIENT_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_CLIENT_H_

#include <string>
#include <unordered_map>

#include "lynx_export.h"

namespace lynx {

class LynxViewBase;
class LynxViewHolder;

// align with lynxViewClient
class LYNX_EXPORT LynxViewHolderClient {
 public:
  virtual ~LynxViewHolderClient() = default;

  /**
   * 页面开始准备加载
   * @param url 页面链接
   */
  virtual void OnPageStart(LynxViewHolder* lynx_view_holder,
                           const std::string& url) = 0;

  /**
   * 页面加载成功
   */
  virtual void onLoadSuccess(LynxViewHolder* lynx_view_holder) = 0;

  /**
   * 首屏 layout 完成
   */
  virtual void onFirstScreen(LynxViewHolder* lynx_view_holder) = 0;

  virtual void OnDestroy(LynxViewHolder* lynx_view_holder) = 0;

  /**
   * 通知 JS Runtime 初始化完成
   */
  virtual void OnRuntimeReady(LynxViewHolder* lynx_view_holder) = 0;

  virtual void onErrorOccurred(LynxViewHolder* lynx_view_holder,
                               int32_t error_code,
                               const std::string& message) = 0;

  virtual void onReceivedError(LynxViewHolder* lynx_view_holder,
                               int32_t error_code,
                               const std::string& message) = 0;

  /**
   * 首次加载完成之后的性能数据统计完成回调。
   * NOTE：回调时机由于渲染线程的差别，不固定，不应作为任何业务方的打点起始点。
   * 回调位于主线程。
   */
  virtual void OnFirstLoadPerfReady(
      LynxViewHolder* lynx_view_holder,
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) = 0;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_CLIENT_H_
