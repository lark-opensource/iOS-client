//
// Created by wangchengyi.1 on 2021/11/10.
//

#ifndef NLECONSOLE_NLEPROPERTYUTIL_HPP
#define NLECONSOLE_NLEPROPERTYUTIL_HPP

#include "NLENode.h"
#include <nlohmann/json.hpp>

namespace cut {
    namespace model {

        class NLEPropertyUtil {
        public:
            template<typename T>
            static void
            setValueInternal(const std::shared_ptr<nlohmann::json> &primaryValues, const NLEPropertyBase &property,
                             ChangeBits &changeBits, std::unordered_set<TNLEFeature> &featureList,
                             const std::vector<std::shared_ptr<NLEChangeListener>> &listeners, T value) {
                auto iter = primaryValues->find(property.name);
                if (iter != primaryValues->end()) { if ((*primaryValues)[property.name].get<T>() == value) { return; }}
                (*primaryValues)[property.name] = value;
                changeBits.markChange(ChangeBit::PROPERTY);
                featureList.insert(property.apiFeature);
                for (auto &listener:listeners) { listener->onChanged(); }
            }

            template<typename T>
            static T
            getValueInternal(const std::shared_ptr<nlohmann::json> &primaryValues, const NLEPropertyBase &property,
                             const T &defaultValue) {
                const auto iter = primaryValues->find(property.name);
                if (iter != primaryValues->end()) { return (*primaryValues)[property.name].get<T>(); }
                return defaultValue;
            }
        };

    }
}


#endif //NLECONSOLE_NLEPROPERTYUTIL_HPP
