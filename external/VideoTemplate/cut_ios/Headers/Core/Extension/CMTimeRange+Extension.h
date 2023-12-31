//
//  CMTimeRange+Extension.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/14.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(__cplusplus)
    extern "C" {
#endif /* defined(__cplusplus) */

CMTimeRange lv_trimStart(CMTimeRange range, CMTime value);

bool lv_closeContain(CMTimeRange range, CMTime value);

#if defined(__cplusplus)
    }
#endif /* defined(__cplusplus) */

NS_ASSUME_NONNULL_END

