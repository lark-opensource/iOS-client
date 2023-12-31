//
//  ACCImageAlbumEditTagStickerHandler.m
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/9/29.
//

#import "ACCImageAlbumEditTagStickerHandler.h"
#import "ACCEditTagStickerView.h"
#import "ACCAlbumEditTagStickerConfig.h"
#import "ACCStickerBizDefines.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCStickerContainerView+CameraClient.h"
#import "ACCImageAlbumStickerModel.h"
#import <CreativeKitSticker/UIView+ACCStickerSDKUtils.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "ACCImageAlbumSafeAreaPlugin.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation ACCImageAlbumEditTagStickerHandler

- (void)addTagWithModel:(AWEInteractionEditTagStickerModel *)model inContainerView:(ACCStickerContainerView *)containerView constructorBlock:(void (^)(ACCAlbumEditTagStickerConfig * _Nullable))constructorBlock
{
    ACCEditTagStickerView *tagView = [[ACCEditTagStickerView alloc] initWithStickerModel:model];

    ACCAlbumEditTagStickerConfig *config = [[ACCAlbumEditTagStickerConfig alloc] init];
    config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
        if ((gestureType & ACCStickerGestureTypePinch) || (gestureType & ACCStickerGestureTypeRotate)) {
            return NO;
        }
        return YES;
    };
    @weakify(tagView);
    @weakify(self);
    config.deleteAction = ^{
        @strongify(self);
        @strongify(tagView);
        [self.logger logTagWillDeleteWithAddtionalInfo:@{@"tag_type": [tagView.interactionStickerModel.editTagInfo tagType]?:@"", @"tag_id": [tagView.interactionStickerModel.editTagInfo tagId]?:@"", @"pic_location": @([self.dataProvider picLocation] + 1)}];
        [self.stickerContainerView removeStickerView:tagView];
    };

    CGPoint normalizedTagCenterPoint = [tagView normalizedTagCenterPoint];
    config.alignPoint = @(normalizedTagCenterPoint);
    config.changeDirection = ^{
        @strongify(self);
        @strongify(tagView);
        [self.logger logTagAdjustWithAddtionalInfo:@{@"tag_type": [tagView.interactionStickerModel.editTagInfo tagType]?:@"", @"tag_id": [tagView.interactionStickerModel.editTagInfo tagId]?:@"", @"pic_location": @([self.dataProvider picLocation] + 1)}];
        if (self.onTagChangeDirection) {
            self.onTagChangeDirection(tagView);
        }
    };
    config.edit = ^{
        @strongify(self);
        @strongify(tagView);
        [self.logger logTagReEditWithAddtionalInfo:@{@"tag_type": [tagView.interactionStickerModel.editTagInfo tagType]?:@"", @"tag_id": [tagView.interactionStickerModel.editTagInfo tagId]?:@"",  @"pic_location": @([self.dataProvider picLocation] + 1)}];
        if (self.onEditTag) {
            self.onEditTag(tagView);
        }
    };
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            [self.logger logTagDragWithAddtionalInfo:@{@"tag_type": [tagView.interactionStickerModel.editTagInfo tagType]?:@"", @"tag_id": [tagView.interactionStickerModel.editTagInfo tagId]?:@"",  @"pic_location": @([self.dataProvider picLocation] + 1)}];
        }
    };
    config.boxMargin = UIEdgeInsetsMake(10, 0, 10, 0);
    config.typeId = ACCStickerTypeIdEditTag;
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryHigh + 100); // highest, hierarchyId used as number, the bigger number the higher hierarchy level
    if (constructorBlock) {
        constructorBlock(config);
    }
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    CGFloat realStartTime = 0.f;
    CGFloat realDuration = self.player.stickerInitialEndTime;
    NSString *startTime = [NSString stringWithFormat:@"%.4f", realStartTime];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", realDuration];
    config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    AWEInteractionStickerLocationModel *locationModel = [self adaptedLocationWithInteractionInfo:model inContainerView:containerView];
    if (!locationModel) {
        locationModel = [[AWEInteractionStickerLocationModel alloc] init];
    }
    config.geometryModel = [locationModel ratioGeometryModel];
    [containerView addStickerView:tagView config:config];
}

- (void)reverseTag:(ACCEditTagStickerView *)tagView
{
    ACCStickerViewType tag = [self.stickerContainerView stickerViewWithContentView:tagView];

    UIView *copyedView = [tag copy];
    copyedView.frame = tag.frame;
    [copyedView accs_setAnchorPointForRotateAndScale:[tagView normalizedTagCenterPoint]];
    copyedView.transform = CGAffineTransformScale(copyedView.transform, -1, 1);
    [copyedView accs_setAnchorPointForRotateAndScale:CGPointMake(0.5, 0.5)];
    
    if (tagView.interactionStickerModel.editTagInfo.orientation == ACCEditTagOrientationLeft) {
        tagView.interactionStickerModel.editTagInfo.orientation = ACCEditTagOrientationRight;
        tag.config.alignPoint = @([tagView normalizedTagCenterPoint]);
    } else {
        tagView.interactionStickerModel.editTagInfo.orientation = ACCEditTagOrientationLeft;
        tag.config.alignPoint = @([tagView normalizedTagCenterPoint]);
    }

    [self makeGeometrySafeWithTag:tagView withNewCenter:copyedView.center];
}

- (void)makeGeometrySafeWithTag:(ACCEditTagStickerView *)tagView withNewCenter:(CGPoint)newCenter
{
    ACCStickerViewType tag = [self.stickerContainerView stickerViewWithContentView:tagView];
    
    ACCImageAlbumSafeAreaPlugin *imageAlbumSafeAreaPlugin = [[self.stickerContainerView plugins] acc_match:^BOOL(__kindof id<ACCStickerContainerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[ACCImageAlbumSafeAreaPlugin class]];
    }];
    newCenter = [imageAlbumSafeAreaPlugin fixStickerView:tag withWillChangeLocationWithCenter:newCenter];
    
    ACCStickerGeometryModel *newGeometryModel = [tag interactiveStickerGeometryWithCenterInPlayer:newCenter interactiveBoundsSize:CGSizeZero]; // use interactive geometry to simulate new center in normalized coordinate system; just to get x and y
    ACCStickerGeometryModel *geometryModel = [tag.stickerGeometry copy];
    geometryModel.xRatio = newGeometryModel.xRatio;
    geometryModel.yRatio = newGeometryModel.yRatio;
    geometryModel.preferredRatio = YES;
    [tag recoverWithGeometryModel:geometryModel];
}

#pragma mark - InteractionInfo

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex inContainerView:(ACCStickerContainerView *)containerView
{
    for (UIView<ACCStickerProtocol> *sticker in [[containerView stickerViewsWithTypeId:ACCStickerTypeIdEditTag] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        if ([item.contentView isKindOfClass:[ACCEditTagStickerView class]]) {
            // tags not in material will be filtered out
            CGRect mediaRect = CGRectMake((containerView.frame.size.width - containerView.mediaActualSize.width) / 2.f, (containerView.frame.size.height - containerView.mediaActualSize.height) / 2.f, containerView.mediaActualSize.width, containerView.mediaActualSize.height);
            CGRect intersectionRect = CGRectIntersection(mediaRect, item.frame);
            if (CGRectIsNull(intersectionRect) || CGRectGetWidth(intersectionRect) <= 1 / [UIScreen mainScreen].scale || CGRectGetHeight(intersectionRect) <= 1 / [UIScreen mainScreen].scale) {
                return NO;
            }
            return YES;
        }
        return NO;
    }]) {
        [self addEditTagInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addEditTagInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView toArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    ACCEditTagStickerView *editTagSticker = (ACCEditTagStickerView *)(stickerView.contentView);
    AWEInteractionEditTagStickerModel *interactionStickerInfo = [[AWEInteractionEditTagStickerModel alloc] init];
    interactionStickerInfo.type = AWEInteractionStickerTypeEditTag;
    interactionStickerInfo.editTagInfo = editTagSticker.interactionStickerModel.editTagInfo;
    
    CGPoint point = [editTagSticker convertPoint:editTagSticker.center toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:editTagSticker.bounds.size] andTimeRangeModel:nil];
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = locationInfoModel;
        if (self.player) {
            finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
            interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
        } else {
            ACCStickerContainerView *containerView = (ACCStickerContainerView *)stickerView.stickerContainer;
            finalLocation = [ACCStickerHandler convertRatioLocationModel:finalLocation fromPlayerSize:containerView.playerRect.size toPlayerSize:containerView.mediaActualSize];
            interactionStickerInfo.adaptorPlayer = YES;
        }
        if (finalLocation) {
            NSError *error = nil;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&error];
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
            if (arrJsonData) {
                NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                interactionStickerInfo.trackInfo = arrJsonStr;
            }
            
            interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
            [interactionStickers addObject:interactionStickerInfo];
        }
    }
}

- (BOOL)canRecoverImageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    return sticker.interactionSticker && [sticker.interactionSticker isKindOfClass:AWEInteractionEditTagStickerModel.class];
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView imageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    if ([self canRecoverImageAlbumStickerModel:sticker]) {
        AWEInteractionEditTagStickerModel *model = [(AWEInteractionEditTagStickerModel *)sticker.interactionSticker copy];
        model.editTagInfo = [model.editTagInfo copy];
        [self addTagWithModel:model inContainerView:containerView constructorBlock:^(ACCAlbumEditTagStickerConfig * _Nullable config) {
            
        }];
    }
}

- (NSUInteger)numberOfTags
{
    return [self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdEditTag].count;
}

@end
