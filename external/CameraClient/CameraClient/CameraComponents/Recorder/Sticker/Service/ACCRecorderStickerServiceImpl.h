//
//  ACCRecorderStickerServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import <Foundation/Foundation.h>

#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditViewContainer;

@interface ACCRecorderStickerServiceImpl : NSObject <ACCRecorderStickerServiceProtocol>

@property (nonatomic, copy) ACCStickerContainerView *(^getStickerContainerViewBlock)(void);
@property (nonatomic, copy) id<ACCRecorderViewContainer> (^getViewContainerBlock)(void);

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
