#pragma once

#include <string>

#define MAMMON_VER_MAJOR 9
#define MAMMON_VER_MINOR 0
#define MAMMON_VER_PATCH 0
#define MAMMON_VER_BUILD 0

namespace mammon {

    /**
     * @brief 版本号信息
     */
    struct VersionInfo {
        static constexpr int getMajor();
        static constexpr int getMinor();
        static constexpr int getPatch();
        static constexpr int getBuild();
        static std::string getVersionString();

        /**
         * 判断版本号是否大于当前库版本
         * @param major 主版本号
         * @param minor 次版本号
         * @param patch 修订版本号
         */
        static bool isNewerThan(int major, int minor, int patch);

        /**
         * 判断是否包含某些特性
         * @param name 特性名称
         */
        static bool hasFeature(std::string name);
    };

}  // namespace mammon
