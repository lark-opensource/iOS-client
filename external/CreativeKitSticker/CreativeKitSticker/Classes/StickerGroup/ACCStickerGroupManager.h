//
//  ACCStickerGroupManager.h
//  CreativeKitSticker-Pods-Aweme
//
//  Created by xiangpeng on 2021/5/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerContainerView;
@class ACCBaseStickerView;

@interface ACCStickerGroupManager : NSObject

- (instancetype)initWithContainer:(ACCStickerContainerView *)container;

- (void)addStickerView:(__kindof ACCBaseStickerView *)stickerView;

- (NSArray<__kindof ACCBaseStickerView *> *)subStickerViewsInGroup:(NSNumber *)groupId;

@end

NS_ASSUME_NONNULL_END
