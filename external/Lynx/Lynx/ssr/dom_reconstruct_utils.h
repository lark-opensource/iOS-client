// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_DOM_RECONSTRUCT_UTILS_H_
#define LYNX_SSR_DOM_RECONSTRUCT_UTILS_H_

#include <memory>
#include <string>

#include "base/debug/lynx_assert.h"
#include "tasm/attribute_holder.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace ssr {

lepus::Value RetrievePageData(const lepus::Value& ssr_out_data,
                              const lepus::Value& dict);
lepus::Value RetrieveGlobalProps(const lepus::Value& ssr_out_data);
lepus::Value RetrievePageConfig(const lepus::Value& ssr_out_value);
lepus::Value RetrieveScript(const lepus::Value& ssr_out_value);
lepus::Value ProcessSsrScriptIfNeeded(const lepus::Value value,
                                      const lepus::Value& dict);
bool RetrieveSupportComponentJS(const lepus::Value& page_status);
std::string RetrieveTargetSdkVersion(const lepus::Value& page_status);
bool RetrieveLepusNGSwitch(const lepus::Value& page_status);
std::shared_ptr<tasm::PageConfig> RetrieveLynxPageConfig(
    const lepus::Value& ssr_out_value);

void ReconstructDom(const lepus::Value& ssr_out_data, tasm::PageProxy* proxy,
                    tasm::RadonPage* page, const lepus::Value& dict);

lepus::Value FormatEventArgsForIOS(const std::string& method_name,
                                   const lepus::Value& args);

lepus::Value FormatEventArgsForAndroid(const std::string& method_name,
                                       const lepus::Value& args);
bool CheckSSRkApiVersion(const lepus::Value& ssr_out_value);

}  // namespace ssr
}  // namespace lynx
#endif  // LYNX_SSR_DOM_RECONSTRUCT_UTILS_H_
