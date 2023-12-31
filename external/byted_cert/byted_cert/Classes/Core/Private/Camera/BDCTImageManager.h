//
//  BytedCertCamera.h
//  BytedCert
//
//  Created by LiuChundian on 2019/5/29.
//

#import <Foundation/Foundation.h>

@class BDCTFlow;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTImageManager : NSObject

@property (nonatomic, weak) BDCTFlow *flow;

/// 调起底部alert选择相册、拍照
/// @param args 参数
/// @param completion 回调
- (void)selectImageWithParams:(NSDictionary *)args completion:(void (^)(NSDictionary *_Nullable))completion;

/// 根据图片类型返回图片
/// @param type 图片
- (NSData *)getImageByType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
