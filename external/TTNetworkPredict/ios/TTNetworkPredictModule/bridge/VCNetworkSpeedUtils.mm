//
//  abrUtils.c
//  abrmodule
//
//  Created by guikunzhi on 2020/3/30.
//  Copyright © 2020 gkz. All rights reserved.
//

#include "VCNetworkSpeedUtils.h"

NETWORKPREDICT_NAMESPACE_BEGIN
std::string convertString(NSString *ocStr) {
    if (!ocStr.length) {
        return "";
    }
    const char *str = [ocStr UTF8String];
    if (!str) {
        return "";
    }
    return std::string(str);
}

NETWORKPREDICT_NAMESPACE_END
