//
// Created by huangbiyun on 2020/11/26.
//

#ifndef CUT_ANDROID_VECTORUTILS_H
#define CUT_ANDROID_VECTORUTILS_H

#include <stdio.h>
#include <vector>
#include <algorithm>

namespace TemplateConsumer {
    class VectorUtils {
    public:
        template<typename T>
        static bool contentEquals(std::vector<T> &v1, std::vector<T> &v2) {
            if (v1.size() == 0 || v2.size() == 0 || v1.size() != v2.size()) {
                return false;
            }
            std::sort(v1.begin(), v1.end());
            std::sort(v2.begin(), v2.end());
            return (v1 == v2);
        }
    };
}

#endif //CUT_ANDROID_VECTORUTILS_H
