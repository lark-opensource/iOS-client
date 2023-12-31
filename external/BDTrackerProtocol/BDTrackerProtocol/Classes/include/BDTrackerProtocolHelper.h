//
//  BDTrackerProtocolHelper.h
//  Pods
//
//  Created by bob on 2020/3/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, kTrackerType) {
    kTrackerTypeTTTracker = 0,
    kTrackerTypeBDtracker = 1,
};

@interface BDTrackerProtocolHelper : NSObject

+ (Class)trackerCls;
+ (kTrackerType)trackerType;
+ (void)setTrackerType:(kTrackerType)type;

+ (Class)bdtrackerCls;
+ (Class)tttrackerCls;

@end

NS_ASSUME_NONNULL_END
