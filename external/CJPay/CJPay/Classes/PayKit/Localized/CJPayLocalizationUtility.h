//
//  CJPayLocalizationUtility.h
//  CJPay
//
//  Created by 杨维 on 2018/10/15.
//

#import <Foundation/Foundation.h>
#import "CJPayLocalizedPlugin.h"

NS_ASSUME_NONNULL_BEGIN


/**
 管理国际化语言
 */
@interface CJPayLocalizationUtility : NSObject

/**
 国际化字符串
 
 完整实现国际化字符串，除调用此方法外，还需要将 stringKey 对应的各个语言的字符串在 CJPayLocalization.strings 文件中填充好。
 PS:CJPayLocalization.strings 文件可以用 "右键-> open as -> ASCII Property List" 方式打开，确保以 key-value 方式填写正确
 PSS:国际化字符串最好能够让产品同事给出，不要机翻
 
 @param stringKey 国际化字符串对应的key
 @return 国际化字符串
 */
- (NSString *)localizableStringWithKey:(NSString *)stringKey;

/**
 注意，如果APP有自定义语言的功能 且 CJPayLocalizationLanguage 含有该语言对应的枚举类型，请在更改语言时调用此方法，保证 pod 中文字能够正确国际化。
 APP跟随系统语言的始终不需要调用此方法

 @param language 将要更改成的语言类型
 */
- (void)changeToCustomAppLanguage:(CJPayLocalizationLanguage)language;

/**
 获得当前语言

 @return SDK正在使用的语言
 */
- (CJPayLocalizationLanguage)getCurrentLanguage;

@end

NS_ASSUME_NONNULL_END
