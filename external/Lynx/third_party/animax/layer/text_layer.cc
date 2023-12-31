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

#include "animax/layer/text_layer.h"

#include "Lynx/base/string/string_utils.h"
#include "animax/model/text/font_character_model.h"
#include "animax/render/include/context.h"
#include "animax/resource/asset/font_asset.h"

namespace lynx {
namespace animax {

TextLayer::TextLayer(std::shared_ptr<LayerModel>& layer,
                     CompositionModel& composition)
    : BaseLayer(layer, composition),
      matrix_(Context::MakeMatrix()),
      fill_paint_(Context::MakePaint()),
      stroke_paint_(Context::MakePaint()) {
  text_keyframe_animation_ = layer->GetText()->CreateAnimation();
  AddAnimation(text_keyframe_animation_.get());

  auto* text_properties = layer->GetTextProperties();
  if (text_properties) {
    if (text_properties->color_) {
      color_animation_ = text_properties->color_->CreateAnimation();
      AddAnimation(color_animation_.get());
    }
    if (text_properties->stroke_) {
      stroke_color_animation_ = text_properties->stroke_->CreateAnimation();
      AddAnimation(stroke_color_animation_.get());
    }
    if (text_properties->stroke_width_) {
      stroke_width_animation_ =
          text_properties->stroke_width_->CreateAnimation();
      AddAnimation(stroke_width_animation_.get());
    }
    if (text_properties->tracking_) {
      tracking_animation_ = text_properties->tracking_->CreateAnimation();
      AddAnimation(tracking_animation_.get());
    }
  }

  fill_paint_->SetAntiAlias(true);
  fill_paint_->SetStyle(PaintStyle::kFill);

  stroke_paint_->SetAntiAlias(true);
  stroke_paint_->SetStyle(PaintStyle::kStroke);
}

void TextLayer::Init() {
  BaseLayer::Init();

  if (text_keyframe_animation_) {
    text_keyframe_animation_->AddUpdateListener(this);
  }
  if (color_animation_) {
    color_animation_->AddUpdateListener(this);
  }
  if (stroke_width_animation_) {
    stroke_width_animation_->AddUpdateListener(this);
  }
  if (tracking_animation_) {
    tracking_animation_->AddUpdateListener(this);
  }
}

void TextLayer::DrawLayer(Canvas& canvas, Matrix& matrix, int32_t alpha) {
  const auto& document_data = text_keyframe_animation_->GetValue();
  auto& fonts = composition_.GetFonts();
  if (fonts.find(document_data.font_name_) == fonts.end()) {
    return;
  }

  canvas.Save();
  canvas.Concat(matrix);

  ConfigurePaint(document_data, matrix);

  auto& font = *fonts[document_data.font_name_];
  if (composition_.UseTextGlyphs()) {
    DrawTextWithGlyphs(document_data, matrix, font, canvas);
  } else {
    DrawTextWithFont(document_data, font, canvas);
  }

  canvas.Restore();
}

void TextLayer::GetBounds(RectF& out_bounds, Matrix& parent_matrix,
                          bool apply_parent) {
  BaseLayer::GetBounds(out_bounds, parent_matrix, apply_parent);
  auto& bounds = composition_.GetBounds();
  out_bounds.Set(0, 0, bounds.GetWidth(), bounds.GetHeight());
}

void TextLayer::ConfigurePaint(const DocumentDataModel& document_data,
                               Matrix& parent_matrix) {
  if (color_callback_animation_) {
    fill_paint_->SetColor(color_callback_animation_->GetValue());
  } else if (color_animation_) {
    fill_paint_->SetColor(color_animation_->GetValue());
  } else {
    fill_paint_->SetColor(Color(document_data.color_));
  }

  if (stroke_color_callback_animation_) {
    stroke_paint_->SetColor(stroke_color_callback_animation_->GetValue());
  } else if (stroke_color_animation_) {
    stroke_paint_->SetColor(stroke_color_animation_->GetValue());
  } else {
    stroke_paint_->SetColor(Color(document_data.stroke_color_));
  }

  auto opacity = transform_->GetOpacity() == nullptr
                     ? 100
                     : transform_->GetOpacity()->GetValue().Get();
  auto alpha = opacity * 255.0 / 100.0;
  fill_paint_->SetAlpha(alpha);
  stroke_paint_->SetAlpha(alpha);

  float width;
  if (stroke_width_callback_animation_) {
    width = stroke_width_callback_animation_->GetValue().Get();
  } else if (stroke_width_animation_) {
    width = stroke_width_animation_->GetValue().Get();
  } else {
    width = document_data.stroke_width_ * composition_.GetScale();
  }

  if (width > 0) {
    stroke_paint_->SetStrokeWidth(width);
  } else {
    // width zero will be treat as not visible
    stroke_paint_->SetAlpha(0);
  }
}

void TextLayer::DrawTextWithGlyphs(const DocumentDataModel& document_data,
                                   Matrix& matrix, FontAsset& font_asset,
                                   Canvas& canvas) {
  float text_size = 0;
  if (text_size_callback_animation_) {
    text_size = text_size_callback_animation_->GetValue().Get();
  } else {
    text_size = document_data.size_;
  }
  float font_scale = text_size / 100.0;
  float parent_scale = matrix.GetScale();

  const auto& text = document_data.text_;
  std::vector<std::string> text_lines;
  GetTextLines(text, text_lines);

  auto text_line_count = text_lines.size();
  auto tracking = document_data.tracking_ / 10.0;
  if (tracking_callback_animation_) {
    tracking += tracking_callback_animation_->GetValue().Get();
  } else if (tracking_animation_) {
    tracking += tracking_animation_->GetValue().Get();
  }

  int32_t line_index = -1;
  for (auto i = 0; i < text_line_count; i++) {
    const auto& text_line = text_lines[i];
    auto box_width = document_data.box_size_.IsEmpty()
                         ? 0.0
                         : document_data.box_size_.GetX();
    std::vector<std::shared_ptr<TextSubLine>> lines;
    SplitGlyphTextIntoLines(text_line, box_width, font_asset, font_scale,
                            tracking, true, lines);
    for (auto& line : lines) {
      line_index++;

      canvas.Save();
      OffsetCanvas(canvas, document_data, line_index, line->width_);
      DrawGlyphTextLine(line->text_, document_data, font_asset, canvas,
                        parent_scale, font_scale, tracking);

      canvas.Restore();
    }
  }
}

void TextLayer::DrawTextWithFont(const DocumentDataModel& document_data,
                                 FontAsset& font_asset, Canvas& canvas) {
  auto font = font_asset.GetFont();
  if (font == nullptr) {
    return;
  }

  auto& text = document_data.text_;
  // TODO(aiyongbiao): text delegate

  float text_size = 0;
  if (text_size_callback_animation_) {
    text_size = text_size_callback_animation_->GetValue().Get();
  } else {
    text_size = document_data.size_;
  }
  font->SetTextSize(text_size * composition_.GetScale());

  float tracking = document_data.tracking_ / 10.f;
  if (tracking_callback_animation_) {
    tracking += tracking_callback_animation_->GetValue().Get();
  } else if (tracking_animation_) {
    tracking += tracking_animation_->GetValue().Get();
  }
  tracking = tracking * composition_.GetScale() * text_size / 100.f;

  std::vector<std::string> text_lines;
  GetTextLines(text, text_lines);
  auto text_line_count = text_lines.size();
  auto line_index = -1;
  for (auto i = 0; i < text_line_count; i++) {
    auto& text_line = text_lines[i];
    auto box_width = document_data.box_size_.IsEmpty()
                         ? 0.f
                         : document_data.box_size_.GetX();
    std::vector<std::shared_ptr<TextSubLine>> lines;
    SplitGlyphTextIntoLines(text_line, box_width, font_asset, 0.f, tracking,
                            false, lines);
    for (auto& line : lines) {
      line_index++;

      canvas.Save();
      OffsetCanvas(canvas, document_data, line_index, line->width_);
      DrawFontTextLine(line->text_, document_data, canvas, tracking, *font);
      canvas.Restore();
    }
  }
}

void TextLayer::GetTextLines(const std::string& text,
                             std::vector<std::string>& text_lines) {
  base::SplitString(text, '\r', text_lines);
}

void TextLayer::SplitGlyphTextIntoLines(
    const std::string& text_line, float box_width, FontAsset& font_asset,
    float font_scale, float tracking, bool using_glyphs,
    std::vector<std::shared_ptr<TextSubLine>>& text_lines) {
  int32_t line_count = 0;
  float current_line_width = 0;
  int32_t current_line_start_index = 0;
  int32_t current_word_start_index = 0;
  float current_word_width = 0;
  bool next_character_start_word = false;
  float space_width = 0;

  auto* chars = text_line.c_str();
  auto& characters = composition_.GetCharacters();
  for (auto i = 0; i < text_line.length(); i++) {
    char c = chars[i];
    float current_char_width = 0;
    if (using_glyphs) {
      auto hash =
          FontCharacterModel::HashFor(c, font_asset.family_, font_asset.style_);
      if (characters.find(hash) == characters.end()) {
        continue;
      }
      auto& character = characters[hash];
      current_char_width =
          character->GetWidth() * font_scale * composition_.GetScale() +
          tracking;
    } else {
      current_char_width =
          font_asset.GetFont()->MeasureText(text_line.substr(i, 1)) + tracking;
    }

    if (c == ' ') {
      space_width = current_char_width;
      next_character_start_word = true;
    } else if (next_character_start_word) {
      next_character_start_word = false;
      current_word_start_index = i;
      current_word_width = current_char_width;
    } else {
      current_word_width += current_char_width;
    }
    current_line_width += current_char_width;

    if (box_width > 0 && current_line_width >= box_width) {
      if (c == ' ') {
        continue;
      }
      auto sub_line = EnsureEnoughSubLines(++line_count);
      if (current_word_start_index == current_line_start_index) {
        const auto& sub_str = text_line.substr(current_line_start_index,
                                               i - current_line_start_index);
        auto trimmed = TrimText(sub_str);
        float trimmed_space =
            (trimmed.length() - sub_str.length()) * space_width;
        sub_line->Set(trimmed,
                      current_line_width - current_char_width - trimmed_space);
        current_line_start_index = i;
        current_line_width = current_char_width;
        current_word_start_index = current_line_start_index;
        current_word_width = current_char_width;
      } else {
        const auto& sub_str = text_line.substr(
            current_line_start_index,
            current_word_start_index - 1 - current_line_start_index);
        auto trimmed = TrimText(sub_str);
        float trimmed_space =
            (sub_str.length() - trimmed.length()) * space_width;
        sub_line->Set(trimmed, current_line_width - current_word_width -
                                   trimmed_space - space_width);
        current_line_start_index = current_word_start_index;
        current_line_width = current_word_width;
      }
    }
  }
  if (current_line_width > 0) {
    auto line = EnsureEnoughSubLines(++line_count);
    line->Set(text_line.substr(current_line_start_index), current_line_width);
  }

  for (auto i = 0; i < line_count; i++) {
    text_lines.push_back(text_sub_lines_[i]);
  }
}

void TextLayer::OffsetCanvas(Canvas& canvas,
                             const DocumentDataModel& document_data,
                             int32_t line_index, float line_width) {
  auto& position = document_data.box_position_;
  auto& size = document_data.box_size_;

  float scale = composition_.GetScale();
  float line_start_y =
      position.IsEmpty() ? 0.f : document_data.size_ * scale + position.GetY();
  float line_offset =
      (line_index * document_data.line_height_ * scale) + line_start_y;

  float line_start = position.IsEmpty() ? 0.0 : position.GetX();
  float box_width = size.IsEmpty() ? 0.0 : size.GetX();
  switch (document_data.justification_) {
    case DocumentJustification::kLeftAlign:
      canvas.Translate(line_start, line_offset);
      break;
    case DocumentJustification::kRightAlign:
      canvas.Translate(line_start + box_width - line_width, line_offset);
      break;
    case DocumentJustification::kCenter:
      canvas.Translate(line_start + box_width / 2.0 - line_width / 2.0,
                       line_offset);
      break;
  }
}

void TextLayer::DrawGlyphTextLine(const std::string& text,
                                  const DocumentDataModel& document_data,
                                  FontAsset& font_asset, Canvas& canvas,
                                  float parent_scale, float font_scale,
                                  float tracking) {
  auto text_chars = text.c_str();
  auto& characters = composition_.GetCharacters();
  for (auto i = 0; i < text.length(); i++) {
    auto& text_char = text_chars[i];
    auto hash = FontCharacterModel::HashFor(text_char, font_asset.family_,
                                            font_asset.style_);
    if (characters.find(hash) == characters.end()) {
      continue;
    }
    auto& character = characters[hash];
    DrawCharacterAsGlyph(character, font_scale, document_data, canvas);
    float tx =
        character->GetWidth() * font_scale * composition_.GetScale() + tracking;
    canvas.Translate(tx, 0);
  }
}

std::shared_ptr<ContentGroupList> TextLayer::GetContentsForCharacter(
    std::shared_ptr<FontCharacterModel> character) {
  if (contents_for_character_.find(character) !=
      contents_for_character_.end()) {
    return contents_for_character_[character];
  }
  auto& shapes = character->GetShapes();
  auto contents = std::make_shared<ContentGroupList>();
  for (auto& sg : shapes) {
    contents->push_back(
        std::make_unique<ContentGroup>(*this, *sg, composition_));
  }
  contents_for_character_[character] = contents;
  return contents;
}

void TextLayer::DrawCharacterAsGlyph(
    const std::shared_ptr<FontCharacterModel>& character, float font_scale,
    const DocumentDataModel& document_data, Canvas& canvas) {
  auto content_groups = GetContentsForCharacter(character);
  for (auto j = 0; j < content_groups->size(); j++) {
    auto path = content_groups->at(j)->GetPath();
    if (!path) {
      return;
    }

    path->ComputeBounds(rect_, false);
    matrix_->Reset();
    matrix_->PreTranslate(0, -document_data.baseline_shift_);
    matrix_->PreScale(font_scale, font_scale);
    path->Transform(*matrix_);
    if (document_data.stroke_overfill_) {
      DrawGlyph(*path, *fill_paint_, canvas);
      // TODO(aiyongbiao.rick): restore when stroke text function needed
      // DrawGlyph(*path, *stroke_paint_, canvas);
    } else {
      // DrawGlyph(*path, *stroke_paint_, canvas);
      DrawGlyph(*path, *fill_paint_, canvas);
    }
  }
}

void TextLayer::DrawGlyph(Path& path, Paint& paint, Canvas& canvas) {
  // TODO(aiyongbiao): trans
  // TODO(aiyongbiao): stroke
  canvas.DrawPath(path, paint);
}

std::shared_ptr<TextSubLine> TextLayer::EnsureEnoughSubLines(
    int32_t num_lines) {
  for (auto i = text_sub_lines_.size(); i < num_lines; i++) {
    text_sub_lines_.push_back(std::make_shared<TextSubLine>());
  }
  return text_sub_lines_[num_lines - 1];
}

void TextLayer::DrawFontTextLine(const std::string& text,
                                 const DocumentDataModel& document_data,
                                 Canvas& canvas, float tracking, Font& font) {
  DrawCharacterFromFont(text, document_data, canvas, font);
}

void TextLayer::DrawCharacterFromFont(const std::string& text,
                                      const DocumentDataModel& document_data,
                                      Canvas& canvas, Font& font) {
  if (document_data.stroke_overfill_) {
    DrawCharacter(text, *fill_paint_, canvas, font);
    // DrawCharacter(text, *stroke_paint_, canvas, font);
  } else {
    // DrawCharacter(text, *stroke_paint_, canvas, font);
    DrawCharacter(text, *fill_paint_, canvas, font);
  }
}

void TextLayer::DrawCharacter(const std::string& text, Paint& paint,
                              Canvas& canvas, Font& font) {
  // TODO(aiyongbiao): transparent color

  // TODO(aiyongbiao): stroke width

  canvas.DrawText(text, 0, 0, font, paint);
}

const std::string& TextLayer::CodePointToString(const std::string& text,
                                                int32_t start_index) {
  // TODO(aiyongbiao): implement this
  return text;
}

std::string TextLayer::TrimText(const std::string& s) {
  std::string::const_iterator it = s.begin();
  while (it != s.end() && isspace(*it)) it++;

  std::string::const_reverse_iterator rit = s.rbegin();
  while (rit.base() != it && isspace(*rit)) rit++;

  return std::string(it, rit.base());
}

}  // namespace animax
}  // namespace lynx
