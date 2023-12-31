//
// Created by 天 on 2019-12-09.
//

#ifndef CUTSAMEAPP_COLORUTILS_H
#define CUTSAMEAPP_COLORUTILS_H

#include <cstdint>
#include <string>
#include <vector>

using std::string;
using std::vector;

namespace asve {
    class ColorUtils {
    public:
        static const int COLOR_TYPE_WHITE();
        static const int COLOR_TYPE_BLACK();

        static const string WHITE();
        static const string BLACK();

        /**
        * @param rgba 顺序 RGBA
        * @param defaultColor 默认颜色
        * @return [R, G, B, A]
        */
        static vector<float>
        getColorListByArgb(const string &rgba, int defaultColor = COLOR_TYPE_BLACK());
    };
}


#endif //CUTSAMEAPP_COLORUTILS_H
