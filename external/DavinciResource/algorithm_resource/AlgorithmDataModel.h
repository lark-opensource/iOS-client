//
// Created by bytedance on 2021/4/16.
//
#pragma once
#ifndef DAVINCIRESOURCE_ALGORITHMDATAMODEL_H
#define DAVINCIRESOURCE_ALGORITHMDATAMODEL_H

#include <vector>
#include <json_forward.hpp>
#include <ResponseChecker.h>
#include "Bundle.h"

namespace davinci {
    namespace algorithm {
        class AlgorithmUrlModel: public davinci::task::BaseModel {
        public:
            std::string uri;
            std::vector<std::string> url_list;
            std::vector<std::string> zip_url_list;
        };

        class ModelInfo: public davinci::task::BaseModel {
        public:
            std::string name;
            std::string version;
            long type;
            AlgorithmUrlModel file_url;
            int status;
        };

        class ModelInfoMap: public davinci::task::BaseModel {
        public:
            std::unordered_map<std::string, std::vector<ModelInfo>> arithmetics;
        };

        class ModelInfoResponse : public ResponseChecker {
        public:
            ModelInfoMap data;
            int status_code;
            std::string message;

            std::string &getMessage() override {
                return message;
            }

            int getStatusCode() override {
                return status_code;
            }
        };

        void from_json(const nlohmann::json &j, AlgorithmUrlModel &urlModel);

        void from_json(const nlohmann::json &j, ModelInfo &modelInfo);

        void from_json(const nlohmann::json &j, davinci::algorithm::ModelInfoMap &modelInfoMap);

        void from_json(const nlohmann::json &j, ModelInfoResponse &modelsInfoResponse);
    }
}
#endif//DAVINCIRESOURCE_ALGORITHMDATAMODEL_H
