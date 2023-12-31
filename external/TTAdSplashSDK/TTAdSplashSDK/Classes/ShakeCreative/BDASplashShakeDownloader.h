//
//  BDASplashShakeDownloader.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/12.
//

#import <Foundation/Foundation.h>

@class TTAdSplashModel;

NS_ASSUME_NONNULL_BEGIN

/// 开屏摇一摇样式，素材下载工具类。
@interface BDASplashShakeDownloader : NSObject

/// 下载摇一摇创意相关素材
/// @param models 这一刷的广告创意数据
+ (void)downloadShakeAdResourceWithModel:(NSArray <TTAdSplashModel *> *)models;

@end

NS_ASSUME_NONNULL_END
