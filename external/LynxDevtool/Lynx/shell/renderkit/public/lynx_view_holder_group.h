// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_GROUP_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_GROUP_H_

#include <Windows.h>

#include <list>
#include <memory>
#include <string>
#include <unordered_map>

#include "lynx_export.h"
#include "lynx_view_holder.h"

namespace lynx {

class __declspec(dllexport) LynxViewHolderGroup : public LynxViewHolderClient {
 public:
  LynxViewHolderGroup() {}
  ~LynxViewHolderGroup() { Clear(); }

  void Open(const std::string& url) {
    auto it = lynx_view_holder_map_.find(url);
    if (it != lynx_view_holder_map_.end() && it->second != nullptr) {
      auto* holder = it->second;
      holder->Show();
      current_lynx_view_holder_ = holder;
      return;
    }
    auto* lynx_view_holder = new LynxViewHolder();
    lynx_view_holder->AddLynxViewHolderClient(this);
    lynx_view_holder_map_.emplace(url, lynx_view_holder);
    current_lynx_view_holder_ = lynx_view_holder;
  }

  void Close(const std::string& url) {
    auto it = lynx_view_holder_map_.find(url);
    if (it != lynx_view_holder_map_.end()) {
      auto* holder = it->second;
      if (holder == current_lynx_view_holder_) {
        current_lynx_view_holder_ = nullptr;
      }
      delete holder;
      lynx_view_holder_map_.erase(it);
    }
  }

  void Show(const std::string& url) {
    auto* holder = GetLynxViewHolder(url);
    if (holder) {
      holder->Show();
    }
  }

  void Hide(const std::string& url) {
    auto* holder = GetLynxViewHolder(url);
    if (holder) {
      holder->Hide();
    }
  }

  void Clear() {
    current_lynx_view_holder_ = nullptr;
    for (auto& value : lynx_view_holder_map_) {
      delete value.second;
    }
    lynx_view_holder_map_.clear();
  }

  bool Exist(const lynx::LynxView* lynx_view) {
    LynxViewHolder* lynx_view_holder = GetLynxViewHolder(lynx_view);
    return lynx_view_holder ? true : false;
  }

  bool Exist(const lynx::LynxViewHolder* holder) {
    for (auto& iter : lynx_view_holder_map_) {
      if (iter.second == holder) {
        return true;
      }
    }
    return false;
  }

  LynxViewHolder* GetLynxViewHolder(const std::string& url) {
    auto it = lynx_view_holder_map_.find(url);
    if (it != lynx_view_holder_map_.end()) {
      return it->second;
    }
    return nullptr;
  }

  LynxViewHolder* GetLynxViewHolder(const lynx::LynxView* lynx_view) {
    for (auto& iter : lynx_view_holder_map_) {
      auto* holder = iter.second;
      if (holder && holder->GetLynxView() == lynx_view) {
        return holder;
      }
    }

    return nullptr;
  }

  LynxViewHolder* GetCurrentLynxViewHolder() {
    return current_lynx_view_holder_;
  }

  void AddLynxViewHolderClient(LynxViewHolderClient* client) {
    client_list_.push_back(client);
  }
  void RemoveLynxViewHolderGroupClient(LynxViewHolderClient* client) {
    client_list_.remove(client);
  }

  virtual void OnPageStart(LynxViewHolder* lynx_view_holder,
                           const std::string& url) override {
    for (auto& client : client_list_) {
      client->OnPageStart(lynx_view_holder, url);
    }
  }

  void onLoadSuccess(LynxViewHolder* lynx_view_holder) override {
    for (auto& client : client_list_) {
      client->onLoadSuccess(lynx_view_holder);
    }
  }

  void onFirstScreen(LynxViewHolder* lynx_view_holder) override {
    for (auto& client : client_list_) {
      client->onFirstScreen(lynx_view_holder);
    }
  }

  void OnDestroy(LynxViewHolder* lynx_view_holder) override {
    for (auto& client : client_list_) {
      client->OnDestroy(lynx_view_holder);
    }
  }

  void OnRuntimeReady(LynxViewHolder* lynx_view_holder) override {
    for (auto& client : client_list_) {
      client->OnRuntimeReady(lynx_view_holder);
    }
  }

  void onErrorOccurred(LynxViewHolder* lynx_view_holder, int32_t error_code,
                       const std::string& message) override {
    for (auto& client : client_list_) {
      client->onErrorOccurred(lynx_view_holder, error_code, message);
    }
  }

  void onReceivedError(LynxViewHolder* lynx_view_holder, int32_t error_code,
                       const std::string& message) override {
    for (auto& client : client_list_) {
      client->onReceivedError(lynx_view_holder, error_code, message);
    }
  }

  void OnFirstLoadPerfReady(
      LynxViewHolder* lynx_view_holder,
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {
    for (auto& client : client_list_) {
      client->OnFirstLoadPerfReady(lynx_view_holder, perf, perf_timing);
    }
  }

 private:
  LynxViewHolder* current_lynx_view_holder_ = nullptr;
  std::unordered_map<std::string, LynxViewHolder*> lynx_view_holder_map_{};
  std::list<LynxViewHolderClient*> client_list_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_VIEW_HOLDER_GROUP_H_
