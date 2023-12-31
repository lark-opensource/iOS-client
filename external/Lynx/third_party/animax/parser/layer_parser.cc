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

#include "animax/parser/layer_parser.h"

#include <string>
#include <vector>

#include "animax/model/animatable/animatable_transform_model.h"
#include "animax/model/content_model.h"
#include "animax/model/layer_model.h"
#include "animax/model/mask_model.h"
#include "animax/parser/animatable/animatable_text_properties_parser.h"
#include "animax/parser/animatable/animatable_transform_parser.h"
#include "animax/parser/animatable/animatable_value_parser.h"
#include "animax/parser/content_model_parser.h"
#include "animax/parser/effect/blur_effect_parser.h"
#include "animax/parser/effect/drop_shadow_effect_parser.h"
#include "animax/parser/mask_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<LayerModel> LayerParser::Parse(CompositionModel& composition) {
  auto layer_model = LayerModel::Make(composition);
  ;
  auto& bounds = composition.GetBounds();

  auto color = Color::Make();
  // TODO(aiyongbiao): add more params to constructor, text, textprop p1
  layer_model->Init(
      std::string("__container"), LayerType::kPreComp, -1, -1, std::string(""),
      0, 0, color, 0, 0, bounds.GetWidth(), bounds.GetHeight(), nullptr,
      nullptr, false, std::make_shared<AnimatableTransformModel>(),
      static_cast<int>(MatteType::kUnknown), nullptr, nullptr, nullptr);
  return layer_model;
}

std::shared_ptr<LayerModel> LayerParser::Parse(rapidjson::Value& value,
                                               CompositionModel& composition) {
  auto layer_model = LayerModel::Make(composition);
  auto scale = composition.GetScale();

  std::string layer_name;
  int32_t layer_id = 0, parent_id = -1;
  std::string ref_id;
  LayerType layer_type;
  int32_t solid_width = 0, solid_height = 0;
  Color solid_color = Color::MakeEmpty();
  float time_stretch = 1, start_frame = 0, in_frame = 0, out_frame = 0;
  float pre_comp_width = 0, pre_comp_height = 0;
  std::string cl;
  bool hidden = false;

  std::unique_ptr<BlurEffectModel> blur_effect;
  std::unique_ptr<DropShadowEffectModel> drop_shadow_effect;

  int32_t matte_type_int = static_cast<int>(MatteType::kUnknown);
  std::shared_ptr<AnimatableTransformModel> transform;
  std::unique_ptr<AnimatableTextFrame> text;
  std::unique_ptr<AnimatableTextProperties> text_properties;
  std::unique_ptr<AnimatableFloatValue> time_remapping;

  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "nm") == 0) {
      layer_name = it->value.GetString();
    } else if (strcmp(key, "ind") == 0) {
      layer_id = it->value.GetInt();
    } else if (strcmp(key, "refId") == 0) {
      ref_id = it->value.GetString();
    } else if (strcmp(key, "ty") == 0) {
      int32_t layer_type_int = it->value.GetInt();
      if (layer_type_int < static_cast<int32_t>(LayerType::kUnknown)) {
        layer_type = static_cast<LayerType>(layer_type_int);
      } else {
        layer_type = LayerType::kUnknown;
      }
    } else if (strcmp(key, "parent") == 0) {
      parent_id = it->value.GetInt();
    } else if (strcmp(key, "sw") == 0) {
      solid_width = it->value.GetInt() * scale;
    } else if (strcmp(key, "sh") == 0) {
      solid_height = it->value.GetInt() * scale;
    } else if (strcmp(key, "sc") == 0) {
      std::string color = it->value.GetString();
      solid_color = Color::ParseColor(color);
    } else if (strcmp(key, "ks") == 0) {
      transform =
          AnimatableTransformParser::Instance().Parse(it->value, composition);
    } else if (strcmp(key, "tt") == 0) {
      matte_type_int = it->value.GetInt();
      composition.IncrementMatteOrMaskCount(1);
    } else if (strcmp(key, "masksProperties") == 0) {
      const auto& mask_array = it->value.GetArray();
      auto& masks = layer_model->GetMasks();
      for (auto mask_it = mask_array.Begin(); mask_it != mask_array.End();
           mask_it++) {
        masks.push_back(
            MaskParser::Instance().Parse(mask_it->Move(), composition));
      }
    } else if (strcmp(key, "shapes") == 0) {
      const auto& array = it->value.GetArray();
      auto& shapes = layer_model->GetShapes();
      for (auto shape_it = array.Begin(); shape_it != array.End(); shape_it++) {
        auto shape =
            ContentModelParser::Instance().Parse(shape_it->Move(), composition);
        if (shape) {
          shapes.push_back(shape);
        }
      }
    } else if (strcmp(key, "t") == 0) {
      const auto& text_object = it->value.GetObject();
      for (auto text_it = text_object.MemberBegin();
           text_it != text_object.MemberEnd(); text_it++) {
        const auto& text_key = text_it->name.GetString();
        if (strcmp(text_key, "d") == 0) {
          text = AnimatableValueParser::Instance().ParseDocumentData(
              text_it->value, composition);
        } else if (strcmp(text_key, "a") == 0) {
          const auto& prop_array = text_it->value.GetArray();
          if (!prop_array.Empty()) {
            text_properties = AnimatableTextPropertiesParser::Instance().Parse(
                prop_array[0], composition);
          }
        }
      }
    } else if (strcmp(key, "ef") == 0) {
      const auto& effect_array = it->value.GetArray();

      for (auto array_it = effect_array.Begin(); array_it != effect_array.End();
           array_it++) {
        const auto& effect_object = array_it->GetObject();
        for (auto object_it = effect_object.MemberBegin();
             object_it != effect_object.MemberEnd(); object_it++) {
          auto name = object_it->name.GetString();
          if (strcmp("ty", name) == 0) {
            auto type = object_it->value.GetInt();
            auto ef_object = effect_object.FindMember("ef");
            if (ef_object == effect_object.MemberEnd()) {
              ANIMAX_LOGE("no ef member");
              continue;
            }

            if (type == 29) {
              blur_effect = BlurEffectParser::Instance().Parse(ef_object->value,
                                                               composition);
            } else if (type == 25) {
              drop_shadow_effect = DropShadowEffectParser::Instance().Parse(
                  ef_object->value, composition);
            } else {
              ANIMAX_LOGI("effect not support, type:") << std::to_string(type);
            }
          }
        }
      }
    } else if (strcmp(key, "sr") == 0) {
      time_stretch = it->value.GetFloat();
    } else if (strcmp(key, "st") == 0) {
      start_frame = it->value.GetFloat();
    } else if (strcmp(key, "w") == 0) {
      pre_comp_width = it->value.GetFloat() * scale;
    } else if (strcmp(key, "h") == 0) {
      pre_comp_height = it->value.GetFloat() * scale;
    } else if (strcmp(key, "ip") == 0) {
      in_frame = it->value.GetFloat();
    } else if (strcmp(key, "op") == 0) {
      out_frame = it->value.GetFloat();
    } else if (strcmp(key, "tm") == 0) {
      time_remapping = AnimatableValueParser::Instance().ParseFloat(
          it->value, composition, false);
    } else if (strcmp(key, "cl") == 0) {
      cl = it->value.GetString();
    } else if (strcmp(key, "hd") == 0) {
      hidden = it->value.GetBool();
    }
  }

  auto& in_out_frames = layer_model->GetInOutFrames();
  if (in_frame > 0) {
    in_out_frames.emplace_back(std::make_unique<KeyframeModel<Float>>(
        composition, Float::Make(0), Float::Make(0), nullptr, 0, in_frame));
  }

  out_frame = out_frame > 0 ? out_frame : composition.GetEndFrame();

  in_out_frames.emplace_back(std::make_unique<KeyframeModel<Float>>(
      composition, Float::Make(1), Float::Make(1), nullptr, in_frame,
      out_frame));

  in_out_frames.emplace_back(std::make_unique<KeyframeModel<Float>>(
      composition, Float::Make(0), Float::Make(0), nullptr, out_frame,
      Float::Max()));

  layer_model->Init(
      layer_name, layer_type, layer_id, parent_id, ref_id, solid_width,
      solid_height, solid_color, time_stretch, start_frame, pre_comp_width,
      pre_comp_height, std::move(text), std::move(text_properties), hidden,
      std::move(transform), matte_type_int, std::move(time_remapping),
      std::move(blur_effect), std::move(drop_shadow_effect));
  return layer_model;
}

}  // namespace animax
}  // namespace lynx
