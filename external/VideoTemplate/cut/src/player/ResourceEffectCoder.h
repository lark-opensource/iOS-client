//
// Created by zhangyeqi on 2019-12-19.
//

#ifndef CUT_ANDROID_RESOURCEEFFECTCODER_H
#define CUT_ANDROID_RESOURCEEFFECTCODER_H

#include <string>
#include "DefaultResourceFetcher.h"
#include "EffectTypeHelper.h"

using std::pair;
using std::string;

namespace cut {
    class ResourceEffectCoder
            : public ResourceIOCoder<string, pair<string, string>> {
    public:
        pair<string, string> decode(const string& pack) override;

        string encode(const string& resourceId, const string& resourceType) {
            return encode(std::make_pair(resourceId, resourceType));
        }

        string encode(const pair<string, string>& frame) override;
                
        const string requestURL(FetchEffectRequest& request) {
            std::string platformName = EffectPlatformHelper::getEffectSourcePlatformTypeName(request.getEffectSourcePlatformType());
            return SCHEMA_EFFECT + SCHEMA_DELIMITER + platformName + "/" + encode(request.mResourceId, request.mResourceType);
        }
    };
}


#endif //CUT_ANDROID_RESOURCEEFFECTCODER_H
