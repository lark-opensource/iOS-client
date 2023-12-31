//
//  UIApplication+BDCTAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIApplication (BDCTAdditions)

+ (void)bdct_requestAlbumPermissionWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock;

+ (void)bdct_jumpToAppSettingWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
