//
// Created by bytedance on 7/15/21.
//

#ifndef NLEPLATFORM__NLEINSTANCEMODE_H
#define NLEPLATFORM__NLEINSTANCEMODE_H

#include "nle_export.h"
#include <string>

namespace cut::model {
    class NLEInstantMode {
    public:
        static const std::string Key;
        static const std::string PivotalStickerUUID;
        static const std::string InstantStickerTransform;
        static const std::string InstantStickerScale;
        static const std::string InstantStickerRemove;
    };
}

#endif //NLEPLATFORM__NLEINSTANCEMODE_H
