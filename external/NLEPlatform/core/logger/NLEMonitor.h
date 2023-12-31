//
// Created by bytedance on 2021/8/18.
//

#ifndef CUT_ANDROID_NLEMONITOR_H
#define CUT_ANDROID_NLEMONITOR_H

#include "nle_export.h"
#include <string>
#include <memory>
#include <map>
#include <cstdint>

namespace nle::monitor {
        class NLE_EXPORT_CLASS INLEMonitor {
        public:
            INLEMonitor() = default;

            virtual ~INLEMonitor() = default;

            virtual void
            onEvent(const std::string &key, int32_t resultCode, const std::string &msg,
                    int64_t duration) {};

        };


        class NLE_EXPORT_CLASS NLEMonitor {
        public:
            NLEMonitor() = default;

            ~NLEMonitor() = default;

            static const std::string KEY_NLE_EDITOR_STORE;
            static const std::string KEY_NLE_EDITOR_RESTORE;
            static const std::string KEY_NLE_MEDIA_CONVERT;
            static const std::string KEY_NLE_MEDIA_PLAY;
            static const std::string KEY_NLE_MEDIA_PLAY_FPS;
            static const std::string PARAM_ERROR_MSG;
            static const std::string PARAM_ERROR_CODE;
            static const std::string PARAM_NLE_JSON_SIZE;

            static const std::string PARAM_VE_API;

            static const int32_t RESULT_CODE_SUCCESS = 0;

            static const NLEMonitor *obtain();

            /**
             * 统计
             * @param key
             * @param resultCode 状态码 0为正常，其他一般是错误，可以是负数
             * @param msg
             * @param duration 毫秒
             */
            void
            onEvent(const std::string &key, int32_t resultCode, const std::string &msg, int64_t duration = -1) const {
                if (listener != nullptr) {
                    listener->onEvent(key, resultCode, msg, duration);
                }
            }

            void setListener(const std::shared_ptr<INLEMonitor> &l) {
                this->listener = l;
            }

        private:
            mutable std::shared_ptr<INLEMonitor> listener;
        };

        class NLE_EXPORT_CLASS NLEMonitorParamBuilder {
        public:
            NLEMonitorParamBuilder() = default;
            ~NLEMonitorParamBuilder() = default;

            NLEMonitorParamBuilder *appendParam(const std::string &key, const std::string &value);

            std::string buildParamString() const;

        private:
            std::map<std::string, std::string> paramMap;
        };
    }


#define NLE_MONITOR nle::monitor::NLEMonitor::obtain()

#endif //CUT_ANDROID_NLEMONITOR_H
