//
//  CJPayThemeModeManager.h
//  CJComponents
//
//  Created by 易培淮 on 2020/9/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayThemeModeType) {
    CJPayThemeModeTypeLight = 0,
    CJPayThemeModeTypeDark,
    CJPayThemeModeTypeOrigin
};

@interface CJPayThemeModeManager : NSObject

// 主题模式参数
@property (nonatomic, assign) CJPayThemeModeType themeMode;

+ (instancetype)sharedInstance;

/**
 配置SDK主题：深色或浅色模式
 @param themeMode 模式
 */
- (void)setTheme:(NSString*)themeMode;

- (BOOL)isDarkMode;

- (BOOL)isLightMode;

- (BOOL)isOriginMode;

+ (CJPayThemeModeType)themeModeFromString:(NSString *)themeString;

@end

NS_ASSUME_NONNULL_END
