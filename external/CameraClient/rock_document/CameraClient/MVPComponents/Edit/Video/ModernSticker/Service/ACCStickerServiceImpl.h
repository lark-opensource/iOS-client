//
//  ACCStickerServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/9/4.
//

#import <Foundation/Foundation.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCEditStickerServiceImplProtocol.h"
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate, AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

@interface ACCStickerServiceImpl : NSObject <ACCStickerServiceProtocol, ACCEditStickerServiceImplProtocol>

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *repository;

@property (nonatomic, copy) ACCStickerContainerView *(^stickerContainerLoader)(void);

@end

NS_ASSUME_NONNULL_END
