//
// Created by bytedance on 4/9/21.
//

#ifndef AWEMETOOLS_NLEMEASURE_H
#define AWEMETOOLS_NLEMEASURE_H

#include <memory>
#include "NLESequenceNode.h"

namespace cut::model {
    class NLEMeasure {
    public:
        NLE_EXPORT_METHOD static void performMeasure(const std::shared_ptr<cut::model::NLETimeSpaceNode>& rootNode);

    private:
        static void measure(const std::shared_ptr<cut::model::NLETimeSpaceNode>& node);
        static void clearMeasure(const std::shared_ptr<cut::model::NLETimeSpaceNode>& node);
    };
}

#endif //AWEMETOOLS_NLEMEASURE_H
