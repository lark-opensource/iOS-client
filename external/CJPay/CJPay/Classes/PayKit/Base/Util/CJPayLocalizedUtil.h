//
//  CJPayLocalizedUtil.h
//  Pods
//
//  Created by 高航 on 2022/7/27.
//

#import <Foundation/Foundation.h>
#import "CJPayLocalizedPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayLocalizedUtil : NSObject

+ (NSString *)localizableStringWithKey:(NSString *)stringKey;
+ (void)changeToCustomAppLanguage:(CJPayLocalizationLanguage)language;
+ (CJPayLocalizationLanguage)getCurrentLanguage;

@end

NS_ASSUME_NONNULL_END
