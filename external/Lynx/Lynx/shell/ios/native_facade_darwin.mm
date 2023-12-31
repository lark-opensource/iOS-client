// Copyright 2020 The Lynx Authors. All rights reserved.

#import "shell/ios/native_facade_darwin.h"
#import "LynxLog.h"
#import "LynxPerformance.h"
#import "tasm/react/ios/lepus_value_converter.h"

#include "base/float_comparison.h"
#include "base/perf_collector.h"
#include "base/string/string_utils.h"
#include "tasm/react/ios/prop_bundle_darwin.h"

#include "jsbridge/ios/lepus/lynx_lepus_module_darwin.h"
#include "jsbridge/ios/piper/platform_value_darwin.h"
#include "lepus/table.h"
#include "tasm/react/ios/lepus_value_converter.h"
#include "tasm/template_assembler.h"

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

std::vector<uint8_t> ConvertNSBinary(NSData* binary) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ConvertNSBinary");
  std::vector<uint8_t> result;
  if (binary.length > 0) {
    result.resize(binary.length);
    std::memcpy(result.data(), reinterpret_cast<const uint8_t*>(binary.bytes), binary.length);
  }
  return result;
}

namespace lynx {
namespace shell {

namespace {

NSDictionary* convertPerfTiming(const std::unordered_map<int32_t, std::string>& perf_timing) {
  NSMutableDictionary* result = [NSMutableDictionary new];
  for (auto& item : perf_timing) {
    [result setValue:[NSString stringWithUTF8String:item.second.c_str()]
              forKey:[LynxPerformance toPerfStampKey:item.first]];
  }
  return result;
}

NSDictionary* convertDynamicComponentPerf(
    const std::unordered_map<std::string, base::PerfCollector::DynamicComponentPerfInfo>&
        dynamic_component_perf) {
  NSMutableDictionary* result = [NSMutableDictionary new];
  for (const auto& item : dynamic_component_perf) {
    NSMutableDictionary* info = [NSMutableDictionary new];
    NSMutableDictionary* timing = [NSMutableDictionary new];
    [info setValue:@(item.second.sync_require())
            forKey:[NSString stringWithUTF8String:item.second.sync_require_key().c_str()]];
    [info setValue:@(item.second.size())
            forKey:[NSString stringWithUTF8String:item.second.size_key().c_str()]];
    static const auto& f = [](NSMutableDictionary* dict, const auto& map) {
      for (const auto& pair : map) {
        [dict
            setValue:@(pair.second)
              forKey:[NSString stringWithUTF8String:base::PerfCollector::DynamicComponentPerfInfo::
                                                        GetName(pair.first)
                                                            .c_str()]];
      }
    };
    f(info, item.second.perf_time());
    f(timing, item.second.perf_time_stamps());
    [info setValue:timing
            forKey:[NSString stringWithUTF8String:item.second.perf_time_stamps_key().c_str()]];
    [result setValue:info forKey:[NSString stringWithUTF8String:item.first.c_str()]];
  }
  return result;
}

NSDictionary* convertPerf(const std::unordered_map<int32_t, double>& perf,
                          const std::unordered_map<int32_t, std::string>& perf_timing) {
  if (perf.empty() && perf_timing.empty()) {
    return nil;
  }

  NSMutableDictionary* result = [NSMutableDictionary new];

#if defined(OS_IOS)
  // To determine whether it is a ssr hydrate perf.
  // Ssr hydrate perf should should be suffixed with "_hydrate".
  BOOL isSsrHydrate = NO;
  auto it = perf.find(kLynxPerformanceIsSrrHydrateIndex);
  if (it != perf.end()) {
    if (base::FloatsLarger(it->second, 0.f)) {
      isSsrHydrate = YES;
    }
  }
  for (auto& item : perf) {
    [result setValue:[NSNumber numberWithDouble:item.second]
              forKey:[LynxPerformance toPerfKey:item.first isSsrHydrate:isSsrHydrate]];
  }
#else
  for (auto& item : perf) {
    [result setValue:[NSNumber numberWithDouble:item.second]
              forKey:[LynxPerformance toPerfKey:item.first]];
  }
#endif

  if (!perf_timing.empty()) {
    [result setValue:convertPerfTiming(perf_timing) forKey:@"timing"];
  }
  return result;
}

}  // namespace

void NativeFacadeDarwin::OnDataUpdated() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnDataUpdated");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onDataUpdated];
}

void NativeFacadeDarwin::OnPageChanged(bool is_first_screen) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnPageChanged");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onPageChanged:is_first_screen];
}

void NativeFacadeDarwin::OnTasmFinishByNative() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnTasmFinishByNative");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onTasmFinishByNative];
}

void NativeFacadeDarwin::OnTemplateLoaded(const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnTemplateLoaded");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onTemplateLoaded:[NSString stringWithUTF8String:url.c_str()]];
}

void NativeFacadeDarwin::OnSSRHydrateFinished(const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnSSRHydrateFinished");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onSSRHydrateFinished:[NSString stringWithUTF8String:url.c_str()]];
}

void NativeFacadeDarwin::OnRuntimeReady() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "NativeFacadeDarwin::OnRuntimeReady");
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onRuntimeReady];
}

void NativeFacadeDarwin::ReportError(int32_t err_code, const std::string& msg) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onErrorOccurred:err_code message:[NSString stringWithUTF8String:msg.c_str()]];
}

// issue: #1510
void NativeFacadeDarwin::OnModuleMethodInvoked(const std::string& module, const std::string& method,
                                               int32_t code) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render didInvokeMethod:[NSString stringWithUTF8String:method.c_str()]
                 inModule:[NSString stringWithUTF8String:module.c_str()]
                errorCode:code];
}

void NativeFacadeDarwin::OnFirstLoadPerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  using lynx::base::PerfCollector;
  std::unordered_map<int32_t, std::string> mutable_perf_timing = perf_timing;
  mutable_perf_timing[static_cast<int32_t>(PerfCollector::PerfStamp::INIT_START)] =
      std::to_string(render.initStartTiming);
  mutable_perf_timing[static_cast<int32_t>(PerfCollector::PerfStamp::INIT_END)] =
      std::to_string(render.initEndTiming);
  [render onFirstLoadPerf:convertPerf(perf, mutable_perf_timing)];
}

void NativeFacadeDarwin::OnUpdatePerfReady(
    const std::unordered_map<int32_t, double>& perf,
    const std::unordered_map<int32_t, std::string>& perf_timing) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onUpdatePerfReady:convertPerf(perf, perf_timing)];
}

void NativeFacadeDarwin::OnDynamicComponentPerfReady(
    const std::unordered_map<std::string, base::PerfCollector::DynamicComponentPerfInfo>&
        dynamic_component_perf) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render onDynamicComponentPerf:convertDynamicComponentPerf(dynamic_component_perf)];
}

void NativeFacadeDarwin::OnConfigUpdated(const lepus::Value& data) {
  if (!data.IsTable() || data.Table()->size() == 0) {
    return;
  }

  __strong id<TemplateRenderCallbackProtocol> render = _render;
  for (const auto& prop : *(data.Table())) {
    if (!prop.first.IsEqual(CARD_CONFIG_THEME) || !prop.second.IsTable()) {
      continue;
    }

    LynxTheme* themeConfig = [LynxTheme new];
    for (const auto& sub_prop : *(prop.second.Table())) {
      if (sub_prop.second.IsString() && sub_prop.second.String()) {
        NSString* key = [NSString stringWithUTF8String:sub_prop.first.c_str()];
        NSString* value = [NSString stringWithUTF8String:sub_prop.second.String()->c_str()];
        [themeConfig updateValue:value forKey:key];
      }
    }
    [render setLocalTheme:themeConfig];
  }
}

void NativeFacadeDarwin::OnPageConfigDecoded(const std::shared_ptr<tasm::PageConfig>& config) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render setPageConfig:config];
}

std::string NativeFacadeDarwin::TranslateResourceForTheme(const std::string& res_id,
                                                          const std::string& theme_key) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  if (res_id.empty() || ![render respondsToSelector:@selector(translatedResourceWithId:
                                                                              themeKey:)]) {
    return std::string();
  }

  NSString* resId = [NSString stringWithUTF8String:res_id.c_str()];
  NSString* key = theme_key.empty() ? nil : [NSString stringWithUTF8String:theme_key.c_str()];
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxResourceFetcher::translatedResource");
  return base::SafeStringConvert([[render translatedResourceWithId:resId themeKey:key] UTF8String]);
}

lepus::Value NativeFacadeDarwin::TriggerLepusMethod(const std::string& js_method_name,
                                                    const lepus::Value& args) {
  lepus::Value value = lynx::piper::TriggerLepusMethod(js_method_name, args, _render);
  if (!value.IsNil()) {
    return value;
  }
  return lepus::Value();
}

void NativeFacadeDarwin::TriggerLepusMethodAsync(const std::string& js_method_name,
                                                 const lepus::Value& args) {
  lynx::piper::TriggerLepusMethodAsync(js_method_name, args, _render);
}

void NativeFacadeDarwin::GetI18nResources(const std::string& channel,
                                          const std::string& fallback_url) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  NSString* ns_channel = [NSString stringWithUTF8String:channel.c_str()];
  NSString* ns_fallback_url = [NSString stringWithUTF8String:fallback_url.c_str()];
  [render getI18nResourceForChannel:ns_channel withFallbackUrl:ns_fallback_url];
}

std::unique_ptr<NativeFacade> NativeFacadeDarwin::Copy() {
  return std::make_unique<NativeFacadeDarwin>(*this);
}

void NativeFacadeDarwin::SetTiming(tasm::Timing timing) {
#if !defined(OS_OSX)
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  NSString* flag = nil;
  if (!timing.timing_flag_.empty()) {
    flag = [NSString stringWithUTF8String:timing.timing_flag_.c_str()];
  }
  for (auto const& [timing_key, timestamp] : timing.timings_) {
    NSString* key = [NSString stringWithUTF8String:tasm::TimingKeyToString(timing_key).c_str()];
    if (key) {
      [render setTiming:timestamp key:key updateFlag:flag];
    }
  }
#endif
}

// Report tracker events to TemplateRender.
void NativeFacadeDarwin::Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  [render reportEvents:std::move(stack)];
}

void NativeFacadeDarwin::InvokeUIMethod(const tasm::LynxGetUIResult& ui_result,
                                        const std::string& method,
                                        std::unique_ptr<piper::PlatformValue> params,
                                        piper::ApiCallBack callback) {
#if !defined(OS_OSX)
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  NSString* method_string = [NSString stringWithUTF8String:method.c_str()];
  NSDictionary* params_dict = ((piper::PlatformValueDarwin*)params.get())->Get();

  [render invokeUIMethod:method_string
                  params:params_dict
                callback:callback.id()
                  toNode:ui_result.UiImplIds()[0]];
#endif
}

void NativeFacadeDarwin::FlushJSBTiming(piper::NativeModuleInfo timing) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  NSDictionary* info = @{
    @"jsb_module_name" : [NSString stringWithUTF8String:timing.module_name_.c_str()],
    @"jsb_method_name" : [NSString stringWithUTF8String:timing.method_name_.c_str()],
    @"jsb_name" : [NSString stringWithUTF8String:timing.method_first_arg_name_.c_str()],
    // "jsb_protocol_version" web field, lynx default 0.
    @"jsb_protocol_version" : @(0),
    @"jsb_bridgesdk" : @"lynx"
  };
  NSMutableDictionary* invokedInfo = [NSMutableDictionary dictionaryWithDictionary:info];
  [invokedInfo setObject:@(static_cast<int64_t>(timing.status_code_)) forKey:@"jsb_status_code"];
  [render onJSBInvoked:invokedInfo.copy];
  if (timing.status_code_ != piper::NativeModuleStatusCode::SUCCESS) {
    return;
  }
  NSDictionary* timing_info = @{
    @"perf" : @{
      @"jsb_call" : @(timing.jsb_call_),
      @"jsb_func_call" : @(timing.jsb_func_call_),
      @"jsb_func_convert_params" : @(timing.jsb_func_convert_params_),
      @"jsb_func_platform_method" : @(timing.jsb_func_platform_method_),
      @"jsb_callback_thread_switch" : @(timing.jsb_callback_thread_switch_),
      @"jsb_callback_call" : @(timing.jsb_callback_call_),
      @"jsb_callback_convert_params" : @(timing.jsb_callback_convert_params_),
      @"jsb_callback_invoke" : @(timing.jsb_callback_invoke_),
      @"jsb_func_call_start" : @(timing.jsb_func_call_start_),
      @"jsb_func_call_end" : @(timing.jsb_func_call_end_),
      @"jsb_callback_thread_switch_start" : @(timing.jsb_callback_thread_switch_start_),
      @"jsb_callback_thread_switch_end" : @(timing.jsb_callback_thread_switch_end_),
      @"jsb_callback_call_start" : @(timing.jsb_callback_call_start_),
      @"jsb_callback_call_end" : @(timing.jsb_callback_call_end_),
    },
    @"info" : info
  };
  [render onCallJSBFinished:timing_info];
}
}  // namespace shell
}  // namespace lynx
