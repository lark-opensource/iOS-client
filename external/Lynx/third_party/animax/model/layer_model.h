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

#ifndef ANIMAX_MODEL_LAYER_MODEL_H_
#define ANIMAX_MODEL_LAYER_MODEL_H_

#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include "animatable/animatable_text_properties.h"
#include "animatable/animatable_value.h"
#include "animax/model/effect/blur_effect_model.h"
#include "animax/model/effect/drop_shadow_effect_model.h"
#include "animax/model/mask_model.h"

namespace lynx {
namespace animax {

class ContentModel;
class CompositionModel;
class AnimatableTransformModel;

enum class LayerType : uint8_t {
  kPreComp = 0,
  kSolid,
  kImage,
  kNull,
  kShape,
  kText,
  kUnknown
};

enum class MatteType : uint8_t {
  kNone = 0,
  kAdd,
  kInvert,
  kLuma,
  kLumaInverted,
  kUnknown
};

class LayerModel {
 public:
  static std::shared_ptr<LayerModel> Make(CompositionModel& composition);

  LayerModel(CompositionModel& composition);
  ~LayerModel() = default;

  void Init(std::string layer_name, LayerType layer_type, int32_t layer_id,
            int32_t parent_id, std::string ref_id, int32_t solid_width,
            int32_t solid_height, Color& solid_color, float time_stretch,
            float start_frame, float pre_comp_width, float pre_comp_height,
            std::unique_ptr<AnimatableTextFrame> text,
            std::unique_ptr<AnimatableTextProperties> text_properties,
            bool hidden, std::shared_ptr<AnimatableTransformModel> transform,
            int32_t matte_type_int,
            std::unique_ptr<AnimatableFloatValue> time_remapping,
            std::unique_ptr<BlurEffectModel> blur_effect,
            std::unique_ptr<DropShadowEffectModel> drop_shadow_effect);

  LayerType GetLayerType() { return layer_type_; }
  int32_t GetId() { return layer_id_; }
  std::string& GetRefId() { return ref_id_; }
  std::string& GetName() { return layer_name_; }

  std::vector<std::shared_ptr<ContentModel>>& GetShapes() { return shapes_; }
  std::vector<std::unique_ptr<MaskModel>>& GetMasks() { return masks_; }
  std::vector<std::unique_ptr<KeyframeModel<Float>>>& GetInOutFrames() {
    return in_out_frames_;
  }
  std::shared_ptr<AnimatableTransformModel> GetTransform() {
    return transform_;
  }

  Color& GetSolidColor() { return solid_color_; }
  int32_t GetSolidWidth() { return solid_width_; }
  int32_t GetSolidHeight() { return solid_height_; }

  float GetPreCompWidth() { return pre_comp_width_; }
  float GetPreCompHeight() { return pre_comp_height_; }
  int32_t GetParentId() { return parent_id_; }
  float GetStartProgress() {
    return start_frame_ / composition_.GetDurationFrames();
  }
  float GetTimeStretch() { return time_stretch_; }

  bool IsHidden() { return hidden_; }

  MatteType& GetMatteType() { return matte_type_; }

  AnimatableTextFrame* GetText() { return text_.get(); }
  AnimatableTextProperties* GetTextProperties() {
    return text_properties_.get();
  }
  AnimatableFloatValue* GetTimeRemapping() { return time_remapping_.get(); }

  BlurEffectModel* GetBlurEffect() { return blur_effect_.get(); }
  DropShadowEffectModel* GetDropEffect() { return drop_shadow_effect_.get(); }

 private:
  CompositionModel& composition_;

  std::vector<std::shared_ptr<ContentModel>> shapes_;
  std::vector<std::unique_ptr<MaskModel>> masks_;

  std::string layer_name_;
  LayerType layer_type_;
  int32_t layer_id_ = -1;
  int32_t parent_id_ = -1;
  std::string ref_id_;

  // TODO(aiyongbiao): masks p1
  std::shared_ptr<AnimatableTransformModel> transform_;
  int32_t solid_width_ = 0;
  int32_t solid_height_ = 0;
  Color solid_color_;
  float time_stretch_ = 0;
  float start_frame_ = 0;
  float pre_comp_width_ = 0;
  float pre_comp_height_ = 0;
  bool hidden_ = false;

  // text
  std::unique_ptr<AnimatableTextFrame> text_;
  std::unique_ptr<AnimatableTextProperties> text_properties_;

  std::vector<std::unique_ptr<KeyframeModel<Float>>> in_out_frames_;

  MatteType matte_type_ = MatteType::kNone;
  std::unique_ptr<AnimatableFloatValue> time_remapping_;

  // effect
  std::unique_ptr<BlurEffectModel> blur_effect_;
  std::unique_ptr<DropShadowEffectModel> drop_shadow_effect_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_LAYER_MODEL_H_
