//
//  ACCCreativePathConstants.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/4/13.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const ACCCreativePathActionKey;
FOUNDATION_EXPORT NSString * const ACCCreativePathCodeKey;
FOUNDATION_EXPORT NSString * const ACCRecordBeofeWillAppearNotification;

typedef NS_ENUM(NSUInteger, ACCCreativeEditAction) {
    ACCCreativeEditActionNone,
    ACCCreativeEditActionEffectEnter,
    ACCCreativeEditActionEffectExit,
};

typedef NS_ENUM(NSUInteger, ACCCreativeEditCode) {
    ACCCreativeEditCodeUnknow,
    ACCCreativeEditCodeWithEffect,
    ACCCreativeEditCodeWithoutEffect,
};
