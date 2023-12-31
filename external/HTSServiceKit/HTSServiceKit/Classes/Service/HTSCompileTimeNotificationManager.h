//  HTSCompileTimeNotificationManager.h
//  HTSCompileTimeNotificationManager
//
//  Created by Huangwenchen on 2020/03/31.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSMacro.h"

#define _HTS_NOTI_SECTION               "__HTSNoti"
#define _HTS_NOTI_NAME_METHOD           _HTS_CONCAT(__hts_notification_name_provider_, __LINE__)
#define _HTS_NOTI_LOGIC_METHOD          _HTS_CONCAT(__hts_notification_logic_provider_, __LINE__)
#define _HTS_NOTI_UNIQUE_VAR            _HTS_CONCAT(__hts_notification_var_, __COUNTER__)

typedef struct{
    void * name_provider;
    void * logic_provider;
}_hts_notification_pair;

typedef NSString*(*_hts_notification_name_provider)(void);
typedef void(*_hts_notification_logic_provider)(NSNotification * notification);

/** 
 Register a notification subscriber at compile time。
 Example:
 
    HTS_NOTIFICATION_SUBSCRIBER(AWEAppBytedSettingMessage){
        [[Manager sharedManager] hanldeNotification:notification];
    }
**/ 
#define HTS_NOTIFICATION_SUBSCRIBER(notificaiton_name) static void _HTS_NOTI_LOGIC_METHOD(NSNotification * notification);\
static NSString * _HTS_NOTI_NAME_METHOD(void){\
    return notificaiton_name;\
}\
__attribute((used, section(_HTS_SEGMENT "," _HTS_NOTI_SECTION ))) static _hts_notification_pair _HTS_NOTI_UNIQUE_VAR = \
{\
&_HTS_NOTI_NAME_METHOD,\
&_HTS_NOTI_LOGIC_METHOD,\
};\
static void _HTS_NOTI_LOGIC_METHOD(NSNotification * notification)

