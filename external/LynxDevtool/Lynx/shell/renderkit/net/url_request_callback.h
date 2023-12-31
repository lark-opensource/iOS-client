// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_NET_URL_REQUEST_CALLBACK_H_
#define LYNX_SHELL_RENDERKIT_NET_URL_REQUEST_CALLBACK_H_

// Cronet sample is expected to be used outside of Chromium infrastructure,
// and as such has to rely on STL directly instead of //base alternatives.
#include <future>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "third_party/ttnet/include/cronet_c.h"
namespace lynx {
enum class TTNetFinishStatus { CANCLED, FAIL, SUCCEED, OTHER };

class RequestCallbackListener {
 public:
 private:
  std::function<void(const std::string&, TTNetFinishStatus)> on_finished_ =
      nullptr;

 public:
  void SetOnFinishedFunc(
      const std::function<void(const std::string&, TTNetFinishStatus)>& func) {
    on_finished_ = func;
  }

  RequestCallbackListener(
      const std::function<void(const std::string&, TTNetFinishStatus)>&
          on_finished) {
    on_finished_ = on_finished;
  }
  RequestCallbackListener() = default;
  ~RequestCallbackListener() = default;
  void OnSucceed(const std::string& result) {
    if (on_finished_) {
      on_finished_(result, TTNetFinishStatus::SUCCEED);
    }
  }

  void OnFailed(const std::string& error_code) {
    if (on_finished_) {
      on_finished_(error_code, TTNetFinishStatus::FAIL);
    }
  }

  void OnCanceled(const std::string& cancel_info) {
    if (on_finished_) {
      on_finished_(cancel_info, TTNetFinishStatus::CANCLED);
    }
  }
};

// Sample implementation of Cronet_UrlRequestCallback interface using static
// methods to map C API into instance of C++ class.
class UrlRequestCallback {
 public:
  UrlRequestCallback();
  ~UrlRequestCallback();

  // Gets Cronet_UrlRequestCallbackPtr implemented by |this|.
  Cronet_UrlRequestCallbackPtr GetUrlRequestCallback() const;

  // Waits until request is done.
  void WaitForDone() { is_done_.wait(); }
  void SetListener(std::shared_ptr<RequestCallbackListener> listener) {
    listener_ = std::move(listener);
  }
  // Returns error message if OnFailed callback is invoked.
  std::string last_error_message() const { return last_error_message_; }
  // Returns string representation of the received response.
  std::string response_as_string() const { return response_as_string_; }

  void SetSync(bool flag) { sync_io_ = flag; }

 protected:
  void OnRedirectReceived(Cronet_UrlRequestPtr request,
                          Cronet_UrlResponseInfoPtr info,
                          Cronet_String newLocationUrl);

  void OnResponseStarted(Cronet_UrlRequestPtr request,
                         Cronet_UrlResponseInfoPtr info);

  void OnReadCompleted(Cronet_UrlRequestPtr request,
                       Cronet_UrlResponseInfoPtr info, Cronet_BufferPtr buffer,
                       uint64_t bytes_read);

  void OnSucceeded(Cronet_UrlRequestPtr request,
                   Cronet_UrlResponseInfoPtr info);

  void OnFailed(Cronet_UrlRequestPtr request, Cronet_UrlResponseInfoPtr info,
                Cronet_ErrorPtr error);
  void OnCanceled(Cronet_UrlRequestPtr request, Cronet_UrlResponseInfoPtr info);

  void SignalDone(bool success) { done_with_success_.set_value(success); }

  static UrlRequestCallback* GetThis(Cronet_UrlRequestCallbackPtr self);

  // Implementation of Cronet_UrlRequestCallback methods.
  static void OnRedirectReceived(Cronet_UrlRequestCallbackPtr self,
                                 Cronet_UrlRequestPtr request,
                                 Cronet_UrlResponseInfoPtr info,
                                 Cronet_String newLocationUrl);

  static void OnResponseStarted(Cronet_UrlRequestCallbackPtr self,
                                Cronet_UrlRequestPtr request,
                                Cronet_UrlResponseInfoPtr info);

  static void OnReadCompleted(Cronet_UrlRequestCallbackPtr self,
                              Cronet_UrlRequestPtr request,
                              Cronet_UrlResponseInfoPtr info,
                              Cronet_BufferPtr buffer, uint64_t bytesRead);

  static void OnSucceeded(Cronet_UrlRequestCallbackPtr self,
                          Cronet_UrlRequestPtr request,
                          Cronet_UrlResponseInfoPtr info);

  static void OnFailed(Cronet_UrlRequestCallbackPtr self,
                       Cronet_UrlRequestPtr request,
                       Cronet_UrlResponseInfoPtr info, Cronet_ErrorPtr error);

  static void OnCanceled(Cronet_UrlRequestCallbackPtr self,
                         Cronet_UrlRequestPtr request,
                         Cronet_UrlResponseInfoPtr info);

  // Error message copied from |error| if OnFailed callback is invoked.
  std::string last_error_message_;
  // Accumulated string representation of the received response.
  std::string response_as_string_;
  // Promise that is set when request is done.
  std::promise<bool> done_with_success_;
  // Future that is signalled when request is done.
  std::future<bool> is_done_ = done_with_success_.get_future();
  std::shared_ptr<RequestCallbackListener> listener_;
  Cronet_UrlRequestCallbackPtr const callback_;
  bool sync_io_ = true;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_NET_URL_REQUEST_CALLBACK_H_
