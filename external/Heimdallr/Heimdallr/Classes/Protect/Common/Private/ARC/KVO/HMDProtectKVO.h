//
//  HMDProtectKVO.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#import <Foundation/Foundation.h>
#import "HMDProtect_Private.h"
#import "HMDKVOPair.h"

NS_ASSUME_NONNULL_BEGIN

extern void HMD_Protect_toggle_KVO_protection(HMDProtectCaptureBlock _Nullable captureBlock);
extern void HMD_Protect_KVO_captureException(HMDProtectCapture * capture);

@interface NSObject (HMDProtectKVO)

@property(nonatomic, strong)HMDKVOPairsInfo* HMDKVOInfo;

- (void)HMDP_addObserver:(NSObject *)observer
              forKeyPath:(NSString *)keyPath
                 options:(NSKeyValueObservingOptions)options
                 context:(nullable void *)context;

- (void)HMDP_removeObserver:(NSObject *)observer
                 forKeyPath:(NSString *)keyPath;

- (void)HMDP_removeObserver:(NSObject *)observer
                 forKeyPath:(NSString *)keyPath
                    context:(nullable void *)context;

@end

NS_ASSUME_NONNULL_END


