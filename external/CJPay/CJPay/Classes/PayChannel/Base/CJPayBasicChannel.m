//
//  CJPayBasicChannel.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayBasicChannel.h"
#import "CJPayTracker.h"
#import "CJPayUIMacro.h"

@interface CJPayBasicChannel()

@end

@implementation CJPayBasicChannel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

//检查是否可用
+ (BOOL)isAvailableUse {
    return NO;
}

- (void)trackWithEvent:(NSString *)eventName trackParam:(NSDictionary *)trackDic {
    NSMutableDictionary *mutableTrackDic = [trackDic mutableCopy];
    [mutableTrackDic addEntriesFromDictionary:self.trackParam];
    [mutableTrackDic addEntriesFromDictionary:@{
        @"is_chaselight" : @"1"
    }];
    [CJTracker event:eventName params:mutableTrackDic];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    return NO;
}

- (BOOL)canProcessUserActivity:(NSUserActivity *)activity {
    return NO;
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion) completionBlock {
    //子类实现
    self.dataDict = dataDict;
    self.trackParam = [dataDict cj_dictionaryValueForKey:@"track_info"];
    self.completionBlock = [completionBlock copy];
}


@end
