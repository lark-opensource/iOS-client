// 计划移除此文件，如有问题请Lark联系 zhangyeqi
//
////
////  CanvasConfigUtils.hpp
////  LVTemplate
////
////  Created by bytedance on 2020/2/15.
////
//
//#pragma once
//
//#include <memory>
//
//template <typename  T> inline T safeGet(const std::shared_ptr<T>& sharedValue, const T& defaultValue) {
//    if (sharedValue.get() == nullptr) {
//        return defaultValue;
//    } else {
//        return *(sharedValue.get());
//    }
//}
//
//template <typename  T> inline T* safeGetPointer(const std::shared_ptr<T>& sharedValue, T* defaultValue) {
//    if (sharedValue.get() == nullptr) {
//        return defaultValue;
//    } else {
//        return sharedValue.get();
//    }
//}
//
