//
//  LynxView+Monitor.h
//  
//
//  Created by admin on 2020/6/22.
//

#import <Lynx/LynxView.h>
#import "IESLynxPerformanceDictionary.h"
#import "IESLynxMonitorConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxView (Monitor)

@property (nonatomic, strong, readonly) IESLynxPerformanceDictionary *performanceDic;
@property (nonatomic) IESLynxMonitorConfig *config;
@property (nonatomic,  readonly, copy) NSString *bdlm_containerID;

// config biztag if needed. if you have called this method, monitor will report to a special service base on this biztag which means you must config this to slardar . by zhouyichuan
@property (nonatomic, strong) NSString *bdlm_bizTag;

- (instancetype)bdlm_initWithBuilderBlock:(void (^)(NS_NOESCAPE LynxViewBuilder*))block;
//- (void)bdlm_removeFromSuperview;
- (void)bdlm_clearForDestroy;
- (void)bdlm_willMoveToWindow:(nullable UIWindow *)newWindow;

@end

NS_ASSUME_NONNULL_END
