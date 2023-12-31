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

#ifndef ANIMAX_LAYER_TEXT_LAYER_H_
#define ANIMAX_LAYER_TEXT_LAYER_H_

#include "animax/content/content_group.h"
#include "animax/layer/base_layer.h"
#include "animax/model/basic_model.h"
#include "animax/model/text/document_data_model.h"
#include "animax/render/include/font.h"

namespace lynx {
namespace animax {

class TextSubLine {
 public:
  TextSubLine() = default;
  void Set(const std::string& text, float width) {
    text_ = text;
    width_ = width;
  }

 private:
  friend class TextLayer;
  std::string text_;
  float width_ = 0;
};

using ContentGroupList = std::vector<std::unique_ptr<ContentGroup>>;
using FontContentMap = std::unordered_map<std::shared_ptr<FontCharacterModel>,
                                          std::shared_ptr<ContentGroupList>>;
using FontAnimation = std::unique_ptr<
    BaseKeyframeAnimation<std::shared_ptr<Font>, std::shared_ptr<Font>>>;

class TextLayer : public BaseLayer {
 public:
  TextLayer(std::shared_ptr<LayerModel>& layer, CompositionModel& composition);

  void Init() override;
  void DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) override;
  void GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                 bool apply_parent) override;

  // TODO(aiyongbiao): callabck method
 private:
  void ConfigurePaint(const DocumentDataModel& document_data,
                      Matrix& parent_matrix);

  void DrawTextWithGlyphs(const DocumentDataModel& document_data,
                          Matrix& matrix, FontAsset& font_asset,
                          Canvas& canvas);
  void DrawTextWithFont(const DocumentDataModel& document_data,
                        FontAsset& font_asset, Canvas& canvas);

  void GetTextLines(const std::string& text,
                    std::vector<std::string>& text_lines);
  void SplitGlyphTextIntoLines(
      const std::string& text_line, float box_width, FontAsset& font_asset,
      float font_scale, float tracking, bool using_glyphs,
      std::vector<std::shared_ptr<TextSubLine>>& text_lines);
  void OffsetCanvas(Canvas& canvas, const DocumentDataModel& document_data,
                    int32_t line_index, float line_width);
  void DrawGlyphTextLine(const std::string& text,
                         const DocumentDataModel& document_data,
                         FontAsset& font_asset, Canvas& canvas,
                         float parent_scale, float font_scale, float tracking);

  std::shared_ptr<ContentGroupList> GetContentsForCharacter(
      std::shared_ptr<FontCharacterModel> character);
  void DrawCharacterAsGlyph(
      const std::shared_ptr<FontCharacterModel>& character, float font_scale,
      const DocumentDataModel& document_data, Canvas& canvas);
  void DrawGlyph(Path& path, Paint& paint, Canvas& canvas);

  void DrawFontTextLine(const std::string& text,
                        const DocumentDataModel& document_data, Canvas& canvas,
                        float tracking, Font& font);
  void DrawCharacterFromFont(const std::string& text,
                             const DocumentDataModel& document_data,
                             Canvas& canvas, Font& font);
  void DrawCharacter(const std::string& text, Paint& paint, Canvas& canvas,
                     Font& font);

  std::shared_ptr<TextSubLine> EnsureEnoughSubLines(int32_t num_lines);
  const std::string& CodePointToString(const std::string& text,
                                       int32_t start_index);

  std::string TrimText(const std::string& s);

  RectF rect_;
  std::unique_ptr<Matrix> matrix_;
  std::unique_ptr<Paint> fill_paint_;
  std::unique_ptr<Paint> stroke_paint_;

  FontContentMap contents_for_character_;
  std::unordered_map<int32_t, std::string> code_point_cache_;
  std::vector<std::shared_ptr<TextSubLine>> text_sub_lines_;

  std::unique_ptr<BaseTextKeyframeAnimation> text_keyframe_animation_;

  std::unique_ptr<BaseColorKeyframeAnimation> color_animation_;
  std::unique_ptr<BaseColorKeyframeAnimation> stroke_color_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> stroke_width_animation_;
  std::unique_ptr<BaseFloatKeyframeAnimation> tracking_animation_;

  std::unique_ptr<BaseColorKeyframeAnimation> color_callback_animation_ =
      nullptr;
  std::unique_ptr<BaseColorKeyframeAnimation> stroke_color_callback_animation_ =
      nullptr;
  std::unique_ptr<BaseFloatKeyframeAnimation> stroke_width_callback_animation_ =
      nullptr;
  std::unique_ptr<BaseFloatKeyframeAnimation> tracking_callback_animation_ =
      nullptr;
  std::unique_ptr<BaseFloatKeyframeAnimation> text_size_callback_animation_ =
      nullptr;

  FontAnimation font_animation_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_LAYER_TEXT_LAYER_H_
