//
//  ACCMVPageStyleABHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCCutsameSelectHintType) {
    ACCCutsameSelectHintTypeDefault = 0,
    ACCCutsameSelectHintTypeA,
    ACCCutsameSelectHintTypeB,
    ACCCutsameSelectHintTypeC,
};

typedef NS_ENUM(NSUInteger, ACCCutsameNameTextType) {
    ACCCutsameNameTextTypeDefault = 0,
    ACCCutsameNameTextTypeA,
    ACCCutsameNameTextTypeB,
};

@interface ACCMVPageStyleABHelper : NSObject

/// 影集功能文案优化
+ (NSString *)acc_cutsameNameText;
+ (NSString *)acc_cutsameTitleText;
+ (NSString *)acc_cutsameSelectHintText;

@end

NS_ASSUME_NONNULL_END
