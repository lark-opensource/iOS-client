//
// Created by Steven on 2021/1/21.
//

#ifndef TEMPLATECONSUMERAPP_CONVERTUTILS_H
#define TEMPLATECONSUMERAPP_CONVERTUTILS_H

#include <string>
#include <vector>

namespace TemplateConsumer {
    class ConvertUtils {
    public:
        static int64_t msToUs(int64_t ms);
        static int64_t usToMs(int64_t ms);

        static uint32_t getColorArgb(const std::string &rgba, uint32_t defaultColor);
        static uint32_t getColorAlpha(const std::string &rgba);
        static bool isValidColor(const std::string &color);

        static float getRatio(const std::string &ratio);

        static std::vector<std::string> strSplit(const std::string &str, const std::string &pattern);

        static std::vector<double> limitVideoMaxSize(double aspectRatio, double width, double height);

        static float getRotation(double rotation);
        
        static uint32_t WHITE();
        static uint32_t BLACK();
        static uint32_t TRANSPARENT();
    };
}


#endif //TEMPLATECONSUMERAPP_CONVERTUTILS_H
