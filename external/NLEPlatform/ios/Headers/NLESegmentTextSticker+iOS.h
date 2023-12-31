//
//  NLESegmentTextSticker+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import "NLESegmentSticker+iOS.h"

@class NLEStyleText_OC;

@interface NLESegmentTextSticker_OC : NLESegmentSticker_OC
///文本内容
@property (nonatomic, copy) NSString *content;
///文本类型
@property (nonatomic, strong) NLEStyleText_OC *style;
///Json字符串构建对象
+ (instancetype)textStickerWithEffectSDKJSONString:(NSString *)effectSDKJSONString;
///Json字符串设置对象属性
- (void)setEffectSDKJSONString:(NSString *)effectSDKJSONString;
///文本对象转换Json字符串
- (NSString *)toEffectJSON;

@end
