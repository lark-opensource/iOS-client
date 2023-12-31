//
//  ACCStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/1/21.
//

#import "ACCStickerHandler.h"
#import "ACCStickerHandler+Private.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMacrosTool.h>
#import "ACCStickerContainerView+CameraClient.h"

@implementation ACCStickerHandler

- (ACCStickerContainerView *)stickerContainerView {
    if (!_stickerContainerView && self.stickerContainerLoader) {
        _stickerContainerView = self.stickerContainerLoader();
    }
    return _stickerContainerView;
}

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx
{
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{

}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig onCompletion:(nonnull void (^)(void))completionHandler
{
    
}

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return NO;
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return NO;
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return NO;
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex inContainerView:(ACCStickerContainerView *)containerView
{
}

- (void)reset
{
}

- (void)finish
{
}

- (BOOL)canRecoverStickerStorageModel:(NSObject<ACCSerializationProtocol> *)sticker
{
    return NO;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView storageModel:(NSObject<ACCSerializationProtocol> *)sticker
{}

- (BOOL)canRecoverImageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    return NO;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView imageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{}

- (void)applyStickerStorageModel:(NSObject<ACCSerializationProtocol> *)sticker
                    forContainer:(ACCStickerContainerView *)containerView
                    stickerIndex:(NSUInteger)stickerIndex
                 imageAlbumIndex:(NSUInteger)imageAlbumIndex
{}
- (void)updateSticker:(NSInteger)stickerId withNewId:(NSInteger)newId {}

#pragma mark - Utils
+ (AWEInteractionStickerLocationModel *)convertRatioLocationModel:(AWEInteractionStickerLocationModel *)model
                                                   fromPlayerSize:(CGSize)fromSize
                                                     toPlayerSize:(CGSize)toSize
{
    if (!fromSize.width || !fromSize.height || !toSize.width || !toSize.height) {
        return model;
    }
    
    if (fromSize.width / fromSize.height == toSize.width / toSize.height) {
        return model;
    }
    
    CGFloat x = [model.x floatValue];
    CGFloat y = [model.y floatValue];
    CGFloat width = [model.width floatValue];
    CGFloat height = [model.height floatValue];
    
    x = (x * fromSize.width + (toSize.width - fromSize.width) / 2.0) / toSize.width;
    y = (y * fromSize.height + (toSize.height - fromSize.height) / 2.0) / toSize.height;
    width = width * fromSize.width / toSize.width;
    height = height * fromSize.height / toSize.height;
    
    AWEInteractionStickerLocationModel *locModel = [model copy];
    locModel.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", x]];
    locModel.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
    locModel.width = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", width]];
    locModel.height = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", height]];
    return locModel;
}

- (AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(AWEInteractionStickerModel *)model
{
    AWEInteractionStickerLocationModel *locationModel = [self locationModelFromInteractionInfo:model];
    if (model.adaptorPlayer && self.player) {
        locationModel = [self.player resetStickerLocation:locationModel isRecover:YES];
    }
    return locationModel;
}

- (AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(AWEInteractionStickerModel *)model inContainerView:(ACCStickerContainerView *)containerView
{
    if (!model || !containerView) {
        return nil;
    }
    AWEInteractionStickerLocationModel *locationModel = [self locationModelFromInteractionInfo:model];
    if (model.adaptorPlayer) {
        locationModel = [ACCStickerHandler convertRatioLocationModel:locationModel fromPlayerSize:containerView.mediaActualSize toPlayerSize:containerView.playerRect.size];
    }
    return locationModel;
}

- (AWEInteractionStickerLocationModel *)locationModelFromInteractionInfo:(AWEInteractionStickerModel *)info
{
    if (ACC_isEmptyString(info.trackInfo)){
        return nil;
    }

    AWEInteractionStickerLocationModel *location = nil;
    NSData* data = [info.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return nil;
    }
    NSError *error = nil;
    NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if ([values count]) {
        NSArray *locationArr = [MTLJSONAdapter modelsOfClass:[AWEInteractionStickerLocationModel class] fromJSONArray:values error:&error];
        if ([locationArr count]) {
            location = [locationArr firstObject];
        }
    }
    if (error != nil) {
        AWELogToolError(AWELogToolTagEdit, @"[locationModelFromInteractionInfo] -- error:%@", error);
    }
    
    return location;
}

@end
