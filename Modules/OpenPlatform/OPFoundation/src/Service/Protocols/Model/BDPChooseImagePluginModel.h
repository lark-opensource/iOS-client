//
//  BDPChooseImagePluginModel.h
//  Timor
//
//  Created by 武嘉晟 on 2019/11/19.
//

#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 图片来源
 */
typedef NS_OPTIONS(NSInteger, BDPImageSourceType) {
    BDPImageSourceTypeUnknow    = 0,
    BDPImageSourceTypeAlbum     = 1,
    BDPImageSourceTypeCamera    = 1 << 1
};

/**
 * 图片尺寸的类型
 */
typedef NS_OPTIONS(NSInteger, BDPImageSizeType) {
    BDPImageSizeTypeUnknow      = 0,
    BDPImageSizeTypeOriginal    = 1,
    BDPImageSizeTypeCompressed  = 1 << 1
};

@interface BDPChooseImagePluginModel : BDPBaseJSONModel

@property (nonatomic, assign) NSInteger count;
/// 选择图片的来源, 可能是相册也可能是相机
@property (nonatomic, assign) BDPImageSourceType bdpSourceType;
/// 所选的图片的尺寸，有['original', 'compressed']
@property (nonatomic, assign) BDPImageSizeType bdpSizeType;
/// 摄像头方向
@property (nonatomic, copy) NSString *cameraDevice;
/// camera模式下，拍摄完是否保存到相册
@property (nonatomic, copy) NSString *isSaveToAlbum;
/// album完成按钮自定义文案
@property (nonatomic, copy, nullable) NSString *confirmBtnText;

@end

NS_ASSUME_NONNULL_END
