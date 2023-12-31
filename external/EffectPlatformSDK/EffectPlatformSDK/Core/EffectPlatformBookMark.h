//
//  EffectPlatformBookMark.h
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/26.
//

#import <Foundation/Foundation.h>
#import "IESCategoryModel.h"
#import "IESEffectModel.h"
#import "IESPlatformPanelModel.h"

@interface EffectPlatformBookMark: NSObject

+ (void)markReadForCategory:(IESCategoryModel *)category;
+ (void)markReadForEffect:(IESEffectModel *)effect;
+ (void)markReadForPanel:(IESPlatformPanelModel *)panel;
+ (void)markReadForPanelName:(NSString *)panelName
                   timeStamp:(NSString *)timeStamp;

+ (BOOL)isReadForCategory:(IESCategoryModel *)category;
+ (BOOL)isReadForEffect:(IESEffectModel *)effect;
+ (BOOL)isReadForPanel:(IESPlatformPanelModel *)panel;
+ (BOOL)isReadForPanelName:(NSString *)panelName
                 timeStamp:(NSString *)timeStamp;

@end
