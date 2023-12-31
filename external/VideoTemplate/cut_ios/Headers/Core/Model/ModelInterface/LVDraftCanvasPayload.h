//
//  LVDraftCanvasPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"
NS_ASSUME_NONNULL_BEGIN

@interface LVCanvasAsset : NSObject
/**
 资源图
 */
@property (nonatomic, strong, nullable) UIImage *image;

/**
 资源标识
 */
@property (nonatomic, copy) NSString *identifier;

/**
 初始资源
 
 @param image 图片
 @param identifier 图片标识
 @return 资源
 */
- (instancetype)initWithImage:(UIImage * _Nullable)image identifier:(NSString *)identifier;

@end

/**
 画布素材解析模型
 */
@interface LVDraftCanvasPayload (Interface)

/**
 画布背景图资源
 */
@property (nonatomic, strong, nullable) LVCanvasAsset *asset;

/**
 相册图资源
 */
@property (nonatomic, strong, nullable) LVCanvasAsset *albumAsset;

/**
 背景颜色值，用16进制表示，例如：#f8dd4a，如果选择图片后
 */
@property (nonatomic, copy) NSString *color;

/**
 模糊的程度
 */
//@property (nonatomic, assign) CGFloat blur;

/**
 图片的路径
 */
@property (nonatomic, copy, nullable) NSString *imageFileKey;

/*
 小图路径--不用存草稿
 */
@property (nonatomic, copy, nullable) NSString *smallImageFileKey;

/**
 相册选择的最后一张图的路径
 */
@property (nonatomic, copy, nullable) NSString *albumImageFileKey;

/**
 统计使用的画布名
 */
@property (nonatomic, copy) NSString *canvasStyle;

/**
 统计使用的画布标识
 */
@property (nonatomic, copy) NSString *canvasStyleId;

/**
更新 画布背景图资源
*/
- (void)updateAsset:(LVCanvasAsset* _Nullable)asset;

/**
更新  相册图资源
*/
- (void)updateAlbumAsset:(LVCanvasAsset* _Nullable)asset;

/*
 裁剪尺寸
 原尺寸会被短边压缩到600px
 */
+ (CGSize)smallImagSize:(CGSize)originalSize;

@end

NS_ASSUME_NONNULL_END
