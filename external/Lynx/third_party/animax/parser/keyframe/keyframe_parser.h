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

#ifndef ANIMAX_PARSER_KEYFRAME_KEYFRAME_PARSER_H_
#define ANIMAX_PARSER_KEYFRAME_KEYFRAME_PARSER_H_

#include <vector>

#include "animax/animation/interpolator/interpolator.h"
#include "animax/model/composition_model.h"
#include "animax/model/keyframe/keyframe_model.h"
#include "animax/parser/base_parser.h"
#include "animax/parser/keyframe/json_parser.h"
#include "animax/parser/value_parser.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace animax {

class KeyframeParser : public BaseParser<KeyframeParser> {
 public:
  template <typename T>
  std::unique_ptr<KeyframeModel<T>> Parse(rapidjson::Value& value,
                                          CompositionModel& composition,
                                          float scale,
                                          ValueParser<T>& value_parser,
                                          bool animated, bool multi_dimen) {
    if (animated && multi_dimen) {
      return ParseMultiDimensionalKeyframe(value, composition, scale,
                                           value_parser);
    } else if (animated) {
      return ParseKeyframe(value, composition, scale, value_parser);
    } else {
      return ParseStaticValue(value, composition, scale, value_parser);
    }
  }

  template <typename T>
  std::unique_ptr<KeyframeModel<T>> ParseMultiDimensionalKeyframe(
      rapidjson::Value& value, CompositionModel& composition, float scale,
      ValueParser<T>& value_parser) {
    PointF cp1 = PointF::MakeEmpty();
    PointF cp2 = PointF::MakeEmpty();

    PointF x_cp1 = PointF::MakeEmpty();
    PointF x_cp2 = PointF::MakeEmpty();
    PointF y_cp1 = PointF::MakeEmpty();
    PointF y_cp2 = PointF::MakeEmpty();

    float start_frame = 0;
    T start_value = T::MakeEmpty();
    T end_value = T::MakeEmpty();
    bool hold = false;

    std::unique_ptr<Interpolator> interpolator;
    std::unique_ptr<Interpolator> x_interpolator;
    std::unique_ptr<Interpolator> y_interpolator;

    PointF path_cp1 = PointF::MakeEmpty();
    PointF path_cp2 = PointF::MakeEmpty();

    const auto& object = value.GetObject();
    for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
      const auto& key = it->name.GetString();
      if (strcmp(key, "t") == 0) {
        start_frame = it->value.GetFloat();
      } else if (strcmp(key, "s") == 0) {
        end_value = value_parser.Parse(it->value, scale);
      } else if (strcmp(key, "e") == 0) {
        end_value = value_parser.Parse(it->value, scale);
      } else if (strcmp(key, "o") == 0) {
        if (it->value.IsObject()) {
          ParseControlPoints(it->value, x_cp1, y_cp1);
        } else {
          cp1 = JsonParser::Instance().JsonToPoint(it->value, scale);
        }
      } else if (strcmp(key, "i") == 0) {
        if (it->value.IsObject()) {
          ParseControlPoints(it->value, y_cp1, y_cp2);
        } else {
          cp2 = JsonParser::Instance().JsonToPoint(it->value, scale);
        }
      } else if (strcmp(key, "h") == 0) {
        hold = it->value.GetInt() == 1;
      } else if (strcmp(key, "to") == 0) {
        path_cp1 = JsonParser::Instance().JsonToPoint(it->value, scale);
      } else if (strcmp(key, "ti") == 0) {
        path_cp2 = JsonParser::Instance().JsonToPoint(it->value, scale);
      }
    }

    if (hold) {
      end_value = start_value;
      interpolator = LinearInterpolator::Make();
    } else if (!cp1.IsEmpty() && !cp2.IsEmpty()) {
      interpolator = PathInterpolator::Make(cp1, cp2);
    } else if (!x_cp1.IsEmpty() && !y_cp1.IsEmpty() && !x_cp2.IsEmpty() &&
               !y_cp2.IsEmpty()) {
      x_interpolator = PathInterpolator::Make(x_cp1, x_cp2);
      y_interpolator = PathInterpolator::Make(y_cp1, y_cp2);
    } else {
      interpolator = LinearInterpolator::Make();
    }

    std::unique_ptr<KeyframeModel<T>> keyframe;
    if (x_interpolator && y_interpolator) {
      keyframe = std::make_unique<KeyframeModel<T>>(
          composition, start_value, end_value, std::move(x_interpolator),
          std::move(y_interpolator), start_frame, Float::Min());
    } else {
      keyframe = std::make_unique<KeyframeModel<T>>(
          composition, start_value, end_value, std::move(interpolator),
          start_frame, Float::Min());
    }

    keyframe->SetPathCps(path_cp1, path_cp2);
    return keyframe;
  }

  void ParseControlPoints(rapidjson::Value& value, PointF& x_cp, PointF& y_cp) {
    float x_cp_x = 0, x_cp_y = 0, y_cp_x = 0, y_cp_y = 0;
    const auto& object = value.GetObject();
    for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
      const auto& name = it->name.GetString();
      if (strcmp(name, "x") == 0) {
        if (it->value.IsNumber()) {
          x_cp_x = it->value.GetFloat();
          y_cp_x = x_cp_x;
        } else {
          const auto& array = it->value.GetArray();
          for (auto i = 0; i < array.Size(); i++) {
            auto point = (array.Begin() + i)->GetFloat();
            if (i == 0) {
              x_cp_x = point;
            } else if (i == 1) {
              y_cp_x = point;
            }
          }
          if (array.Size() <= 1) {
            y_cp_x = x_cp_x;
          }
        }
      } else if (strcmp(name, "y") == 0) {
        if (it->value.IsNumber()) {
          x_cp_y = it->value.GetFloat();
          y_cp_y = x_cp_y;
        } else {
          const auto& array = it->value.GetArray();
          for (auto i = 0; i < array.Size(); i++) {
            auto point = (array.Begin() + i)->GetFloat();
            if (i == 0) {
              x_cp_y = point;
            } else if (i == 1) {
              y_cp_y = point;
            }
          }
          if (array.Size() <= 1) {
            y_cp_y = x_cp_y;
          }
        }
      }
    }
    x_cp = PointF::Make(x_cp_x, x_cp_y);
    y_cp = PointF::Make(y_cp_x, y_cp_y);
  }

  template <typename T>
  std::unique_ptr<KeyframeModel<T>> ParseKeyframe(
      rapidjson::Value& value, CompositionModel& composition, float scale,
      ValueParser<T>& value_parser) {
    PointF cp1 = PointF::MakeEmpty();
    PointF cp2 = PointF::MakeEmpty();
    float start_frame = 0;
    T start_value = T::MakeEmpty();
    T end_value = T::MakeEmpty();
    bool hold = false;
    std::unique_ptr<Interpolator> interpolator;

    PointF path_cp1 = PointF::MakeEmpty();
    PointF path_cp2 = PointF::MakeEmpty();

    const auto& object = value.GetObject();
    for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
      const auto& key = it->name.GetString();
      if (strcmp(key, "t") == 0) {
        start_frame = it->value.GetFloat();
      } else if (strcmp(key, "s") == 0) {
        start_value = value_parser.Parse(it->value, scale);
      } else if (strcmp(key, "e") == 0) {
        end_value = value_parser.Parse(it->value, scale);
      } else if (strcmp(key, "o") == 0) {
        cp1 = JsonParser::Instance().JsonToPoint(it->value, 1);
      } else if (strcmp(key, "i") == 0) {
        cp2 = JsonParser::Instance().JsonToPoint(it->value, 1);
      } else if (strcmp(key, "h") == 0) {
        hold = it->value.GetInt() == 1;
      } else if (strcmp(key, "to") == 0) {
        path_cp1 = JsonParser::Instance().JsonToPoint(it->value, scale);
      } else if (strcmp(key, "ti") == 0) {
        path_cp2 = JsonParser::Instance().JsonToPoint(it->value, scale);
      }
    }

    if (hold) {
      end_value = start_value;
      interpolator = LinearInterpolator::Make();
    } else if (!cp1.IsEmpty() && !cp2.IsEmpty()) {
      interpolator = PathInterpolator::Make(cp1, cp2);
    } else {
      interpolator = LinearInterpolator::Make();
    }

    auto keyframe = std::make_unique<KeyframeModel<T>>(
        composition, start_value, end_value, std::move(interpolator),
        start_frame, Float::Min());
    keyframe->SetPathCps(path_cp1, path_cp2);

    return keyframe;
  }

  template <typename T>
  std::unique_ptr<KeyframeModel<T>> ParseStaticValue(
      rapidjson::Value& value, CompositionModel& composition, float scale,
      ValueParser<T>& value_parser) {
    return std::make_unique<KeyframeModel<T>>(composition,
                                              value_parser.Parse(value, scale));
  }
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_PARSER_KEYFRAME_KEYFRAME_PARSER_H_
