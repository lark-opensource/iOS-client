//
//  BDPRouteMediatorDelegate.h
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/4/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPRouteMediatorDelegate : NSObject
+ (instancetype)shared;
- (void)setDelegate;
@end

NS_ASSUME_NONNULL_END
