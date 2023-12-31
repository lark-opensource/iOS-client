//
// Created by bytedance on 2021/5/25.
//

#ifndef TEMPLATECONSUMERAPP_SCRIPTFEATURE_H
#define TEMPLATECONSUMERAPP_SCRIPTFEATURE_H

#include <unordered_set>
#include <string>

#define FEATURE_E "E"
namespace script::model {
    using TScriptFeature = std::string;
    class ScriptFeature {
    public:
        // E project setup, the first VE-Public-API ability. Feature E.


        // check support or not
        static bool support(const std::unordered_set<TScriptFeature> &features);

        static const std::unordered_set<TScriptFeature> SUPPORT_FEATURES;
    };

}



#endif //TEMPLATECONSUMERAPP_SCRIPTFEATURE_H
