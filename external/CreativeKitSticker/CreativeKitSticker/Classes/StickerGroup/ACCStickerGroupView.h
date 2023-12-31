//
//  ACCStickerGroupView.h
//  CreativeKitSticker-Pods-Aweme
//
//  Created by xiangpeng on 2021/5/21.
//

#import <Foundation/Foundation.h>
#import "ACCGestureResponsibleStickerView.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCBaseStickerView;

@interface ACCStickerGroupView : ACCGestureResponsibleStickerView

@property (nonatomic, strong, readonly) NSMutableArray<__kindof ACCBaseStickerView *> *stickerList;

- (instancetype)initWithConfig:(__kindof ACCStickerConfig *)config;

- (void)addStickerView:(__kindof ACCBaseStickerView *)stickerView;



@end

NS_ASSUME_NONNULL_END
