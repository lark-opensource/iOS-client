//
//  ACCStickerPlayerApplyingImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by aloes on 2020/8/25.
//

#import <Foundation/Foundation.h>
#import "ACCStickerPlayerApplying.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;
@protocol ACCStickerServiceProtocol;
@class AWEVideoPublishViewModel;

@interface ACCStickerPlayerApplyingImpl : NSObject <ACCStickerPlayerApplying>

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, assign) BOOL isIMRecord;

@end

NS_ASSUME_NONNULL_END
