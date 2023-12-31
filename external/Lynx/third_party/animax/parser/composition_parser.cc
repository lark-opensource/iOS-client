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

#include "animax/parser/composition_parser.h"

#include <string.h>

#include "animax/base/log.h"
#include "animax/model/composition_model.h"
#include "animax/parser/layer_parser.h"
#include "animax/resource/asset/image_asset.h"
#include "text/font_character_parser.h"
#include "text/font_parser.h"

namespace lynx {
namespace animax {

std::shared_ptr<CompositionModel> CompositionParser::Parse(const char* str_data,
                                                           size_t length,
                                                           float scale) {
  rapidjson::Document document;
  document.Parse(str_data, length);
  if (document.HasParseError()) {
    ANIMAX_LOGE("CompositionParser.Parse error_code:"
                << std::to_string(document.GetParseError())
                << ", msg:" << document.GetParseErrorMsg());
    return nullptr;
  }

  if (!document.IsObject()) {
    ANIMAX_LOGE("document is not a object");
    return nullptr;
  }

  auto composition_model = std::make_shared<CompositionModel>(scale);
  int32_t width = 0, height = 0;
  float start_frame = 0, end_frame = 0, frame_rate = 0;

  for (auto it = document.MemberBegin(); it != document.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "w") == 0) {
      width = it->value.GetInt();
    } else if (strcmp(key, "h") == 0) {
      height = it->value.GetInt();
    } else if (strcmp(key, "ip") == 0) {
      start_frame = it->value.GetFloat();
    } else if (strcmp(key, "op") == 0) {
      end_frame = it->value.GetFloat() - 0.01f;
    } else if (strcmp(key, "fr") == 0) {
      frame_rate = it->value.GetFloat();
    } else if (strcmp(key, "v") == 0) {
      const auto& version = it->value.GetString();
      ANIMAX_LOGI("current json file version:") << version;
    } else if (strcmp(key, "layers") == 0) {
      ParseLayers(it->value, *composition_model);
    } else if (strcmp(key, "assets") == 0) {
      ParseAssets(it->value, *composition_model);
    } else if (strcmp(key, "fonts") == 0) {
      ParseFonts(it->value, *composition_model);
    } else if (strcmp(key, "chars") == 0) {
      ParseChars(it->value, *composition_model);
    } else if (strcmp(key, "markers") == 0) {
      ParseMarkers(it->value, *composition_model);
    }
  }

  auto rect = std::make_unique<Rect>(0, scale * width, 0, scale * height);

  ANIMAX_LOGI("total layers size:")
      << std::to_string(composition_model->GetLayers()->size());
  composition_model->Init(std::move(rect), start_frame, end_frame, frame_rate);

  return composition_model;
}

void CompositionParser::ParseLayers(rapidjson::Value& value,
                                    CompositionModel& composition) {
  const auto& array = value.GetArray();
  int32_t image_count = 0;

  auto& layers = composition.GetLayers();
  auto& layer_map = composition.GetLayerMap();
  for (auto it = array.Begin(); it != array.End(); it++) {
    auto layer = LayerParser::Instance().Parse(it->Move(), composition);
    if (layer->GetLayerType() == LayerType::kImage) {
      image_count++;
    }
    layers->push_back(layer);
    layer_map[layer->GetId()] = layer;
  }

  if (image_count > 4) {
    ANIMAX_LOGI("image layer count is larger than 4, image_count:")
        << std::to_string(image_count);
  }
}

void CompositionParser::ParseAssets(rapidjson::Value& value,
                                    CompositionModel& composition) {
  const auto& array = value.GetArray();
  auto& precomps = composition.GetPrecomps();
  auto& images = composition.GetImages();

  for (auto it = array.Begin(); it != array.End(); it++) {
    std::string id;
    auto layers = std::make_shared<LayerModelList>();

    int32_t width = 0, height = 0;
    std::string image_file_name;
    std::string relative_folder;

    const auto& object = it->GetObject();
    for (auto object_it = object.MemberBegin(); object_it != object.MemberEnd();
         object_it++) {
      const auto& object_key = object_it->name.GetString();
      if (strcmp(object_key, "id") == 0) {
        id = object_it->value.GetString();
      } else if (strcmp(object_key, "layers") == 0) {
        const auto& layer_array = object_it->value.GetArray();
        for (auto layer_it = layer_array.Begin(); layer_it != layer_array.End();
             layer_it++) {
          auto layer_model =
              LayerParser::Instance().Parse(layer_it->Move(), composition);
          layers->push_back(layer_model);
        }
      } else if (strcmp(object_key, "w") == 0) {
        width = object_it->value.GetInt();
      } else if (strcmp(object_key, "h") == 0) {
        height = object_it->value.GetInt();
      } else if (strcmp(object_key, "p") == 0) {
        image_file_name = object_it->value.GetString();
      } else if (strcmp(object_key, "u") == 0) {
        relative_folder = object_it->value.GetString();
      }
    }

    if (!image_file_name.empty()) {
      images[id] = std::make_shared<ImageAsset>(
          width, height, id, image_file_name, relative_folder);
    } else {
      precomps[id] = layers;
    }
  }
}

void CompositionParser::ParseFonts(rapidjson::Value& value,
                                   CompositionModel& composition) {
  auto& fonts = composition.GetFonts();
  const auto& object = value.GetObject();
  for (auto it = object.MemberBegin(); it != object.MemberEnd(); it++) {
    const auto& key = it->name.GetString();
    if (strcmp(key, "list") == 0) {
      const auto& array = it->value.GetArray();
      for (auto array_it = array.Begin(); array_it != array.End(); array_it++) {
        auto font = FontParser::Instance().Parse(array_it->Move(), composition);
        fonts[font->GetName()] = font;
      }
    }
  }
}

void CompositionParser::ParseChars(rapidjson::Value& value,
                                   CompositionModel& composition) {
  auto& characters = composition.GetCharacters();
  const auto& array = value.GetArray();
  for (auto array_it = array.Begin(); array_it != array.End(); array_it++) {
    auto character =
        FontCharacterParser::Instance().Parse(array_it->Move(), composition);
    characters[character->HashCode()] = character;
  }
}

void CompositionParser::ParseMarkers(rapidjson::Value& value,
                                     CompositionModel& composition) {
  auto& markers = composition.GetMarkers();
  const auto& array = value.GetArray();
  for (auto it = array.Begin(); it != array.End(); it++) {
    const auto& object = it->GetObject();
    for (auto object_it = object.MemberBegin(); object_it != object.MemberEnd();
         object_it++) {
      const auto& name = object_it->name.GetString();

      std::string comment;
      float frame = 0;
      float duration_frames = 0;
      if (strcmp(name, "cm") == 0) {
        comment = object_it->value.GetString();
      } else if (strcmp(name, "tm") == 0) {
        frame = object_it->value.GetFloat();
      } else if (strcmp(name, "dr") == 0) {
        duration_frames = object_it->value.GetFloat();
      }

      markers.push_back(std::make_shared<MarkerModel>(std::move(comment), frame,
                                                      duration_frames));
    }
  }
}

}  // namespace animax
}  // namespace lynx
