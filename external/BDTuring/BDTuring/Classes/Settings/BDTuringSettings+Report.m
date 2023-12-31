//
//  BDTuringSettings+Report.m
//  BDTuring
//
//  Created by bob on 2020/4/9.
//

#import "BDTuringSettings+Report.h"
#import <objc/runtime.h>
#import "BDTuringCoreConstant.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringEventService.h"
#import "BDTuringUtility.h"
#import "BDTuringEventConstant.h"

@implementation BDTuringSettings (Report)

- (long long)startRequestTime {
    return [objc_getAssociatedObject(self, @selector(startRequestTime)) longLongValue];
}

- (void)setStartRequestTime:(long long)startRequestTime {
    objc_setAssociatedObject(self, @selector(startRequestTime), @(startRequestTime), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)reportRequestResult:(NSInteger)result {
    long long duration = turing_duration_ms(self.startRequestTime);
    NSMutableDictionary *param = [NSMutableDictionary new];
    [param setValue:@(duration) forKey:BDTuringEventParamDuration];
    [param setValue:@(result) forKey:BDTuringEventParamResult];
    
    [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameSettings data:param];
}

@end
