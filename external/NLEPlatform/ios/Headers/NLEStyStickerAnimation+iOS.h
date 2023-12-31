//
//  NLEStyStickerAnimation.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEStyStickerAnimation_OC : NLENode_OC

/// 是否为循环动画，若为循环动画，则将inPath作为动画路径
@property (nonatomic, assign) BOOL loop;

/// 入场动画持续时间，单位微秒
@property (nonatomic, assign) CMTime inDuration;

/// 出场动画持续时间，单位微秒
@property (nonatomic, assign) CMTime outDuration;

/// 入场(或循环)动画
@property (nonatomic, strong) NLEResourceNode_OC *inAnimation;

/// 出场动画
@property (nonatomic, strong) NLEResourceNode_OC *outAnimation;

@end

NS_ASSUME_NONNULL_END
