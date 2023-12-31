//
//  ACCRecorderShootSameStickerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "AWERepoStickerModel.h"
#import "ACCRecorderShootSameStickerViewModel.h"

#import "ACCShootSameStickerHandlerFactory.h"
#import "ACCRecorderStickerDefines.h"
#import "ACCRecordViewControllerInputData.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCRecorderShootSameStickerViewModel ()

@property (nonatomic, strong) NSMutableArray<UIView<ACCStickerProtocol> *> *addedStickerViews;

@end

@implementation ACCRecorderShootSameStickerViewModel

@synthesize handlers;
@synthesize onSelectTimeCallback;
@synthesize configDelegation;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.handlers = [NSMutableDictionary dictionary];
        self.addedStickerViews = [NSMutableArray array];
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
            [self.stickerService registerStickerHandler:handler];
            self.handlers[@(shootSameStickerModel.stickerType)] = handler;
        }
    }
}

- (void)createStickerViews
{
    for (ACCShootSameStickerModel *shootSameStickerModel in self.inputData.publishModel.repoSticker.shootSameStickerModels) {
        if (shootSameStickerModel.isDeleted) {
            continue;;
        }
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        if ([UIDevice acc_isIPad] && shootSameStickerModel.stickerType == 4) {//commnet sticker
            if (shootSameStickerModel.tempLocationModel != NULL) {
                shootSameStickerModel.locationModel = [shootSameStickerModel.tempLocationModel copy];
                shootSameStickerModel.tempLocationModel = NULL;
            }
        }
        UIView<ACCStickerProtocol> * stickerView = [handler createStickerViewWithShootSameStickerModel:shootSameStickerModel
                                                                                          isInRecorder:YES];
        stickerView.contentView.alpha = kRecorderShootSameStickerViewAlpha;
        [self.addedStickerViews addObject:stickerView];
    }
}

- (void)updateShootSameStickerModel
{
    for (ACCShootSameStickerModel *shootSameStickerModel in self.inputData.publishModel.repoSticker.shootSameStickerModels) {
        ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *handler = self.handlers[@(shootSameStickerModel.stickerType)];
        [handler updateLocationModelWithShootSameStickerModel:shootSameStickerModel];
    }
}

@end
