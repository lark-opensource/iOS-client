//
//  PNSServiceCenter+private.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/22.
//

#import <Foundation/Foundation.h>
#import "PNSServiceCenter.h"

#ifndef PNSServiceCenter_private_h
#define PNSServiceCenter_private_h

typedef struct{
    const char * _Nonnull cls;
    const char * _Nonnull protocol;
}_pns_service_info;

#define PNS_SERVICE_SECTION "__PNSService"
#define PNS_CONCAT_PRIVATE(x,y) x##y
#define PNS_CONCAT(x,y) PNS_CONCAT_PRIVATE(x,y)
#define PNS_SERVICE_VALID_METHOD PNS_CONCAT(__pns_service_valid_, __COUNTER__)
#define PNS_SERVICE_UNIQUE_VAR PNS_CONCAT(__pns_service_var_, __COUNTER__)
#define PNS_TO_STRING_PRIVATE(x) #x
#define PNS_TO_STRING(x) PNS_TO_STRING_PRIVATE(x)


/**
 PNS_BIND_DEFAULT_SERVICE 绑定 service 默认实现，在编译期写入，只在内部绑定默认实现使用，不对外暴露
 
 @param cls_name 类
 @param protocol_name 协议
 */
#define PNS_BIND_DEFAULT_SERVICE(cls_name, protocol_name)\
__attribute((used, section("__DATA" "," PNS_SERVICE_SECTION )))\
static _pns_service_info PNS_SERVICE_UNIQUE_VAR = \
{\
    PNS_TO_STRING(cls_name),\
    PNS_TO_STRING(protocol_name),\
};\


#endif /* PNSServiceCenter_private_h */
