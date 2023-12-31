//
// Created by simple on 2021/10/26.
//

#ifndef NLEANDROID_NLETEMPLATEFEATURE_H
#define NLEANDROID_NLETEMPLATEFEATURE_H

#include "nle_export.h"
#include "NLEFeature.h"

#include <string>
#include <unordered_set>

namespace cut::model {

    class NLE_EXPORT_CLASS NLETemplateFeature {
            public:

            // check support or not
            static bool support(const std::unordered_set<TNLEFeature> &features);

            static const std::unordered_set<TNLEFeature> SUPPORT_TEMPLATE_FEATURES;
    };
}

#endif //NLEANDROID_NLETEMPLATEFEATURE_H
