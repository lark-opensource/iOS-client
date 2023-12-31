//
// Created by bytedance on 2020/12/1.
//

#ifndef NLECONSOLE_NLECOMMIT_H
#define NLECONSOLE_NLECOMMIT_H

#include "nle_export.h"
#include "NLENode.h"
#include "NLESequenceNode.h"

namespace cut::model {
    class NLE_EXPORT_CLASS NLECommit : public NLENode {
        NLENODE_RTTI(NLECommit);
        NLE_PROPERTY_OBJECT(NLECommit, Model, NLEModel, NLEFeature::E)
        NLE_PROPERTY_DEC(NLECommit, Description, std::string, std::string(), NLEFeature::E)
        NLE_PROPERTY_DEC(NLECommit, TimeStamp, int64_t, 0, NLEFeature::E)
        NLE_PROPERTY_DEC(NLECommit, Version, int64_t, 0, NLEFeature::E)
    };
}


#endif //NLECONSOLE_NLECOMMIT_H
