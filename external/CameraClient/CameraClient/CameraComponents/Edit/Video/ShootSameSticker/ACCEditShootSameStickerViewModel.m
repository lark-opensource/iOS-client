//
//  ACCEditShootSameStickerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/23.
//

#import "AWERepoStickerModel.h"
#import "ACCEditShootSameStickerViewModel.h"

#import "ACCShootSameStickerHandlerFactory.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCEditShootSameStickerViewModel

@synthesize handlers;
@synthesize onSelectTimeCallback;
@synthesize configDelegation;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.handlers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public Methods

- (void)createHandlersFromPublishModel
{
    for (ACCShootSameStickerModel *shootSameStickerModel in self.inputData.publishModel.repoSticker.shootSameStickerModels) {
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        if (handler == nil) {
            id<ACCShootSameStickerHandlerFactoryProtocol> factory = [ACCShootSameStickerHandlerFactory factoryWithType:shootSameStickerModel.stickerType];
            handler = [factory createHandlerWithStickerModel:self.inputData.publishModel
                                       shootSameStickerModel:shootSameStickerModel
                                            configDelegation:self.configDelegation];
            handler.repository = self.repository;
            handler.onSelectTimeCallback = self.onSelectTimeCallback;
            if (handler == nil) {
                continue;
            }
            [self.stickerService registStickerHandler:handler];
            self.handlers[@(shootSameStickerModel.stickerType)] = handler;
        }
    }
}

- (void)createStickerViews
{
    AWEVideoPublishViewModel *publishModel = self.inputData.recorderPublishModel ?: self.inputData.sourceModel;
    for (ACCShootSameStickerModel *shootSameStickerModel in publishModel.repoSticker.shootSameStickerModels) {
        if (shootSameStickerModel.isDeleted) {
            continue;
        }
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        if ([UIDevice acc_isIPad] && shootSameStickerModel.stickerType == 4 && publishModel == self.inputData.sourceModel) {
            if (shootSameStickerModel.tempLocationModel == NULL) {
                shootSameStickerModel.tempLocationModel = [shootSameStickerModel.locationModel copy];
            }
            //adjust locationModel's scale and position to adapt video content
            shootSameStickerModel.locationModel = [self adjustStickerLocationModel:shootSameStickerModel.locationModel fromShootCoordinateSystemSize:handler.stickerContainerView.originalFrame.size toContentCoordinateSystemSize:[handler.stickerContainerView playerRect].size stickerHandler:handler];
        }
        [handler createStickerViewWithShootSameStickerModel:shootSameStickerModel
                                               isInRecorder:NO];
    }
}

- (void)updateShootSameStickerModel
{
    AWEVideoPublishViewModel *publishModel = self.inputData.recorderPublishModel ?: self.inputData.sourceModel;
    for (ACCShootSameStickerModel *shootSameStickerModel in self.inputData.publishModel.repoSticker.shootSameStickerModels) {
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        [handler updateLocationModelWithShootSameStickerModel:shootSameStickerModel];
    }
    for (ACCShootSameStickerModel *shootSameStickerModel in publishModel.repoSticker.shootSameStickerModels) {
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        [handler updateLocationModelWithShootSameStickerModel:shootSameStickerModel];
    }
}

- (AWEInteractionStickerLocationModel *) adjustStickerLocationModel:(AWEInteractionStickerLocationModel *)locationModel
                                      fromShootCoordinateSystemSize:(CGSize)videoShootSize
                                      toContentCoordinateSystemSize:(CGSize)videoContentSize   stickerHandler:(ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *)handler
{
    NSDecimalNumber *transformScale = nil;
    AWEInteractionStickerLocationModel *adjustLocationModel = [locationModel copy];
    if (!CGSizeEqualToSize(videoShootSize, videoContentSize)) {
        CGFloat wScale = videoContentSize.width / videoShootSize.width;
        CGFloat hScale = videoContentSize.height / videoShootSize.height;
        NSDecimalNumber *widthScale = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f",wScale]];
        NSDecimalNumber *heightScale = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f",hScale]];
        transformScale = [widthScale compare:heightScale] == NSOrderedAscending ? widthScale : heightScale;
        adjustLocationModel.scale = [adjustLocationModel.scale decimalNumberByMultiplyingBy:transformScale];
        CGFloat expansionHeight = (videoContentSize.height - videoContentSize.width * videoShootSize.height / videoShootSize.width ) / 2;
        CGFloat y = [adjustLocationModel.y floatValue];
        CGFloat height = videoContentSize.height - 2 * expansionHeight;
        if (y < 0.5) {
            y = (y * height + expansionHeight) / videoContentSize.height;
        } else if (y > 0.5) {
            y = (videoContentSize.height - (height - y * height + expansionHeight)) / videoContentSize.height;
        }
        adjustLocationModel.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
        CGFloat x = [adjustLocationModel.x floatValue];
        if (x < 0.5) {
            x = ((x * videoShootSize.width - 16) * transformScale.floatValue + 16) / videoContentSize.width;
        } else if(x > 0.5) {
            x = (videoContentSize.width - (videoShootSize.width - x * videoShootSize.width - 56) * transformScale.floatValue - 56) / videoContentSize.width;
        }
        adjustLocationModel.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", x]];
    }
    return adjustLocationModel;
}

@end
