//
//  CMTime+LV.h
//  longVideo
//
//  Created by xiongzhuang on 2019/7/22.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#if defined(__cplusplus)
    extern "C" {
#endif /* defined(__cplusplus) */
    bool lvCMtimeLessThan(CMTime time1, CMTime time2);

    bool lvCMtimeGreaterThan(CMTime time1, CMTime time2);

    CMTime lvCMTimeGetEnd(CMTimeRange time);
    
    CMTime lvCMTimeScale(CMTime time, CGFloat value);
#if defined(__cplusplus)
    }
#endif /* defined(__cplusplus) */
