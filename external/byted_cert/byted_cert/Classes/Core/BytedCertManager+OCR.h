//
//  BytedCertManager+OCR.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/11.
//

#import "BytedCertManager.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (OCR)

/// 调起拍照功能
/// @param params 参数
/// @param completion 回调
+ (void)takePhotoByCameraWithParams:(NSDictionary *_Nullable)params completion:(void (^)(NSDictionary *_Nullable result))completion;

/// 调起相册功能
/// @param params 参数
/// @param completion 回调
+ (void)selectImageByAlbumWithParams:(NSDictionary *_Nullable)params completion:(void (^)(NSDictionary *_Nullable result))completion;

/// 调起底部alert选择相册、拍照
/// @param params 参数
/// @param completion 回调
+ (void)getImageWithParams:(NSDictionary *_Nullable)params completion:(void (^)(NSDictionary *_Nullable result))completion;

/// 上传证件照片
/// @param type 图片类型
/// @param params 认证参数mode、scene等
/// @param completion 回调
+ (void)doOCRWithImageType:(NSString *_Nullable)type params:(NSDictionary *_Nullable)params completion:(void (^)(NSDictionary *_Nullable data, BytedCertError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
