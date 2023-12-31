//
//  BDWMDeallocHelper.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/11/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDWMDeallockHelperBlock)(void);

@interface BDWMDeallocHelper : NSObject

+ (void)attachDeallocBlock:(BDWMDeallockHelperBlock)block toTarget:(id)object forKey:(const void*)key;

@end

NS_ASSUME_NONNULL_END
