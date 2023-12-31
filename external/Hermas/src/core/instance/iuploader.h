//
//  iuploader.h
//  Hermas
//
//  Created by 崔晓兵 on 12/1/2022.
//

#pragma once

#include <string>
#include <map>

namespace hermas {

struct ResponseStruct {
    virtual ~ResponseStruct() = default;
    long code = -1;
    std::string response_data;
};

struct RequestStruct {
    virtual ~RequestStruct() = default;
    RequestStruct(const std::string& url,
                  const std::string& method,
                  const std::map<std::string, std::string>& header_field,
                  const std::string& request_data,
                  bool need_encrypt = false) : url(url), method(method), header_field(header_field), request_data(request_data), need_encrypt(need_encrypt) {}
    std::string url;
    std::string method;
    std::map<std::string, std::string> header_field;
    std::string request_data;
    bool need_encrypt;
};

struct IUploader {
    virtual ~IUploader() = default;
    
    virtual std::shared_ptr<ResponseStruct> Upload(RequestStruct& request) = 0;
    
    virtual void UploadSuccess(const std::string& module_id) = 0;
    
    virtual void UploadFailure(const std::string& module_id) = 0;
};

}

