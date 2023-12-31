#ifdef __cplusplus
#ifndef BACH_ALGORITHM_INFO_H
#define BACH_ALGORITHM_INFO_H

#include <unordered_map>
#include "Bach/Base/BachObject.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BachMap : public AmazingEngine::RefBase
{
public:
    std::unordered_map<std::string, BachObject> dataMap;

    const BachObject& get(const std::string& key, const BachObject& def = BachObject()) const
    {
        auto iter = dataMap.find(key);
        if (iter != dataMap.end())
        {
            return iter->second;
        }
        return def;
    }

    void copyFrom(const BachMap& maps)
    {
        for (const auto& map : maps.dataMap)
        {
            this->dataMap[map.first] = map.second.clone();
        }
    }
};

using AlgorithmInfo = BachMap;

NAMESPACE_BACH_END
#endif

#endif