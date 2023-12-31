//  Created by 黄清 on 2020/5/24.
//

#ifndef VCUtilBridge_hpp
#define VCUtilBridge_hpp
#pragma once

#include "vc_base.h"
#include "vc_json.h"
#include <string>

@class NSString;

VC_NAMESPACE_BEGIN

namespace VCUtilBridge {
    std::string convertToString(NSString *ocStr);
    NSString *convertToOCString(const std::string &str);

    const VCJson dictToJson(NSDictionary<NSString *, NSString *> *dic);


    std::shared_ptr<std::vector<std::string>>
        convertToStrArr(NSArray<NSString *> *ocStrArr);
    NSArray<NSString *> *
        convertToOCStrArr(std::shared_ptr<std::vector<std::string>> strArr);

};

VC_NAMESPACE_END

#endif /* VCUtilBridge_hpp */
