//
//  MMMemoryLog.m
//  IESDetection-Pods-Aweme
//
//  Created by zhufeng on 2021/9/2.
//

#import "MMMemoryLog.h"
#import "MMMemoryAdapter.h"

void matrix_log(NSString* type, NSString* content) {
    id<MMMemoryAdapterDelegate> mmAdapterDelegate = [MMMemoryAdapter shared].delegate;
    if ([mmAdapterDelegate respondsToSelector:@selector(onMemoryAdapterLog:content:)]) {
        [mmAdapterDelegate onMemoryAdapterLog:type content:content];
    }
}



