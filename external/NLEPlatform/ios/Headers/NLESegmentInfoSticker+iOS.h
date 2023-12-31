//
//  NLESegmentInfoSticker+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLESegmentInfoSticker_iOS_h
#define NLESegmentInfoSticker_iOS_h
#import <Foundation/Foundation.h>
#import "NLESegmentSticker+iOS.h"


@interface NLESegmentInfoSticker_OC : NLESegmentSticker_OC

/// 信息化贴纸素材资源
@property (nonatomic, strong) NLEResourceNode_OC *effectSDKFile;

- (NLEResourceNode_OC *)getResNode;

@end

#endif /* NLESegmentInfoSticker_iOS_h */

