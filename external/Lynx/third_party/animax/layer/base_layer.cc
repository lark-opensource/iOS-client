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

#include "animax/layer/base_layer.h"

#include <memory>

#include "animax/base/log.h"
#include "animax/layer/composition_layer.h"
#include "animax/layer/image_layer.h"
#include "animax/layer/null_layer.h"
#include "animax/layer/shape_layer.h"
#include "animax/layer/solid_layer.h"
#include "animax/layer/text_layer.h"
#include "animax/model/animatable/animatable_transform_model.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

std::unique_ptr<BaseLayer> BaseLayer::forModel(
    CompositionLayer& composition_layer,
    std::shared_ptr<LayerModel>& layer_model, CompositionModel& composition) {
  auto layer_type = layer_model->GetLayerType();
  std::unique_ptr<BaseLayer> layer;
  switch (layer_type) {
    case LayerType::kShape:
      layer = std::make_unique<ShapeLayer>(layer_model, composition_layer,
                                           composition);
      break;
    case LayerType::kPreComp: {
      auto pre_composition_layer =
          std::make_unique<CompositionLayer>(layer_model, composition);
      auto& precomps = composition.GetPrecomps();
      if (precomps.find(layer_model->GetRefId()) != precomps.end()) {
        pre_composition_layer->SetLayerModels(
            precomps[layer_model->GetRefId()]);
      }
      layer = std::move(pre_composition_layer);
      break;
    }
    case LayerType::kSolid:
      layer = std::make_unique<SolidLayer>(layer_model, composition);
      break;
    case LayerType::kImage:
      layer = std::make_unique<ImageLayer>(layer_model, composition);
      break;
    case LayerType::kNull:
      layer = std::make_unique<NullLayer>(layer_model, composition);
      break;
    case LayerType::kText:
      layer = std::make_unique<TextLayer>(layer_model, composition);
      break;
    default:
      ANIMAX_LOGI("skip layer type:")
          << std::to_string(static_cast<int32_t>(layer_type));
      // TODO(aiyongbiao): other layers p1
  }

  if (layer) {
    layer->Init();
  }
  return layer;
}

BaseLayer::BaseLayer(std::shared_ptr<LayerModel>& layer_model,
                     CompositionModel& model)
    : layer_model_(layer_model),
      composition_(model),
      matrix_(Context::MakeMatrix()),
      path_(Context::MakePath()),
      bounds_matrix_(Context::MakeMatrix()),
      content_paint_(Context::MakePaint()),
      dst_in_paint_(Context::MakePaint()),
      dst_out_paint_(Context::MakePaint()),
      matte_paint_(Context::MakePaint()),
      clear_paint_(Context::MakePaint()) {
  content_paint_->SetAntiAlias(true);

  dst_in_paint_->SetAntiAlias(true);
  dst_in_paint_->SetXfermode(PaintXfermode::kDstIn);

  dst_out_paint_->SetAntiAlias(true);
  dst_out_paint_->SetXfermode(PaintXfermode::kDstOut);

  matte_paint_->SetAntiAlias(true);

  clear_paint_->SetXfermode(PaintXfermode::kClear);
}

void BaseLayer::Init() {
  if (layer_model_->GetMatteType() == MatteType::kInvert) {
    matte_paint_->SetXfermode(PaintXfermode::kDstOut);
  } else {
    matte_paint_->SetXfermode(PaintXfermode::kDstIn);
  }

  transform_ = layer_model_->GetTransform()->CreateAnimation();
  transform_->AddListener(this);

  auto& masks = layer_model_->GetMasks();
  if (!masks.empty()) {
    mask_ = std::make_unique<MaskKeyframeAnimation>(masks);
    for (auto& animation : mask_->GetMaskAnimations()) {
      animation->AddUpdateListener(this);
    }
    for (auto& animation : mask_->GetOpacityAnimations()) {
      AddAnimation(animation.get());
      animation->AddUpdateListener(this);
    }
  }

  SetUpInOutAnimations();
}

void BaseLayer::SetUpInOutAnimations() {
  if (!layer_model_->GetInOutFrames().empty()) {
    in_out_animation_ = std::make_unique<FloatKeyframeAnimation>(
        layer_model_->GetInOutFrames());
    in_out_animation_->SetIsDiscrete();
    in_out_listener_ = std::make_unique<InOutAnimationListener>(*this);
    in_out_animation_->AddUpdateListener(in_out_listener_.get());
    SetVisible(in_out_animation_->GetValue().Get() == 1.0);
    AddAnimation(in_out_animation_.get());
  } else {
    SetVisible(true);
  }
}

void BaseLayer::Draw(Canvas& canvas, Matrix& parent_matrix,
                     int32_t parent_alpha) {
  if (!visible_ || layer_model_->IsHidden()) {
    return;
  }

  BuildParentLayerListIfNeeded();

  matrix_->Reset();
  matrix_->Set(parent_matrix);

  for (auto it = parent_layers_.rbegin(); it != parent_layers_.rend(); it++) {
    matrix_->PreConcat((*it)->transform_->GetMatrix());
  }

  int32_t opacity = 100;
  auto opacity_animation = transform_->GetOpacity();
  if (opacity_animation) {
    auto opacity_value = opacity_animation->GetValue().Get();
    if (opacity_value != Integer::Min()) {
      opacity = opacity_value;
    }
  }

  auto alpha = (parent_alpha / 255.0 * (opacity / 100.0) * 255.0);
  if (!HasMatteOnThisLayer() && !HasMaskOnThisLayer()) {
    matrix_->PreConcat(transform_->GetMatrix());
    DrawLayer(canvas, *matrix_, alpha);
    return;
  }

  GetBounds(rect_, *matrix_, false);

  IntersectBoundsWithMatte(rect_, parent_matrix);

  matrix_->PreConcat(transform_->GetMatrix());
  IntersectBoundsWithMask(rect_, *matrix_);

  canvas_bounds_.Set(0, 0, canvas.GetWidth(), canvas.GetHeight());
  canvas_matrix_ = canvas.GetMatrix();

  if (!canvas_matrix_->IsIdentity()) {
    canvas_matrix_->Invert(*canvas_matrix_);
    canvas_matrix_->MapRect(canvas_bounds_);
  }
  if (!rect_.Intersect(canvas_bounds_)) {
    rect_.Set(0, 0, 0, 0);
  }

  if (rect_.GetWidth() >= 1 && rect_.GetHeight() >= 1) {
    content_paint_->SetAlpha(255);
    canvas.SaveLayer(rect_, *content_paint_);

    ClearCanvas(canvas);

    DrawLayer(canvas, *matrix_, alpha);

    if (HasMaskOnThisLayer()) {
      ApplyMasks(canvas, *matrix_);
    }

    if (HasMatteOnThisLayer()) {
      canvas.SaveLayer(
          rect_,
          *matte_paint_);  // TODO(aiyongbiao): save layer missing params p0

      ClearCanvas(canvas);
      matte_layer_->Draw(canvas, parent_matrix, alpha);
      canvas.Restore();
    }

    canvas.Restore();
  }

  if (outline_maks_and_mattes_ && outline_masks_and_mattes_paint_) {
    // stroke
    outline_masks_and_mattes_paint_->SetStyle(PaintStyle::kStroke);
    auto color =
        std::string("#FFFC2803");  // TODO(aiyongbiao): may improve this p1
    auto out_color1 = Color::ParseColor(color);
    outline_masks_and_mattes_paint_->SetColor(out_color1);
    outline_masks_and_mattes_paint_->SetStrokeWidth(4);
    canvas.DrawRect(rect_, *outline_masks_and_mattes_paint_);

    // fill
    outline_masks_and_mattes_paint_->SetStyle(PaintStyle::kFill);
    auto fill_color = std::string("#50EBEBEB");
    auto out_color2 = Color::ParseColor(color);
    outline_masks_and_mattes_paint_->SetColor(out_color2);
    canvas.DrawRect(rect_, *outline_masks_and_mattes_paint_);
  }
}

void BaseLayer::ApplyMasks(Canvas& canvas, Matrix& matrix) {
  canvas.SaveLayer(rect_, *dst_in_paint_);  // TODO(aiyongbiao): opt this p1
  // TODO(aiyongbiao): may need clear canvas p1

  auto& masks = mask_->GetMasks();
  for (auto i = 0; i < masks.size(); i++) {
    auto& mask = masks[i];
    auto& mask_animation = *mask_->GetMaskAnimations()[i];
    auto& opacity_animation = *mask_->GetOpacityAnimations()[i];
    switch (mask->mask_mode_) {
      case MaskMode::kNone:
        if (AreAllMasksNone()) {
          content_paint_->SetAlpha(255);
          canvas.DrawRect(rect_, *content_paint_);
        }
        break;
      case MaskMode::kAdd:
        if (mask->inverted_) {
          ApplyInvertedAddMask(canvas, matrix, mask_animation,
                               opacity_animation);
        } else {
          ApplyAddMask(canvas, matrix, mask_animation, opacity_animation);
        }
        break;
      case MaskMode::kSubtract:
        if (i == 0) {
          content_paint_->SetColor(Color(255, 0, 0, 0));
          content_paint_->SetAlpha(255);
          canvas.DrawRect(rect_, *content_paint_);
        }
        if (mask->inverted_) {
          ApplyInvertedSubtractMask(canvas, matrix, mask_animation,
                                    opacity_animation);
        } else {
          ApplySubtractMask(canvas, matrix, mask_animation, opacity_animation);
        }
        break;
      case MaskMode::kIntersect:
        if (mask->inverted_) {
          ApplyInvertedIntersectMask(canvas, matrix, mask_animation,
                                     opacity_animation);
        } else {
          ApplyIntersectMask(canvas, matrix, mask_animation, opacity_animation);
        }
        break;
    }
  }
  canvas.Restore();
}

bool BaseLayer::AreAllMasksNone() {
  if (mask_->GetMaskAnimations().empty()) {
    return false;
  }
  for (auto& mask : mask_->GetMasks()) {
    if (mask->mask_mode_ != MaskMode::kNone) {
      return false;
    }
  }
  return true;
}

void BaseLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                          bool apply_parent) {
  rect_.Set(0, 0, 0, 0);
  BuildParentLayerListIfNeeded();
  bounds_matrix_->Set(parent_matrix);

  if (apply_parent) {
    if (!parent_layers_.empty()) {
      for (auto it = parent_layers_.rbegin(); it != parent_layers_.rend();
           it++) {
        bounds_matrix_->PreConcat((*it)->transform_->GetMatrix());
      }
    } else if (parent_layer_) {
      bounds_matrix_->PreConcat(parent_layer_->transform_->GetMatrix());
    }
  }

  bounds_matrix_->PreConcat(transform_->GetMatrix());
}

void BaseLayer::SetVisible(bool visible) {
  if (visible_ != visible) {
    visible_ = visible;
  }
}

void BaseLayer::SetProgress(float progress) {
  transform_->SetProgress(progress);

  if (mask_) {
    for (auto& animation : mask_->GetMaskAnimations()) {
      animation->SetProgress(progress);
    }
  }

  if (in_out_animation_) {
    in_out_animation_->SetProgress(progress);
  }

  if (matte_layer_) {
    matte_layer_->SetProgress(progress);
  }

  for (auto& animation : animations_) {
    animation->SetProgress(progress);
  }
}

void BaseLayer::BuildParentLayerListIfNeeded() {
  if (parent_layer_ == nullptr) {
    return;
  }

  if (!parent_layers_.empty()) {
    return;
  }

  auto layer = parent_layer_;
  while (layer) {
    parent_layers_.push_back(layer);
    layer = layer->parent_layer_;
  }
}

void BaseLayer::IntersectBoundsWithMatte(RectF& rect, Matrix& matrix) {
  if (!HasMatteOnThisLayer()) {
    return;
  }

  if (layer_model_->GetMatteType() == MatteType::kInvert) {
    return;
  }

  matte_bounds_rect_.Set(0, 0, 0, 0);
  matte_layer_->GetBounds(matte_bounds_rect_, matrix, true);
  bool intersect = rect.Intersect(matte_bounds_rect_);
  if (!intersect) {
    rect.Set(0, 0, 0, 0);
  }
}

void BaseLayer::IntersectBoundsWithMask(RectF& rect, Matrix& matrix) {
  mask_bounds_rect_.Set(0, 0, 0, 0);
  if (!HasMaskOnThisLayer()) {
    return;
  }
  auto& masks = mask_->GetMasks();
  for (auto i = 0; i < masks.size(); i++) {
    auto& mask = masks[i];
    auto& mask_animation = mask_->GetMaskAnimations()[i];
    const auto& mask_path = mask_animation->GetValue();
    //        if (mask_path == nullptr) {
    //            continue;
    //        }
    path_->Set(mask_path.get());
    path_->Transform(matrix);

    switch (mask->mask_mode_) {
      case MaskMode::kNone:
        return;
      case MaskMode::kSubtract:
        return;
      case MaskMode::kIntersect:
      case MaskMode::kAdd:
        if (mask->inverted_) {
          return;
        }
      default:
        path_->ComputeBounds(temp_mask_bounds_rect_, false);
        if (i == 0) {
          mask_bounds_rect_.Set(temp_mask_bounds_rect_);
        } else {
          mask_bounds_rect_.Set(std::min(mask_bounds_rect_.GetLeft(),
                                         temp_mask_bounds_rect_.GetLeft()),
                                std::min(mask_bounds_rect_.GetTop(),
                                         temp_mask_bounds_rect_.GetTop()),
                                std::max(mask_bounds_rect_.GetRight(),
                                         temp_mask_bounds_rect_.GetRight()),
                                std::max(mask_bounds_rect_.GetBottom(),
                                         temp_mask_bounds_rect_.GetBottom()));
        }
    }
  }

  bool intersects = rect.Intersect(mask_bounds_rect_);
  if (!intersects) {
    rect.Set(0, 0, 0, 0);
  }
}

void BaseLayer::ClearCanvas(Canvas& canvas) {
  canvas.DrawRect(rect_.GetLeft() - 1, rect_.GetTop() - 1, rect_.GetRight() + 1,
                  rect_.GetBottom() + 1, *clear_paint_);
}

void BaseLayer::ApplyInvertedAddMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  BaseLayer::ApplyInvertedMask(canvas, matrix, mask_animation,
                               opacity_animation, *content_paint_,
                               *content_paint_);
}

void BaseLayer::ApplyAddMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  const auto& mask_path = mask_animation.GetValue();
  path_->Set(mask_path.get());
  path_->Transform(matrix);
  content_paint_->SetAlpha(opacity_animation.GetValue().Get() * 2.55);
  canvas.DrawPath(*path_, *content_paint_);
}

void BaseLayer::ApplyInvertedSubtractMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  BaseLayer::ApplyInvertedMask(canvas, matrix, mask_animation,
                               opacity_animation, *dst_out_paint_,
                               *dst_out_paint_);
}

void BaseLayer::ApplySubtractMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  const auto& mask_path = mask_animation.GetValue();
  path_->Set(mask_path.get());
  path_->Transform(matrix);
  canvas.DrawPath(*path_, *dst_out_paint_);
}

void BaseLayer::ApplyInvertedIntersectMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  BaseLayer::ApplyInvertedMask(canvas, matrix, mask_animation,
                               opacity_animation, *dst_in_paint_,
                               *dst_out_paint_);
}

void BaseLayer::ApplyIntersectMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation) {
  canvas.SaveLayer(rect_, *dst_in_paint_);
  const auto& mask_path = mask_animation.GetValue();
  path_->Set(mask_path.get());
  path_->Transform(matrix);
  content_paint_->SetAlpha(opacity_animation.GetValue().Get() * 2.55);
  canvas.DrawPath(*path_, *content_paint_);
  canvas.Restore();
}

void BaseLayer::ApplyInvertedMask(
    Canvas& canvas, Matrix& matrix,
    const BaseShapeKeyframeAnimation& mask_animation,
    const BaseIntegerKeyframeAnimation& opacity_animation, Paint& save_paint,
    Paint& alpha_paint) {
  canvas.SaveLayer(rect_, save_paint);
  canvas.DrawRect(rect_, *content_paint_);
  alpha_paint.SetAlpha(opacity_animation.GetValue().Get() * 2.55);
  const auto& mask_path = mask_animation.GetValue();
  path_->Set(mask_path.get());
  path_->Transform(matrix);
  canvas.DrawPath(*path_, *dst_out_paint_);
  canvas.Restore();
}

MaskFilter* BaseLayer::GetBlurMaskFilter(float radius) {
  if (blur_mask_filter_radius_ == radius) {
    return blur_mask_filter_.get();
  }
  blur_mask_filter_ = Context::MakeBlurFilter(radius / 2.f);
  blur_mask_filter_radius_ = radius;
  return blur_mask_filter_.get();
}

}  // namespace animax
}  // namespace lynx
