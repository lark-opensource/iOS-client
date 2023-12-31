//
//  AWESpecialEffectSimplifiedABManager.h
//  Indexer
//
//  Created by Daniel on 2021/11/11.
//

#import <Foundation/Foundation.h>

@class AWEVideoPublishViewModel;

typedef enum : NSUInteger {
    AWESpecialEffectSimplifiedPanelNone,
    AWESpecialEffectSimplifiedPanelImageOnly,
    AWESpecialEffectSimplifiedPanelAll,
} AWESpecialEffectSimplifiedPanelType;

@interface AWESpecialEffectSimplifiedABManager : NSObject

#pragma mark - Public Methods

/// 是否要使用新的特效icon（编辑页右上角的tool bar item）
+ (BOOL)shouldUseNewBarItemIcon;

/// 是否要替换成特效简化面板
/// @param isPhoto 是否是单图视频
+ (BOOL)shouldUseSimplifiedPanel:(AWEVideoPublishViewModel *)publishModel;

/// 特效简化面板生效场景
/// @return 0-对照组；1-仅单图视频生效；2-全路径生效
+ (AWESpecialEffectSimplifiedPanelType)getSimplifiedPanelType;

@end
