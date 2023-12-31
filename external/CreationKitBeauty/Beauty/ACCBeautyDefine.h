//
//  ACCBeautyDefine.h
//  CameraClient
//
//  Created by Liu Deping on 2020/4/26.
//

#import <Foundation/Foundation.h>

static void * const ACCRecordBeautyPanelContext = (void *)&ACCRecordBeautyPanelContext;


typedef NS_ENUM(NSInteger, AWEComposerBeautyGender) {
    AWEComposerBeautyGenderMen = 0,
    AWEComposerBeautyGenderWomen = 1,
    AWEComposerBeautyGenderBoth = 2,
};


typedef NS_ENUM(NSUInteger, AWEBeautyCellIconStyle) {
    AWEBeautyCellIconStyleRound = 0,
    AWEBeautyCellIconStyleSquare = 1
};

// https://bytedance.feishu.cn/docs/doccnHgNFnscpsTfLJg47DgUbLc
typedef NS_ENUM(NSUInteger, ACCBeautyHeaderViewStyle) {
    ACCBeautyHeaderViewStyleDefault = 0,
    ACCBeautyHeaderViewStyleSaveCancelBtn,
    ACCBeautyHeaderViewStylePlayBtn,
    ACCBeautyHeaderViewStyleReplaceIconWithText,
};

static NSString *const HTSVideoRecorderBeautyKey = @"HTSVideoRecorderBeautyKey";
