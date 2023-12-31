// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_META_FACTORY_H_
#define LYNX_TASM_GENERATOR_META_FACTORY_H_

#include <string>

#include "tasm/generator/base_struct.h"
#include "third_party/rapidjson/rapidjson.h"

namespace lynx {
namespace tasm {
class MetaFactory {
 public:
  static EncoderOptions GetEncoderOptions(rapidjson::Document& document);

 private:
  static void GetSourceContent(rapidjson::Value& document,
                               EncoderOptions& encoder_options);

  static void GetCSSMeta(rapidjson::Value& document,
                         EncoderOptions& encoder_options);

  static void GetAndCheckTargetSdkVersion(rapidjson::Value& compiler_options,
                                          EncoderOptions& encoder_options);

  static void GetTrialOptions(rapidjson::Document& document,
                              EncoderOptions& encoder_options);

  static void GetTemplateInfo(rapidjson::Document& document,
                              EncoderOptions& encoder_options);

  static void GetLepusCode(rapidjson::Document& document,
                           EncoderOptions& encoder_options);

  static void GetJSCode(rapidjson::Document& document,
                        EncoderOptions& encoder_options);

  static void GetConfig(EncoderOptions& encoder_options);

  static void GetTemplateScript(rapidjson::Document& document,
                                EncoderOptions& encoder_options);

  static void GetElementTemplate(rapidjson::Document& document,
                                 EncoderOptions& encoder_options);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_META_FACTORY_H_
