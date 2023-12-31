//
//  ACCTextStickerTextModelHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2021/1/28 00:39.
//	Copyright © 2021 Bytedance. All rights reserved.
	

#import <Foundation/Foundation.h>

@class AWEStoryFontModel;
NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerTextModelHelper : NSObject

+ (CGFloat)fitFontSizeWithContent:(NSString *)content fontModel:(AWEStoryFontModel *)fontModel fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
