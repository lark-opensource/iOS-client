//
//  ACCInfoStickerNetServiceProtocol.h
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/22.
//

#import <Foundation/Foundation.h>
@class AWEInfoStickerResponse;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCInfoStickerNetServiceProtocol <NSObject>

/*
*  获取温度贴纸信息
*/
- (void)requestTemperatureInfoStickersWithCityCode:(NSString *)cityCode
                                        completion:(void (^)(AWEInfoStickerResponse * _Nullable model, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
