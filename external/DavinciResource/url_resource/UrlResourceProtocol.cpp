//
// Created by wangchengyi.1 on 2021/4/27.
//

#include <DAVResourceIdParser.h>

#include <utility>
#include "UrlResourceProtocol.h"


ENUM_STR_IMPLEMENT(davinci::resource::UrlResourceProtocol::PLATFORM_STRING, "url_resource");
ENUM_STR_IMPLEMENT(davinci::resource::UrlResourceProtocol::KEY_URL, "http_url");
ENUM_STR_IMPLEMENT(davinci::resource::UrlResourceProtocol::EXTRA_PARAM_SAVE_PATH, "save_path");
ENUM_STR_IMPLEMENT(davinci::resource::UrlResourceProtocol::EXTRA_PARAM_MD5, "md5");
ENUM_STR_IMPLEMENT(davinci::resource::UrlResourceProtocol::EXTRA_PARAM_AUTO_UNZIP, "auto_unzip");

std::string davinci::resource::UrlResourceProtocol::getSourceFrom() {
    return PLATFORM_STRING();
}

std::unordered_map<std::string, std::string> davinci::resource::UrlResourceProtocol::getParameters() {
    std::unordered_map<std::string, std::string> params;
    params.emplace(std::make_pair(KEY_URL(), httpUrl));
    return params;
}

bool davinci::resource::UrlResourceProtocol::isUrlResource(const davinci::resource::DavinciResourceId &resourceId) {
    auto parser = davinci::resource::DAVResourceIdParser(resourceId);
    if (parser.host == PLATFORM_STRING()) {
        return true;
    }
    return false;
}

davinci::resource::UrlResourceProtocol::UrlResourceProtocol(std::string url) : httpUrl(std::move(url)) {

}
