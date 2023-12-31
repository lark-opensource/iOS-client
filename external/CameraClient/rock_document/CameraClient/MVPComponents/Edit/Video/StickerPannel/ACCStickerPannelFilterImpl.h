//
//  ACCStickerPannelFilterImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/8/23.
//

#import <Foundation/Foundation.h>
#import "ACCStickerPannelFilter.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerPannelFilterDataSource <NSObject>

- (BOOL)canOpenLiveSticker;

@end

@interface ACCStickerPannelFilterImpl : NSObject <ACCStickerPannelFilter>

@property (nonatomic, weak) id<ACCStickerPannelFilterDataSource> dataSource;
@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END
