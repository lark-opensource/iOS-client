//
//  NSBundle+LV.h
//  DraftComponent
//
//  Created by xiongzhuang on 2019/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (LV)

/**
 显示名称
 */
- (NSString *)lv_displayName;


/**
 app版本号
 */
- (NSString *)lv_appVersion;


/**
 app build版本号
 */
- (NSString *)lv_buildVersion;

+ (nullable NSBundle *)templateBundle;

@end

NS_ASSUME_NONNULL_END
