//
//  LVSegmentClipInfo.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"
#import "LVGeometry.h"
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVSegmentClipInfo (Interface)<LVCopying>
/**
 片段裁剪-缩放信息
 */
@property (nonatomic, assign) LVScale scale;
//
///**
// 片段对应资源旋转角度，默认0.0
// */
//@property (nonatomic, assign) CGFloat rotation;
//
///**
// 片段透明度，默认1.0
// */
//@property (nonatomic, assign) CGFloat alpha;

/**
 片段裁剪-形变信息
 */
@property (nonatomic, assign) LVTranslation translation;

/**
片段裁剪-翻转信息
*/
@property (nonatomic, assign) LVFlip flip;

/**
 更新clip信息
 
 @param clip 更新信息
 */
- (void)updateClip:(LVSegmentClipInfo * _Nullable)clip;

@end

NS_ASSUME_NONNULL_END
