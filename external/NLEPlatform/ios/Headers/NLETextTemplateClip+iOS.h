//
//  NLETextTemplateClip+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETextTemplateClip_OC : NLENode_OC

/// 文本内容
@property (nonatomic, copy) NSString *content;

/// 对应的索引值
@property (nonatomic, assign) NSInteger index;

@end

NS_ASSUME_NONNULL_END
