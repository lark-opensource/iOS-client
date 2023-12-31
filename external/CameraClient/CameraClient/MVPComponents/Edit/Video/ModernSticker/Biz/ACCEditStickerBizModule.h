//
//  ACCEditStickerBizModule.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/16.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceContainer.h>

@interface ACCEditStickerBizModule : NSObject

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>) serviceProvider;

- (void)recoverStickers;
- (void)readyForPublish;

@end
