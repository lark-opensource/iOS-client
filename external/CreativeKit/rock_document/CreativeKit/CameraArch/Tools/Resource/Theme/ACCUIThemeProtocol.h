//
//  ACCUIThemeProtocol.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ACCUIThemeStyleDark = 1,
    ACCUIThemeStyleLight = 2,
    ACCUIThemeStyleAutomatic = 100,
} ACCUIThemeStyle;


@protocol ACCUIThemeProtocol <NSObject>

//Initial theme style when ACCUIThemeManager alloc
- (ACCUIThemeStyle)initialThemeStyle;

@end

NS_ASSUME_NONNULL_END
