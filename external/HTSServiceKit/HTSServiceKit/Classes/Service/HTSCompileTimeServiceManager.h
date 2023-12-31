//
//  HTSCompileTimeServiceManager.h
//  HTSServiceKit
//
//  Created by Huangwenchen on 2020/4/28.
//

#import <Foundation/Foundation.h>
#import "HTSMacro.h"

#define _HTS_SERVICE_SECTION                "__HTSService"
#define _HTS_SERVICE_VALID_METHOD           _HTS_CONCAT(__hts_service_valid_, __LINE__)
#define _HTS_SERVICE_UNIQUE_VAR             _HTS_CONCAT(__hts_service_var_, __COUNTER__)

typedef struct{
    const char * cls;
    const char * protocol;
}_hts_service_pair;

/** 
 Register a service pair at compile time
**/ 

#if DEBUG

#define HTS_BIND_SERVICE(PROTOCOL_NAME,CLASS_NAME)\
__used static Class<PROTOCOL_NAME> _HTS_SERVICE_VALID_METHOD(void){\
    return [CLASS_NAME class];\
}\
__attribute((used, section(_HTS_SEGMENT "," _HTS_SERVICE_SECTION ))) static _hts_service_pair _HTS_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(CLASS_NAME),\
_HTS_TO_STRING(PROTOCOL_NAME),\
};\

#else

#define HTS_BIND_SERVICE(PROTOCOL_NAME,CLASS_NAME)\
__attribute((used, section(_HTS_SEGMENT "," _HTS_SERVICE_SECTION ))) static _hts_service_pair _HTS_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(CLASS_NAME),\
_HTS_TO_STRING(PROTOCOL_NAME),\
};\

#endif


