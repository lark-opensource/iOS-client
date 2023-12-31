//
//  NLETemplateManifest.h
//  NLEPlatform
//
//  Created by Charles on 2021/11/12.
//

#ifndef NLETemplateManifest_h
#define NLETemplateManifest_h

#include "NLETemplateModel.h"
#include "NLEMappingNode.h"
#include "NLETemplateFeature.h"

namespace cut::model {

    class NLETemplateManifest {
    public:
        static void registerNLETemplateClass() {
            static bool hasRegister = false;
            if (hasRegister) return;

            NLETemplateModel::registerCreateFunc();
            NLEMappingNode::registerCreateFunc();
            TemplateInfo::registerCreateFunc();
            TemplateConfig::registerCreateFunc();
            hasRegister = true;
        }
    };
}

#endif /* NLETemplateManifest_h */
