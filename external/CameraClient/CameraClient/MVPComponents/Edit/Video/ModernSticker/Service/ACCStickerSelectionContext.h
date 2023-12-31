//
//  ACCStickerSelectionContext.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/1/12.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESThirdPartyStickerModel.h>
#import "ACCStickerBizDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerSelectionContext : NSObject

@property (nonatomic, strong) IESEffectModel *stickerModel;
@property (nonatomic, strong) IESThirdPartyStickerModel *thirdPartyModel;
@property (nonatomic, assign) ACCStickerType stickerType;

@end

NS_ASSUME_NONNULL_END
