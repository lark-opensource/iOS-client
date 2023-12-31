//
//  CJPayJsonParseTracker.h
//  Pods
//
//  Created by 尚怀军 on 2022/6/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayJsonParseTracker : NSObject

+ (instancetype)sharedInstance;

- (void)recordParseProcessWithClassName:(NSString *)className
                               costTime:(NSTimeInterval)costTime
                               modelDic:(NSDictionary *)modelDic;

- (void)syncModelParseTime;

@end

NS_ASSUME_NONNULL_END
