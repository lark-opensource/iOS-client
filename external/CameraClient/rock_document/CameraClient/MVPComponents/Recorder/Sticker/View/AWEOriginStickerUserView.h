//
//  AWEOriginStickerUserView.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/9/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/EffectPlatform.h>


@protocol ACCUserModelProtocol;
@protocol ACCCommerceStickerDetailModelProtocol;

@interface AWEOriginStickerUserView : UIView

- (void)updateWithCommerceModel:(id<ACCCommerceStickerDetailModelProtocol>)commerceModel;

- (void)updateWithUserModel:(id<ACCUserModelProtocol>)userModel;

@end
