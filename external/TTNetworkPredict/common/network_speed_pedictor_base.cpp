//
//  network_speed_pedictor_base.cpp
//  networkPredictModule
//
//  Created by shen chen on 2020/7/9.
//

#include "network_speed_pedictor_base.h"
#include <stdio.h>
#include <stdarg.h>

#define INFO_SIZE 512

#if defined(__ANDROID__)
#include <android/log.h>
static int gSpeedAndroidLevelInfo[]={
        ANDROID_LOG_VERBOSE,
        ANDROID_LOG_DEBUG,
        ANDROID_LOG_INFO,
        ANDROID_LOG_WARN,
        ANDROID_LOG_ERROR,
        ANDROID_LOG_FATAL
};
#endif

static int sSpeedLevel = LOG_WARN;

void network_predict_set_logger_level(int level) {
    sSpeedLevel = level;
}

void network_predict_logger_nprintf(int level,const char* tag,const char* file,const char* fun,int line,const char* format,...) {
    if (level < sSpeedLevel) { return; }
    char infos[INFO_SIZE];
    va_list args;
    va_start( args, format );
    vsnprintf((char *) infos, INFO_SIZE, format, args);
    va_end( args );
#if defined(__ANDROID__)
    __android_log_print(gSpeedAndroidLevelInfo[level],tag,"<%s,%s,%d>%s",file,fun,line,infos);
#else
    printf("<%s,%s,%d>%s\n",file,fun,line,infos);
#endif
}
