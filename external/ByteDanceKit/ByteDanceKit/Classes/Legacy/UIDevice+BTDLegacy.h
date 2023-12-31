//
//  UIDevice+BTDLegacy.h
//  ByteDanceKit
//
//  Created by bytedance on 2020/7/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (BTDLegacy)

/**
*  Optimize the Performance of IDFA and IDFV.
*
*  @param enable Enable the optimization or not.
*/
+ (void)btd_optimizeIDFXEnabled:(BOOL)enable;
+ (nullable NSString *)btd_idfaString;
+ (nullable NSString *)btd_idfvString;

@end

NS_ASSUME_NONNULL_END
