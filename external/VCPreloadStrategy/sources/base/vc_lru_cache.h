//
// Created by 黄清 on 2021/10/7.
//

#ifndef PRELOAD_LRUCACHE_H
#define PRELOAD_LRUCACHE_H

#include "vc_base.h"
#include <list>
#include <unordered_map>

#pragma once

VC_NAMESPACE_BEGIN

template <typename Key, typename Value>
class LRUCache {
public:
    typedef typename std::pair<Key, Value> key_value_pair_t;
    typedef typename std::list<key_value_pair_t>::iterator list_iterator_t;

    LRUCache(size_t max_size) : mMaxSize(max_size) {}

    void put(const Key &key, const Value &value) {
        auto it = mCacheItemsMap.find(key);
        mCacheItemsList.push_front(key_value_pair_t(key, value));
        if (it != mCacheItemsMap.end()) {
            mCacheItemsList.erase(it->second);
            mCacheItemsMap.erase(it);
        }
        mCacheItemsMap[key] = mCacheItemsList.begin();

        if (mCacheItemsMap.size() > mMaxSize) {
            auto last = mCacheItemsList.end();
            last--;
            mCacheItemsMap.erase(last->first);
            mCacheItemsList.pop_back();
        }
    }

    const Value &get(const Key &key) {
        auto it = mCacheItemsMap.find(key);
        if (it == mCacheItemsMap.end()) {
            LOGD("[base] There is no such key in cache");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-stack-address"
            return nullptr;
#pragma clang diagnostic pop
        } else {
            mCacheItemsList.splice(
                    mCacheItemsList.begin(), mCacheItemsList, it->second);
            return it->second->second;
        }
    }

    bool exists(const Key &key) const {
        return mCacheItemsMap.find(key) != mCacheItemsMap.end();
    }

    size_t size() const {
        return mCacheItemsMap.size();
    }

private:
    std::list<key_value_pair_t> mCacheItemsList;
    std::unordered_map<Key, list_iterator_t> mCacheItemsMap;
    size_t mMaxSize;
};

VC_NAMESPACE_END

#endif // PRELOAD_LRUCACHE_H
