//
// Created by bytedance on 2021/4/16.
//
#pragma once
#ifndef DAVINCIRESOURCE_LOKIDATAMODEL_H
#define DAVINCIRESOURCE_LOKIDATAMODEL_H

#include <vector>
#include <ResponseChecker.h>
#include "nlohmann/json.hpp"
#include "Bundle.h"

namespace davinci {
    namespace loki {
        class UrlModel {
        public:
            std::string uri;
            std::vector<std::string> url_list;
        };

        class Effect: public davinci::task::BaseModel {
        public:
            std::string effect_id;
            std::string resource_id;
            std::string md5;
            std::string name;
            std::vector<std::string> file_url;
            std::vector<std::string> requirements;
            std::string model_names;
            std::string file_path;
        };

        class EffectListResponse : public ResponseChecker, public davinci::task::BaseModel {
        public:
            std::vector<Effect> bind_effects;
            std::vector<Effect> collection;
            std::vector<Effect> data;
            int status_code;
            std::string message;
            std::vector<std::string> url_prefix;

            std::string &getMessage() override {
                return message;
            }

            int getStatusCode() override {
                return status_code;
            }
        };

        void from_json(const nlohmann::json &j, davinci::loki::UrlModel &urlModel);

        void from_json(const nlohmann::json &j, davinci::loki::Effect &effect);

        void to_json(nlohmann::json &j, const davinci::loki::Effect &effect);

        void to_json(nlohmann::json &j, const davinci::loki::UrlModel &urlModel);

        void from_json(const nlohmann::json &j, davinci::loki::EffectListResponse &response);
    }
}

#endif//DAVINCIRESOURCE_LOKIDATAMODEL_H
