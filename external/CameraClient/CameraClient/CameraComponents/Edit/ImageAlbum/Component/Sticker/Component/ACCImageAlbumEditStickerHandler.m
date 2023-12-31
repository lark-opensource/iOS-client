//
//  ACCImageAlbumEditStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/29.
//

#import "ACCImageAlbumEditStickerHandler.h"
#import "ACCImageAlbumData.h"

#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCImageAlbumEditStickerHandler ()

@end
@implementation ACCImageAlbumEditStickerHandler
@dynamic editSticker;
@synthesize allStickerContainers = _allStickerContainers;

- (BOOL)canRecoverStickerStorageModel:(NSObject<ACCSerializationProtocol> *)sticker
{
    return YES;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView storageModel:(NSObject<ACCSerializationProtocol> *)sticker
{
    NSArray *newArray = [self.handlers acc_filter:^BOOL(ACCStickerHandler *handler) {
        if ([handler respondsToSelector:@selector(canRecoverStickerStorageModel:)] &&
            [handler respondsToSelector:@selector(recoverStickerForContainer:storageModel:)]) {
            return YES;
        }
        
        return NO;
    }];
    for (ACCStickerHandler *handler in newArray) {
        if ([handler canRecoverStickerStorageModel:sticker]) {
            [handler recoverStickerForContainer:containerView storageModel:sticker];
        }
    }
}

- (BOOL)canRecoverImageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    return YES;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView imageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    NSArray *newArray = [self.handlers acc_filter:^BOOL(ACCStickerHandler *handler) {
        if ([handler respondsToSelector:@selector(canRecoverImageAlbumStickerModel:)] &&
            [handler respondsToSelector:@selector(recoverStickerForContainer:imageAlbumStickerModel:)]) {
            return YES;
        }
        
        return NO;
    }];
    for (ACCStickerHandler *handler in newArray) {
        if ([handler canRecoverImageAlbumStickerModel:sticker]) {
            [handler recoverStickerForContainer:containerView imageAlbumStickerModel:sticker];
        }
    }
}

- (void)applyStickerStorageModel:(NSObject<ACCSerializationProtocol> *)sticker
                    forContainer:(ACCStickerContainerView *)containerView
                    stickerIndex:(NSUInteger)stickerIndex
                 imageAlbumIndex:(NSUInteger)imageAlbumIndex
{
    NSArray *newArray = [self.handlers acc_filter:^BOOL(ACCStickerHandler *handler) {
        if ([handler respondsToSelector:@selector(applyStickerStorageModel:forContainer:stickerIndex:imageAlbumIndex:)]) {
            return YES;
        }
        
        return NO;
    }];
    
    for (ACCStickerHandler *handler in newArray) {
        if ([handler canRecoverStickerStorageModel:sticker] ) {
            [handler applyStickerStorageModel:sticker forContainer:containerView stickerIndex:stickerIndex imageAlbumIndex:imageAlbumIndex];
        }
    }
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex inContainerView:(ACCStickerContainerView *)containerView
{
    NSArray *newArray = [self.handlers acc_filter:^BOOL(ACCStickerHandler *handler) {
        if ([handler respondsToSelector:@selector(addInteractionStickerInfoToArray:idx:inContainerView:)]) {
            return YES;
        }
        return NO;
    }];
    for (ACCStickerHandler *handler in newArray) {
        [handler addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex inContainerView:containerView];
    }
}

- (void)removeAllInfoStickers
{
    [self.allStickerContainers.allObjects enumerateObjectsUsingBlock:^(ACCStickerContainerView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeAllStickerViews];
    }];
}

#pragma mark - property

- (NSHashTable<ACCStickerContainerView *> *)allStickerContainers
{
    if (!_allStickerContainers) {
        _allStickerContainers = [NSHashTable weakObjectsHashTable];
    }
    
    return _allStickerContainers;
}

- (void)setStickerContainerView:(ACCStickerContainerView *)stickerContainerView
{
    [self.handlers enumerateObjectsUsingBlock:^(ACCStickerHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.stickerContainerView = stickerContainerView;
    }];
}

@end
