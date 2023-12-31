//
//  LVCanvasConfig.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDefinition.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN


//@interface LVCanvasConfig : MTLModel <MTLJSONSerializing, LVCopying>

@interface LVCanvasPreviewFrame: NSObject

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGSize canvasSize;

@end

@interface LVCanvasConfig(Interface)<LVCopying>

/**
 画布比例
 */
@property (nonatomic, assign) LVCanvasRatio ratio;

/**
 当前画布尺寸
 */
@property (nonatomic, assign) CGSize size;

/**
 原始画布尺寸
 */
@property (nonatomic, assign) CGSize originRatioSize;

/**
 导出尺寸
 */
- (CGSize)exportSizeForResolution:(LVExportResolution)resolution;

/**
 尺寸修剪
*/
- (CGSize)fitMaxSizeForResolution:(CGFloat)resolution originSize:(CGSize)originSize;

- (LVCanvasPreviewFrame *)previewFrameInSuperRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
