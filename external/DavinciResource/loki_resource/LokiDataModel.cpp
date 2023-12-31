//
// Created by wangchengyi.1 on 2021/5/8.
//
#include "LokiDataModel.h"

void davinci::loki::from_json(const nlohmann::json &j, davinci::loki::UrlModel &urlModel) {
    if (j.find("url_list") != j.end()) {
        urlModel.url_list = j.at("url_list").get<std::vector<std::string>>();
    }
    if (j.find("uri") != j.end()) {
        j.at("uri").get_to(urlModel.uri);
    }
}

void davinci::loki::from_json(const nlohmann::json &j, davinci::loki::Effect &effect) {
    if (j.find("name") != j.end()) {
        j.at("name").get_to(effect.name);
    }
    if (j.find("effect_id") != j.end()) {
        j.at("effect_id").get_to(effect.effect_id);
    }
    if (j.find("requirements") != j.end()) {
        effect.requirements = j.at("requirements").get<std::vector<std::string>>();
    }
    if (j.find("file_url") != j.end()) {
        davinci::loki::UrlModel urlModel = j.at("file_url").get<davinci::loki::UrlModel>();
        effect.file_url = urlModel.url_list;
        effect.md5 = urlModel.uri;
    }
    if (j.find("model_names") != j.end()) {
        j.at("model_names").get_to(effect.model_names);
    }
}

void davinci::loki::from_json(const nlohmann::json &j, davinci::loki::EffectListResponse &response) {
    if (j.find("url_prefix") != j.end()) {
        response.url_prefix = j.at("url_prefix").get<std::vector<std::string>>();
    }
    if (j.find("data") != j.end()) {
        response.data = j.at("data").get<std::vector<davinci::loki::Effect>>();
    }
    if (j.find("status_code") != j.end()) {
        j.at("status_code").get_to(response.status_code);
    }
    if (j.find("message") != j.end()) {
        j.at("message").get_to(response.message);
    }
}

void davinci::loki::to_json(nlohmann::json &j, const davinci::loki::Effect &effect) {
    UrlModel urlModel;
    urlModel.url_list = effect.file_url;
    urlModel.uri = effect.md5;
    auto urlJson = nlohmann::json(urlModel);
    j = nlohmann::json{{"name",         effect.name},
                       {"effect_id",    effect.effect_id},
                       {"requirements", effect.requirements},
                       {"file_url",     urlJson},
                       {"model_names",  effect.model_names}};
}

void davinci::loki::to_json(nlohmann::json &j, const davinci::loki::UrlModel &urlModel) {
    j = nlohmann::json{{"url_list", urlModel.url_list},
                       {"uri",      urlModel.uri}};
}
