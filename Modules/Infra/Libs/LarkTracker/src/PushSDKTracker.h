//
//  PushSDKTracker.h
//  Pods
//
//  Created by 李晨 on 2019/12/5.
//

#import <UIKit/UIKit.h>

@protocol PushSDKTracker <NSObject>
- (nonnull NSString *)deviceID;
- (nonnull NSString *)installID;
- (void)event:(nonnull NSString *)event params:(nonnull NSDictionary<NSString*, id> *)params;
@end

@interface PushSDKTrackerProvider: NSObject

+ (nonnull instancetype)shared;

@property (nonatomic, strong, nullable) id<PushSDKTracker> tracker;

@end
