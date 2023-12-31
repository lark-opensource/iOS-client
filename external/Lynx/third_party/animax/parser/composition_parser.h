// Copyright 2023 The Lynx Authors. All rights reserved.
// Copyright 2018 Airbnb, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ANIMAX_PARSER_COMPOSITION_PARSER_H_
#define ANIMAX_PARSER_COMPOSITION_PARSER_H_

#include <unordered_map>

#include "animax/model/composition_model.h"
#include "animax/model/layer_model.h"
#include "animax/parser/base_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class CompositionParser : public BaseParser<CompositionParser> {
 public:
  /**
   * Entry for parse composition model
   * @param src_url
   * @param str_data
   * @param length
   * @param scale
   * @return
   */
  std::shared_ptr<CompositionModel> Parse(const char* str_data, size_t length,
                                          float scale);

 private:
  /**
   * Parse Layer model into composition.
   * e.g. Text, Image, Solid, Null, Shape
   * @param value
   * @param composition
   */
  void ParseLayers(rapidjson::Value& value, CompositionModel& composition);
  /**
   * Parse image asset model into composition
   * @param value
   * @param composition
   */
  void ParseAssets(rapidjson::Value& value, CompositionModel& composition);
  /**
   * Parse font asset model into composition
   * @param value
   * @param composition
   */
  void ParseFonts(rapidjson::Value& value, CompositionModel& composition);
  /**
   * Parse text character model into composition
   * @param value
   * @param composition
   */
  void ParseChars(rapidjson::Value& value, CompositionModel& composition);
  /**
   * Parse marker model into composition
   * @param value
   * @param composition
   */
  void ParseMarkers(rapidjson::Value& value, CompositionModel& composition);
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_COMPOSITION_PARSER_H_
