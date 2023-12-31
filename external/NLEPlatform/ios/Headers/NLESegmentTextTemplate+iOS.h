//
//  NLESegmentTextTemplate+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "NLEResourceNode+iOS.h"
#import "NLESegment+iOS.h"
#import "NLETextTemplateClip+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentTextTemplate_OC : NLESegment_OC
/// 资源对象
@property (nonatomic, strong) NLEResourceNode_OC* effectSDKFile;

/// 文字模板用到的字体/贴纸资源
@property (nonatomic, copy) NSArray<NLEResourceNode_OC *> *fontResList;

/// 文字模板的文字片段
@property (nonatomic, copy) NSArray<NLETextTemplateClip_OC *>  * _Nullable textClips;

/// 资源类型
- (NLEResourceType)getType;

/// 添加文本
/// 目前文本内容需自行添加
/// @param textClip 文本内容
- (void)addTextClip:(NLETextTemplateClip_OC *)textClip;

/// 删除所有文本
- (void)clearTextClips;

/// 删除指定文本
/// @param textClip 文本内容
- (void)removeTextClip:(NLETextTemplateClip_OC *)textClip;

@end

NS_ASSUME_NONNULL_END
