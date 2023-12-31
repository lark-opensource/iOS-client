//
//  NLESegmentImageSticker+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import "NLESegmentSticker+iOS.h"

@class NLEStyCrop_OC;

/// 图片贴纸
@interface NLESegmentImageSticker_OC : NLESegmentSticker_OC

/// 图片裁剪
@property (nonatomic, strong) NLEStyCrop_OC *crop;

/// 图片文件
@property (nonatomic, strong) NLEResourceNode_OC *imageFile;

- (NLEResourceNode_OC *)getResNode;

@end
