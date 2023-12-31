//
//  HTSSignpost.m
//  HTSSignpost
//
//  Created by Huangwenchen on 2019/12/15.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSSignpost.h"

static os_log_t _logger;
static BOOL _enable_signpost;

FOUNDATION_EXPORT BOOL hts_signpost_is_running(void){
    return _enable_signpost;
}

/// 启用signpost
FOUNDATION_EXPORT BOOL hts_signpost_run(void){
    static dispatch_once_t onceToken;
    __block BOOL result = NO;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 12.0, *)) {
            _logger = os_log_create("BootLoader", "performance");
            _enable_signpost = YES;
            result = YES;
        }
    });
    return result;
}

/// 标记singpost开始
FOUNDATION_EXPORT os_signpost_id_t hts_signpost_begin(const char * name){
    if (!_enable_signpost) {
        return OS_SIGNPOST_ID_INVALID;
    }
    os_signpost_id_t _logId = os_signpost_id_generate(_logger);
    if (@available(iOS 12.0, *)) {
        if ([NSThread isMainThread]) {
            os_signpost_interval_begin(_logger,_logId,"Main","%{public}s",name);
        }else{
            os_signpost_interval_begin(_logger,_logId,"Background","%{public}s",name);
        }
    }
    return _logId;
}

/// 标记signpost结束
FOUNDATION_EXPORT void hts_signpost_end(os_signpost_id_t log_id,const char * name){
    if (!_enable_signpost) {
        return;
    }
    if (log_id == OS_SIGNPOST_ID_INVALID) {
        return;
    }
    if (@available(iOS 12.0, *)) {
        if ([NSThread isMainThread]) {
            os_signpost_interval_end(_logger,log_id,"Main","%{public}s",name);
        }else{
            os_signpost_interval_end(_logger,log_id,"Background","%{public}s",name);
        }
    }
}
