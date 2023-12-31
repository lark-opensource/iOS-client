//
// Created by bytedance on 2021/4/21.
//

#ifndef DAVINCIRESOURCE_ALGORITHMCONFIG_H
#define DAVINCIRESOURCE_ALGORITHMCONFIG_H

#include <string>
#include <unordered_map>
#include "DAVPubDefine.h"

namespace davinci {
    namespace algorithm {
        class DAV_EXPORT AlgorithmResourceConfig {
        public:
            std::string appID;
            std::string accessKey; //在特效后台申请应用的accessKey，必需
            std::string sdkVersion; //对应effectSDK版本，a.b.c三位，用于过滤低版本不支持的特效，必需
            std::string appVersion; //对应自己的app版本，用于过滤低版本不支持的特效，必需
            std::string deviceType; //设备型号，用于过滤该机型不支持的特效，一般传入Build.MODEL，必需
            std::string deviceId;  //设备id，传递"0"即可，必需
            std::string platform;

            std::string cacheDir;
            std::string host;

            std::string busiId;
            std::string status;

            std::unordered_map<std::string, std::string> getRequestParams() const;
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMCONFIG_H
