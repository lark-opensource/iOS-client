// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_H_

#include <Windows.h>

#include <fstream>
#include <list>
#include <string>
#include <unordered_map>
#include <vector>

#include "lynx_export.h"
#include "lynx_view.h"
#include "lynx_view_base.h"
#include "lynx_view_client.h"
#include "lynx_view_holder_client.h"

namespace lynx {
class LynxViewBase;

class __declspec(dllexport) LynxViewHolder : LynxViewClient {
 public:
  virtual ~LynxViewHolder() {
    if (lynx_view_) {
      lynx::DestroyLynxView(static_cast<LynxView*>(lynx_view_));
      lynx_view_ = nullptr;
    }
  }

  std::vector<uint8_t> LoadFileData(std::string_view path) {
    auto stream = std::ifstream{path.data(), std::ios::binary};
    if (stream.fail()) {
      return {};
    }
    std::vector<uint8_t> buf((std::istreambuf_iterator<char>(stream)),
                             (std::istreambuf_iterator<char>()));

    stream.close();
    return buf;
  }

  void Init(RECT rect, float dpi) {
    UpdateDpi(dpi);
    LynxViewBaseBuilderCallback callback = [&](LynxViewBaseBuilder* builder) {
      builder->rect = LynxRect{
          0.f, 0.f, static_cast<float>((rect.right - rect.left) / dpi_),
          static_cast<float>((rect.bottom - rect.top) / dpi_)};
      builder->screenSize.cx = (rect.right - rect.left) / dpi_;
      builder->screenSize.cy = (rect.bottom - rect.top) / dpi_;
    };
    InitWithCallback(rect, callback, dpi, "");
  }

  void InitWithCallback(RECT rect, LynxViewBaseBuilderCallback callback,
                        float dpi, const std::string& global_prop) {
    UpdateDpi(dpi);
    lynx_view_ = lynx::CreateLynxView();

    if (global_prop.empty()) {
      auto default_global_prop = R"({appid:"appid",})";
      lynx_view_->SetGlobalPropsData(default_global_prop);
    } else {
      lynx_view_->SetGlobalPropsData(global_prop);
    }

    static_cast<LynxView*>(lynx_view_)->InitWithBuilder(callback);

    SetWindowSize(rect);
    SetFrameSize(rect);

    lynx_view_->AddLynxViewBaseClient(this);
  }

  void SetBaseUri(const std::string& base_uri) {
    if (lynx_view_) {
      lynx_view_->SetBaseURI(base_uri);
    }
  }

  void SetGlobalPropsData(const std::string& global_prop) {
    if (lynx_view_) {
      lynx_view_->SetGlobalPropsData(global_prop);
    }
  }

  float GetDpi() const { return dpi_; }

  void SetParent(HWND hwnd) {
    if (!lynx_view_) {
      return;
    }

    if (IsWindow(hwnd)) {
      hwnd_ = hwnd;
      ::SetParent(static_cast<LynxView*>(lynx_view_)->GetNativeWindow(), hwnd);
    }
  }

  void Show() {
    is_show_ = true;
    SetFocus();
    static_cast<LynxView*>(lynx_view_)->Show(true);
    lynx_view_->OnEnterForeground();
  }

  void Hide() {
    is_show_ = false;
    static_cast<LynxView*>(lynx_view_)->Show(false);
  }

  void SetFrameSize(RECT rect) {
    if (!lynx_view_) return;

    MoveWindow(static_cast<LynxView*>(lynx_view_)->GetNativeWindow(), rect.left,
               rect.top, rect.right - rect.left, rect.bottom - rect.top, true);

    lynx_view_->SetLayoutWidthMode(
        lynx::LynxViewBaseSizeMode::LynxViewBaseSizeModeExact);
    lynx_view_->SetLayoutHeightMode(
        lynx::LynxViewBaseSizeMode::LynxViewBaseSizeModeExact);
    lynx_view_->SetPreferredLayoutWidth((rect.right - rect.left) / GetDpi());
    lynx_view_->SetPreferredLayoutHeight((rect.bottom - rect.top) / GetDpi());
    lynx_view_->SetFrame((rect.right - rect.left) / GetDpi(),
                         (rect.bottom - rect.top) / GetDpi());
  }

  void LoadTemplate(const std::vector<uint8_t>& source,
                    const std::string& uri) {
    if (!lynx_view_) {
      return;
    }
    uri_ = uri;
    lynx_view_->LoadTemplate(source, uri_);
  }

  const std::string& GetUri() const { return uri_; }

  HWND SetFocus() {
    return ::SetFocus(static_cast<LynxView*>(lynx_view_)->GetNativeWindow());
  }

  void SetWindowSize(RECT rect) {
    if (!lynx_view_) return;

    rect.left /= dpi_;
    rect.right /= dpi_;
    rect.top /= dpi_;
    rect.bottom /= dpi_;
    lynx_view_->UpdateScreenMetrics(rect.right - rect.left,
                                    rect.bottom - rect.top, 1.f);
    lynx_view_->TriggerLayout();
  }

  void* GetLynxView() { return (void*)(lynx_view_); }

  void OnEnterBackground() {
    if (!lynx_view_) return;
    lynx_view_->OnEnterBackground();
  }

  void OnEnterForeground() {
    if (!lynx_view_) return;
    lynx_view_->OnEnterForeground();
  }

  void SendGlobalEvent(const std::string& name,
                       const std::string& json_params) {
    if (lynx_view_) {
      lynx_view_->SendGlobalEvent(name, json_params);
    }
  }

  void SendGlobalEvent(const std::string& name, const EncodableList& params) {
    if (lynx_view_) {
      lynx_view_->SendGlobalEvent(name, params);
    }
  }

  void UpdateDataWithString(const std::string& data) {
    if (lynx_view_) {
      lynx_view_->UpdateDataWithString(data);
    }
  }

  void RequestLayoutWhenSafepointEnable() {
    if (lynx_view_) {
      lynx_view_->RequestLayoutWhenSafepointEnable();
    }
  }

  void UpdateScreenMetrics(float width, float height, float device_ratio) {
    if (lynx_view_) {
      lynx_view_->UpdateScreenMetrics(width, height, device_ratio);
    }
  }
  void UpdateFontScale(float scale) {
    if (lynx_view_) {
      lynx_view_->UpdateFontScale(scale);
    }
  }

  bool IsShow() { return is_show_; }

  void UpdateDpi(float dpi) {
    if (dpi != dpi_) {
      dpi_ = dpi;
    }
  }

  void AddLynxViewHolderClient(LynxViewHolderClient* client) {
    if (client) {
      lynx_view_holder_client_list.push_back(client);
    }
  }

  void RemoveLynxViewHolderClient(LynxViewHolderClient* client) {
    if (client) {
      lynx_view_holder_client_list.remove(client);
    }
  }

  /**
   * 页面开始准备加载
   * @param url 页面链接
   */
  void OnPageStart(const std::string& url) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->OnPageStart(this, url);
    }
  }

  /**
   * 页面加载成功
   */
  void onLoadSuccess() override {
    for (auto* client : lynx_view_holder_client_list) {
      client->onLoadSuccess(this);
    }
  }

  /**
   * 首屏 layout 完成
   */
  void onFirstScreen() override {
    for (auto* client : lynx_view_holder_client_list) {
      client->onFirstScreen(this);
    }
  }

  /**
   * 通知 JS Runtime 初始化完成
   */
  void OnRuntimeReady(LynxViewBase* lynx_view) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->OnRuntimeReady(this);
    }
  }

  void OnDestroy(LynxViewBase* lynx_view) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->OnDestroy(this);
    }
  }

  void onErrorOccurred(int32_t error_code,
                       const std::string& message) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->onErrorOccurred(this, error_code, message);
    }
  }

  void onReceivedError(int32_t error_code,
                       const std::string& message) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->onReceivedError(this, error_code, message);
    }
  }

  /**
   * 首次加载完成之后的性能数据统计完成回调。
   * NOTE：回调时机由于渲染线程的差别，不固定，不应作为任何业务方的打点起始点。
   * 回调位于主线程。
   */
  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {
    for (auto* client : lynx_view_holder_client_list) {
      client->OnFirstLoadPerfReady(this, perf, perf_timing);
    }
  }

 private:
  float dpi_ = 1.f;
  HWND hwnd_;
  std::string uri_;
  bool is_show_ = false;
  LynxViewBase* lynx_view_ = nullptr;
  std::list<LynxViewHolderClient*> lynx_view_holder_client_list;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_H_
