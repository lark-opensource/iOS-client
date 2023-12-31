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

#ifndef ANIMAX_LAYER_BASE_LAYER_H_
#define ANIMAX_LAYER_BASE_LAYER_H_

#include <memory>

#include "animax/animation/basic_keyframe_animation.h"
#include "animax/animation/keyframe_animation.h"
#include "animax/animation/mask_keyframe_animation.h"
#include "animax/animation/transform_keyframe_animation.h"
#include "animax/model/composition_model.h"
#include "animax/model/layer_model.h"
#include "animax/render/include/mask_filter.h"
#include "animax/render/include/paint.h"

namespace lynx {
namespace animax {

class CompositionLayer;
class InOutAnimationListener;

class BaseLayer : public Content, public AnimationListener {
 public:
  static std::unique_ptr<BaseLayer> forModel(
      CompositionLayer& composition_layer,
      std::shared_ptr<LayerModel>& layer_model, CompositionModel& composition);

  BaseLayer(std::shared_ptr<LayerModel>& layer_model, CompositionModel& model);
  virtual ~BaseLayer() = default;

  void Init() override;

  void OnValueChanged() override {}

  void Draw(Canvas& canvas, Matrix& parent_matrix,
            int32_t parent_alpha) override;
  void GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                 bool apply_parent) override;

  std::string GetName() override { return layer_model_->GetName(); }

  virtual void SetContents(std::vector<Content*>& contents_before,
                           std::vector<Content*>& contents_after) override {}
  virtual void SetProgress(float progress);
  virtual void DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) = 0;
  virtual BlurEffectModel* GetBlurEffect() {
    return layer_model_->GetBlurEffect();
  };
  virtual DropShadowEffectModel* GetDropEffect() {
    return layer_model_->GetDropEffect();
  };

  template <typename K, typename A>
  void AddAnimation(BaseKeyframeAnimation<K, A>* animation) {
    if (animation) {
      animations_.push_back(animation);
    }
  }

  const std::shared_ptr<LayerModel>& GetLayerModel() { return layer_model_; }
  bool HasMatteOnThisLayer() { return matte_layer_ != nullptr; }
  bool HasMaskOnThisLayer() {
    return mask_ && !mask_->GetMaskAnimations().empty();
  }

  void SetUpInOutAnimations();
  void SetVisible(bool visible);
  void SetMattedLayer(std::unique_ptr<BaseLayer>& matted_layer) {
    matte_layer_ = std::move(matted_layer);
  }
  void SetParentLayer(BaseLayer* layer) { parent_layer_ = layer; }

  void BuildParentLayerListIfNeeded();
  void IntersectBoundsWithMatte(RectF& rect, Matrix& matrix);
  void IntersectBoundsWithMask(RectF& rect, Matrix& matrix);

  void ClearCanvas(Canvas& canvas);
  void ApplyMasks(Canvas& canvas, Matrix& matrix);
  bool AreAllMasksNone();

  void ApplyInvertedAddMask(
      Canvas& canvas, Matrix& matrix,
      const BaseKeyframeAnimation<ShapeDataModel, std::unique_ptr<Path>>&
          mask_animation,
      const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplyAddMask(
      Canvas& canvas, Matrix& matrix,
      const BaseKeyframeAnimation<ShapeDataModel, std::unique_ptr<Path>>&
          mask_animation,
      const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplyInvertedSubtractMask(
      Canvas& canvas, Matrix& matrix,
      const BaseKeyframeAnimation<ShapeDataModel, std::unique_ptr<Path>>&
          mask_animation,
      const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplySubtractMask(Canvas& canvas, Matrix& matrix,
                         const BaseShapeKeyframeAnimation& mask_animation,
                         const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplyInvertedIntersectMask(
      Canvas& canvas, Matrix& matrix,
      const BaseShapeKeyframeAnimation& mask_animation,
      const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplyIntersectMask(
      Canvas& canvas, Matrix& matrix,
      const BaseShapeKeyframeAnimation& mask_animation,
      const BaseIntegerKeyframeAnimation& opacity_animation);

  void ApplyInvertedMask(Canvas& canvas, Matrix& matrix,
                         const BaseShapeKeyframeAnimation& mask_animation,
                         const BaseIntegerKeyframeAnimation& opacity_animation,
                         Paint& save_paint, Paint& alpha_paint);

  //  TODO(aiyongbiao): resolve key path p1

  CompositionModel& GetComposition() { return composition_; }
  MaskFilter* GetBlurMaskFilter(float radius);

  bool SubDrawingType() override { return true; }

 protected:
  friend class InOutAnimationListener;

  std::shared_ptr<LayerModel> layer_model_;
  CompositionModel& composition_;

  std::unique_ptr<Matrix> matrix_;
  std::unique_ptr<Path> path_;

  // parent
  BaseLayer* parent_layer_ = nullptr;
  std::vector<BaseLayer*> parent_layers_;

  std::unique_ptr<Matrix> bounds_matrix_;
  std::unique_ptr<Matrix> canvas_matrix_;

  std::vector<IKeyframeAnimation*> animations_;
  std::unique_ptr<TransformKeyframeAnimation> transform_;

  std::unique_ptr<Paint> content_paint_;
  std::unique_ptr<Paint> dst_in_paint_;
  std::unique_ptr<Paint> dst_out_paint_;
  std::unique_ptr<Paint> matte_paint_;
  std::unique_ptr<Paint> clear_paint_;

  bool outline_maks_and_mattes_;
  std::unique_ptr<Paint> outline_masks_and_mattes_paint_;

  RectF rect_;
  RectF canvas_bounds_;
  RectF mask_bounds_rect_;
  RectF matte_bounds_rect_;
  RectF temp_mask_bounds_rect_;

  bool visible_ = true;
  std::unique_ptr<BaseFloatKeyframeAnimation> in_out_animation_;
  std::unique_ptr<InOutAnimationListener> in_out_listener_;
  std::unique_ptr<MaskKeyframeAnimation> mask_;
  std::unique_ptr<BaseLayer> matte_layer_;

  float blur_mask_filter_radius_ = 0.0;
  std::unique_ptr<MaskFilter> blur_mask_filter_;
};

class InOutAnimationListener : public AnimationListener {
 public:
  InOutAnimationListener(BaseLayer& layer) : layer_(layer) {}

  void OnValueChanged() override {
    auto in_out_value = layer_.in_out_animation_->GetValue().Get();
    layer_.SetVisible(in_out_value == 1.0);
  }

 private:
  BaseLayer& layer_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_LAYER_BASE_LAYER_H_
