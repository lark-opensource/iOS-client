//
//  DVEPadUIAdapter.h
//  NLEEditor
//
//  Created by Lincoln on 2022/3/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEPadUIAdapter : NSObject

+ (CGFloat)dve_iPadScreenWidth;

+ (void)dve_setIPadScreenWidth:(CGFloat)width;

+ (CGFloat)dve_iPadScreenHeight;

+ (void)dve_setIPadScreenHeight:(CGFloat)height;

+ (BOOL)dve_isIPad;

+ (BOOL)dve_isDeviceVertical;

@end

NS_ASSUME_NONNULL_END
