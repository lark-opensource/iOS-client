//
//  AWEInfoStickerManager.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/10/12.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEInfoStickerResponse.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEInfoStickerManager : NSObject

- (void)fetchTemperatureCompletion:(void(^)(NSError *error, NSString *temperature))complection;

- (void)fetchPOIPermissionCompletion:(void (^)(NSError *))complection;

- (NSString *)fetchCurrentTime;

@end

NS_ASSUME_NONNULL_END
