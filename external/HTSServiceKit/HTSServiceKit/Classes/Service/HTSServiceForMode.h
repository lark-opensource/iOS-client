//
//  HTSAppContext.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSCompileTimeServiceManager.h"

//Service for current mode
#if DEBUG
#define HTS_BIND_SERVICE_FOR_MODE(PROTOCOL_NAME,CLASS_NAME,_mode_)\
__used static Class<PROTOCOL_NAME> _HTS_SERVICE_VALID_METHOD(void){\
    return [CLASS_NAME class];\
}\
__attribute((used, section("HTS_"_mode_ "," _HTS_SERVICE_SECTION ))) static _hts_service_pair _HTS_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(CLASS_NAME),\
_HTS_TO_STRING(PROTOCOL_NAME),\
};\

#else

#define HTS_BIND_SERVICE_FOR_MODE(PROTOCOL_NAME,CLASS_NAME,_mode_)\
__attribute((used, section("HTS_"_mode_ "," _HTS_SERVICE_SECTION ))) static _hts_service_pair _HTS_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(CLASS_NAME),\
_HTS_TO_STRING(PROTOCOL_NAME),\
};\

#endif

