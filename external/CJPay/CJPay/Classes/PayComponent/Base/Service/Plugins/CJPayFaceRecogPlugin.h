//
//  CJPayFaceRecogPlugin.h
//  vvipAweme
//
//  Created by 尚怀军 on 2022/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayFaceRecogPlugin <NSObject>

/// 上传活体验证视频
/// @param appid appid
/// @param merchantid 商户号
/// @param videoPath 视频存储路径
- (void)asyncUploadFaceVideoWithAppId:(NSString *)appId
                           merchantId:(NSString *)merchantId
                            videoPath:(NSString *)videoPath;


@end

NS_ASSUME_NONNULL_END
