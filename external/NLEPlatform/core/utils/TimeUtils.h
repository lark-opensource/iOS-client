// 计划移除此文件，如有问题请Lark联系 zhangyeqi
//
////
//// Created by Steven on 2021/8/24.
////
//
//#ifndef NLE_UTILS_TIMEUTILS_H
//#define NLE_UTILS_TIMEUTILS_H
//
//#include <chrono>
//
//namespace nle::utils {
//        class TimeUtils {
//        public:
//            /**
//             * 获取当前时间
//             * @return 毫秒
//             */
//            static inline int64_t getCurrentMill() {
//                using namespace std::chrono;
//                auto now = high_resolution_clock::now();
//                return duration_cast<milliseconds>(now.time_since_epoch()).count();
//            }
//        };
//    }
//
//#endif //NLE_UTILS_TIMEUTILS_H
