//
//  CJPayThemeStyleManager.h
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import <Foundation/Foundation.h>
@class CJPayServerThemeStyle;
@class CJPayLocalThemeStyle;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayThemeStyleManager : NSObject

@property (nonatomic, strong, readonly) CJPayServerThemeStyle *serverTheme;

+ (instancetype)shared;

- (void)updateStyle:(CJPayServerThemeStyle *)themeStyle;

@end

NS_ASSUME_NONNULL_END
