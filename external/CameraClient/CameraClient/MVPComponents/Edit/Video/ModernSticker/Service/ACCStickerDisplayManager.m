//
//  ACCStickerDisplayManager.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/7.
//

#import "ACCStickerDisplayManager.h"
#import "AWEInteractionStickerModel+DAddition.h"
#import "AWEInteractionEditTagStickerModel.h"

#import "ACCPollStickerView.h"
#import "ACCLiveStickerView.h"
#import "ACCVideoReplyStickerView.h"
#import "ACCVideoReplyCommentStickerView.h"
#import "ACCVideoReplyCommentWithoutCoverStickerView.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "ACCStickerEmptyContentView.h"
#import "ACCStickerContentDisplayProtocol.h"
#import "ACCStickerDisplayContainerConfig.h"
#import "ACCDisplayStickerConfig.h"
#import "ACCModernLiveStickerView.h"
#import "ACCEditTagStickerView.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCStickerDisplayManager()

@property (nonatomic, weak, readwrite) ACCStickerContainerView *stickerContainer;

@end

@implementation ACCStickerDisplayManager

- (instancetype)initWithStickerContainer:(ACCStickerContainerView *)stickerContainer
{
    self = [super init];
    if (self) {
        _stickerContainer = stickerContainer;
        _targetPlayerFrame = CGRectZero;
        _targetContainerRect = CGRectZero;
    }
    return self;
}

- (void)displayWithModels:(NSArray<AWEInteractionStickerModel *> *)models
{
    [self.stickerContainer removeAllStickerViews];
    
    [models enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView<ACCStickerContentProtocol> *contentView = [ACCStickerDisplayManager contentViewForModel:obj];
        ACCDisplayStickerConfig *config = [[ACCDisplayStickerConfig alloc] init];
        config.typeId = @"Studio_Sticker";
        [ACCStickerDisplayManager displayStickerContentView:contentView
                                                     config:config
                                                      model:obj
                                                inContainer:self.stickerContainer];
    }];
}

+ (void)displayStickerContentView:(UIView<ACCStickerContentProtocol> *)contentView
                           config:(ACCDisplayStickerConfig *)config
                            model:(AWEInteractionStickerModel *)model
                      inContainer:(ACCStickerContainerView *)containerView
{
    // Recover Location and Time Config
    AWEInteractionStickerLocationModel *locationModel = [ACCStickerDisplayManager p_locationModelFromInteractionInfo:model];
    if (!locationModel.scale) {
        locationModel.scale = [NSDecimalNumber decimalNumberWithString:@"1"];
    }
    if (!locationModel) {
        locationModel = [[AWEInteractionStickerLocationModel alloc] init];
    };
    config.hierarchyId = @([model indexFromType]);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    // Time Config
    config.timeRangeModel.startTime = locationModel.startTime;
    config.timeRangeModel.endTime = locationModel.endTime;
    config.geometryModel = [locationModel ratioGeometryModel];

    // 这里需要注意一下，空内容的ContentView，需要手动撑开Size
    CGRect playerFrame = containerView.playerFrame ? containerView.playerFrame.CGRectValue : containerView.bounds;
    if (CGSizeEqualToSize(CGSizeZero, contentView.bounds.size) && !CGSizeEqualToSize(CGSizeZero, playerFrame.size)) {
        CGFloat scale = locationModel.scale.floatValue ? : 1.f;
        contentView.bounds = CGRectMake(0.f, 0.f, playerFrame.size.width * locationModel.width.floatValue / scale, playerFrame.size.height * locationModel.height.floatValue / scale);
    }
    if (config.syncAlignPosition && config.alignPoint) {
        CGFloat alignX = playerFrame.origin.x + playerFrame.size.width * locationModel.x.floatValue - config.alignPointOffset.x;
        CGFloat alignY = playerFrame.origin.y + playerFrame.size.height * locationModel.y.floatValue - config.alignPointOffset.y;
        config.alignPosition = [NSValue valueWithCGPoint:CGPointMake(alignX, alignY)];
    }
    [containerView addStickerView:contentView config:config];
    if (config.syncCoordinateChange) {
        ACCBLOCK_INVOKE(contentView.coordinateDidChange);
    }
}

#pragma mark - Private Helper
+ (AWEInteractionStickerLocationModel *)p_locationModelFromInteractionInfo:(AWEInteractionStickerModel *)info
{
    AWEInteractionStickerLocationModel *location = nil;
    NSData* data = [info.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
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
    return location;
}

#pragma mark - Relations/将stickertype与view进行关联
+ (UIView<ACCStickerContentProtocol> *)contentViewForModel:(AWEInteractionStickerModel *)model
{
    switch (model.type) {
        case AWEInteractionStickerTypePoll:
            return [[ACCPollStickerView alloc] initWithStickerModel:model];
        case AWEInteractionStickerTypeLive:
            return [ACCModernLiveStickerView createLiveStickerViewWithModel:model];
        case AWEInteractionStickerTypeVideoReply:
            return [[ACCVideoReplyStickerView alloc] initWithStickerModel:model];
        case AWEInteractionStickerTypeVideoReplyComment: {
            ACCVideoReplyCommentViewType viewType = [[(AWEInteractionVideoReplyCommentStickerModel *)model videoReplyCommentInfo] viewType];
            switch (viewType) {
                case ACCVideoReplyCommentViewTypeWithoutCover:
                    return [[ACCVideoReplyCommentWithoutCoverStickerView alloc] initWithStickerModel:model];
                case ACCVideoReplyCommentViewTypeWithCover:
                    return [[ACCVideoReplyCommentStickerView alloc] initWithStickerModel:model];
            }
        }
        case AWEInteractionStickerTypeEditTag:
            return [[ACCEditTagStickerView alloc] initWithStickerModel:model];
        default:
            return [[ACCStickerEmptyContentView alloc] initWithStickerModel:model];
    }
}

@end
