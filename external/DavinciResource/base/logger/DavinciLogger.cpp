//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "DavinciLogger.h"

using namespace davinci::logger;

const DAVLogger *DAVLogger::obtain() {
    static DAVLogger _logger;
    return &_logger;
}