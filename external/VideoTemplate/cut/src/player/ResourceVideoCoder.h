//
// Created by zhangyeqi on 2019-12-19.
//

#ifndef CUT_ANDROID_RESOURCEVIDEOCODER_H
#define CUT_ANDROID_RESOURCEVIDEOCODER_H

#include <string>
#include <TemplateConsumer/model.hpp>
#include "ResourceFetcher.h"

namespace cut {
    class ResourceVideoCoder
: public ResourceIOCoder<string, std::vector<std::shared_ptr<CutSame::VideoSegment>>> {
    public:

    std::vector<std::shared_ptr<CutSame::VideoSegment>> decode(const string& pack) override;

    string encode(const std::vector<std::shared_ptr<CutSame::VideoSegment>>& frame) override;

    };
}


#endif //CUT_ANDROID_RESOURCEVIDEOCODER_H
