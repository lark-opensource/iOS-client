//
//  OPLocationPrivacyAccessStatusManager.h
//  TTMicroApp
//
//  Created by laisanpin on 2021/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPLocationPrivacyAccessStatusManager : NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

+ (instancetype)shareInstance;
//更新单次定位开关状态
- (void)updateSingleLocationAccessStatus:(BOOL)isUsing;
//更新持续定位开关状态
- (void)updateContinueLocationAccessStatus:(BOOL)isUsing;
@end

NS_ASSUME_NONNULL_END
