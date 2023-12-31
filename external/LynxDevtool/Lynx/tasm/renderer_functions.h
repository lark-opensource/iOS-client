// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RENDERER_FUNCTIONS_H_
#define LYNX_TASM_RENDERER_FUNCTIONS_H_

#include <string>

#include "lepus/value.h"
#include "tasm/list_component_info.h"
#include "tasm/renderer_functions_def.h"

namespace lynx {
namespace tasm {
class AttributeHolder;
class BaseComponent;
class TemplateAssembler;
#define NORMAL_FUNCTION_DEF(name) \
  static lepus::Value name(lepus::Context* ctx, lepus::Value* argv, int argc);

class RendererFunctions {
 public:
  NORMAL_RENDERER_FUNCTIONS(NORMAL_FUNCTION_DEF)

 private:
  static ListComponentInfo ComponentInfoFromContext(lepus::Context* ctx,
                                                    lepus::Value* argv,
                                                    int argc);
  static lepus::Value InnerTranslateResourceForTheme(
      lepus::Context* ctx, lepus::Value* argv, int argc,
      const char* keyIn = nullptr);
  static void InnerThemeReplaceParams(lepus::Context* context,
                                      std::string& retStr, lepus::Value* argv,
                                      int argc, int paramStartIndex);

  // Should update component config before component created.
  static void UpdateComponentConfig(TemplateAssembler* tasm,
                                    BaseComponent* component);

  static AttributeHolder* GetInternalAttributeHolder(lepus::Context* context,
                                                     lepus::Value* arg);
  static BaseComponent* GetBaseComponent(lepus::Context* context,
                                         lepus::Value* arg);
  static void UpdateAirElement(lepus::Context* ctx,
                               const lepus::Value& lepus_element,
                               bool need_flush);
  static void CreateAirElement(lepus::Context* ctx,
                               const lepus::Value& lepus_element);
};
#undef NORMAL_FUNCTION_DEF
#undef TEMP_FUNCTION_DEF
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RENDERER_FUNCTIONS_H_
