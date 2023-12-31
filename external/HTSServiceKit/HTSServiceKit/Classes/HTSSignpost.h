//
//  HTSSignpost.h
//  HTSSignpost
//
//  Created by Huangwenchen on 2019/12/15.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <os/log.h>
#import <os/signpost.h>

/// 启用signpost
FOUNDATION_EXPORT BOOL hts_signpost_run(void);
/// 标记singpost开始
FOUNDATION_EXPORT os_signpost_id_t hts_signpost_begin(const char * name);
/// 标记signpost结束
FOUNDATION_EXPORT void hts_signpost_end(os_signpost_id_t log_id,const char * name);
/// signpost是否在运行
FOUNDATION_EXPORT BOOL hts_signpost_is_running(void);
