//
//  NLESegmentEffect+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import "NLESegment+iOS.h"
#import "NLEResourceNode+iOS.h"

/**
 特效作用对象类型
 */
typedef NS_ENUM(NSUInteger, NLESegmentEffectApplyTargetType) {
    NLESegmentEffectApplyTargetTypeMainVideo,    // 主视频
    NLESegmentEffectApplyTargetTypeSubVideo,     // 画中画
    NLESegmentEffectApplyTargetTypeGlobal,       // 全局
};


NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentEffect_OC : NLESegment_OC
///特效名称
@property (nonatomic, copy) NSString *effectName;
///特效资源对象
@property (nonatomic, copy) NSString *effectTag;
///特效资源对象
@property (nonatomic, strong) NLEResourceNode_OC* effectSDKEffect;
///特效作用对象类型
@property (nonatomic, assign) NLESegmentEffectApplyTargetType applyTargetType;
///资源类型
- (NLEResourceType)getType;

/// 特效调节参数
- (void)setAdjustParams:(NSDictionary<NSString *, NSNumber *> *)adjustParams;
- (nullable NSDictionary<NSString *, NSNumber *> *)adjustParams;

@end

NS_ASSUME_NONNULL_END
