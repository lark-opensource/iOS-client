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

#ifndef ANIMAX_MODEL_COMPOSITION_MODEL_H_
#define ANIMAX_MODEL_COMPOSITION_MODEL_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "animax/model/basic_model.h"
#include "animax/model/marker_model.h"
#include "animax/resource/asset/font_asset.h"
#include "animax/resource/asset/image_asset.h"

namespace lynx {
namespace animax {

class LayerModel;
class FontCharacterModel;

using LayerModelList = std::vector<std::shared_ptr<LayerModel>>;

class CompositionModel {
 public:
  CompositionModel(float scale);
  ~CompositionModel() = default;

  void Init(std::unique_ptr<Rect> bounds, float start_frame, float end_frame,
            float frame_rate);

  long GetDuration();
  float GetStartFrame() { return start_frame_; }
  float GetEndFrame() { return end_frame_; }
  float GetScale() { return scale_; }
  float GetDurationFrames() { return end_frame_ - start_frame_; }
  float GetFrameRate() { return frame_rate_; }

  Rect& GetBounds() { return *bounds_; }

  const std::shared_ptr<LayerModelList>& GetLayers() { return layers_; }
  std::unordered_map<int32_t, std::shared_ptr<LayerModel>>& GetLayerMap() {
    return layer_map_;
  }

  std::unordered_map<std::string, std::shared_ptr<LayerModelList>>&
  GetPrecomps() {
    return pre_comps_;
  }
  std::unordered_map<std::string, std::shared_ptr<ImageAsset>>& GetImages() {
    return images_;
  }

  // key: font name, value: font asset
  std::unordered_map<std::string, std::shared_ptr<FontAsset>>& GetFonts() {
    return fonts_;
  }
  std::unordered_map<int32_t, std::shared_ptr<FontCharacterModel>>&
  GetCharacters() {
    return characters_;
  }

  std::vector<std::shared_ptr<MarkerModel>>& GetMarkers() { return markers_; }
  std::shared_ptr<MarkerModel> GetMarker(const std::string& marker_name);

  void SetHashDashPattern(bool has_dash_patern);
  void IncrementMatteOrMaskCount(int32_t count);

  bool UseTextGlyphs();

 private:
  std::unique_ptr<Rect> bounds_;

  int32_t mask_and_matte_count_ = 0;
  float start_frame_ = 0;
  float end_frame_ = 0;
  float frame_rate_ = 30;
  float scale_ = 1;
  bool has_dash_pattern_ = false;

  // parse assets
  std::unordered_map<std::string, std::shared_ptr<LayerModelList>> pre_comps_;
  std::unordered_map<std::string, std::shared_ptr<ImageAsset>> images_;

  // parse layers
  std::shared_ptr<LayerModelList> layers_ = std::make_shared<LayerModelList>();
  std::unordered_map<int32_t, std::shared_ptr<LayerModel>> layer_map_;

  // text
  std::unordered_map<std::string, std::shared_ptr<FontAsset>> fonts_;
  std::unordered_map<int32_t, std::shared_ptr<FontCharacterModel>> characters_;

  // marker
  std::vector<std::shared_ptr<MarkerModel>> markers_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_MODEL_COMPOSITION_MODEL_H_
