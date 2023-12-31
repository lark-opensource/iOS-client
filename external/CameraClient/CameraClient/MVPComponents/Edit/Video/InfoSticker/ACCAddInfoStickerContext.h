//
//  ACCAddInfoStickerContext.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/1/6.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESThirdPartyStickerModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCInfoStickerSource) {
    ACCInfoStickerSourceLoki = 0,
    ACCInfoStickerSourceThirdParty = 1,
    ACCInfoStickerSourceCustom = 2,
};

@interface ACCAddInfoStickerContext : NSObject

@property (nonatomic, assign) NSInteger stickerID;
@property (nonatomic, strong) IESEffectModel *stickerModel;
@property (nonatomic, strong) IESThirdPartyStickerModel *thirdPartyModel;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *tabName;
@property (nonatomic, assign) ACCInfoStickerSource source;
@property (nonatomic, copy) void (^completion)(void);

@end

NS_ASSUME_NONNULL_END
