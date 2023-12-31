// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SERVER_SHELL_SSR_SHELL_H_
#define LYNX_SSR_SERVER_SHELL_SSR_SHELL_H_

#include <memory>
#include <string>
#include <vector>

#include "napi.h"
#include "ssr/server_shell/server_tasm_mediator.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace ssr {

class NapiLynxShell {
 public:
  NapiLynxShell(bool enable_server_event, std::string&& api_version);
  void LoadTemplate(std::vector<uint8_t>&& source);
  std::vector<uint8_t> RenderToBinary(Napi::Env env, bool keep_page_data,
                                      Napi::Value& init_states,
                                      Napi::Value& global_props,
                                      Napi::Value& system_info,
                                      Napi::Function event_predictor);
  std::vector<uint8_t> LoadAndRender(std::vector<uint8_t>&& source,
                                     Napi::Env env, bool keep_page_data,
                                     Napi::Value& init_states,
                                     Napi::Value& global_props,
                                     Napi::Value& system_info,
                                     Napi::Function event_predictor);
  std::string GetAppService();

 private:
  std::unique_ptr<tasm::TemplateAssembler> tasm_;
  ServerTasmMediator mediator_;
  void AttachServerEvent(Napi::Env env, Napi::Function event_predictor,
                         bool needLoadAppService, lepus::Value* ssr_script);
  lepus::Value InjectData(Napi::Env env, Napi::Value& init_state,
                          Napi::Value& global_props, Napi::Value& system_info,
                          bool keep_page_data);
  std::vector<uint8_t> CollectResult(Napi::Env env, lepus::Value config_value,
                                     Napi::Function event_predictor,
                                     bool needLoadAppService);
  bool enable_server_event_;
  std::string api_version_;
};

}  // namespace ssr
}  // namespace lynx
#endif  // LYNX_SSR_SERVER_SHELL_SSR_SHELL_H_
