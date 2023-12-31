//
//  CJPayABTestNewPlugin.h
//  Pods
//
//  Created by 孟源 on 2022/5/18.
//

#ifndef CJPayABTestNewPlugin_h
#define CJPayABTestNewPlugin_h

#import <Foundation/Foundation.h>
#import "CJPayProtocolManager.h"


NS_ASSUME_NONNULL_BEGIN
@protocol CJPayABTestNewPlugin <NSObject>

// 注册实验,isSticky在 app 生命周期内，实验取值是否永远保持一致 默认为no
- (void)registerABTestWithKey:(NSString *)key defaultValue:(NSString *)defaultValue;

- (void)registerABTestWithKey:(NSString *)key defaultValue:(NSString *)defaultValue isSticky:(BOOL)isSticky;

// 获得试验值
- (NSString *)getABTestValWithKey:(NSString *)key exposure:(BOOL)exposure;
@end


NS_ASSUME_NONNULL_END

#endif /* CJPayABTestNewPlugin_h */
