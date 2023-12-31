//
//  LVDeivice.h
//  VideoTemplate-Pods-Aweme
//
//  Created by luochaojing on 2020/4/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^LVDeviceJudgerWorseThanIPhone6s)(void);

@interface VideoTemplateDevice : NSObject

+ (void)registerWorseThanIPhone6sJudger:(LVDeviceJudgerWorseThanIPhone6s)judger;
+ (BOOL)isWorseThanIPhone6s;

@end

NS_ASSUME_NONNULL_END
