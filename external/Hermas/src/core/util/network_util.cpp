//
//  network_util.cpp
//  Hermas
//
//  Created by ByteDance on 2023/9/5.
//

#include "network_util.h"
#include "string_util.h"

namespace hermas {

std::string urlWithHostAndPath(const std::string& host, const std::string& path) {
    std::string urlprefixCheck = "http";
    std::string defaultUrlPrefix = "https://";
    if (isPrefix(path, urlprefixCheck)) {
        return path;
    }
    
    std::string url;
    if (isPrefix(host, urlprefixCheck)) {
        url = host;
    } else {
        url = defaultUrlPrefix + host;
    }
    
    if (path.empty() || path.size() == 0) {
        return url;
    }
    
    std::string pathPrefix = "/";
    if (isPrefix(path, pathPrefix) || isSuffix(url, pathPrefix)) {
        url = url + path;
    } else {
        url = url + "/" + path;
    }
    
    return url;
}

}
