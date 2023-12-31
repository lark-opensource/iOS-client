//
//  ACCRecorderStickerServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import "ACCRecorderStickerServiceImpl.h"
#import "ACCRecorderStickerCompoundHandler.h"
#import "AWERepoStickerModel.h"

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#pragma mark - UIView Category

@interface UIView (ACCRecordLayoutManager)

@property (nonatomic, assign) BOOL acc_recordLayoutForbidHiding;

@end

@implementation UIView (ACCRecordLayoutManager)

- (BOOL)acc_recordLayoutForbidHiding
{
    return [objc_getAssociatedObject(self, @"acc_recordLayoutForbidHiding") boolValue];
}

- (void)setAcc_recordLayoutForbidHiding:(BOOL)acc_recordLayoutForbidHiding
{
    objc_setAssociatedObject(self, @"acc_recordLayoutForbidHiding", [NSNumber numberWithBool:acc_recordLayoutForbidHiding], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - ACCRecorderStickerServiceImpl

@interface ACCRecorderStickerServiceImpl ()

@property (nonatomic, weak, readwrite) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, strong, readwrite) ACCStickerCompoundHandler *compoundHandler;
@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *repository;

@end

@implementation ACCRecorderStickerServiceImpl

@synthesize containerInteracting;

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
{
    self = [super init];
    if (self) {
        self.repository = repository;
    }
    return self;
}

#pragma mark - ACCRecorderStickerServiceProtocol Methods

- (void)registerStickerHandler:(nonnull ACCStickerHandler *)handler
{
    [self.compoundHandler addHandler:handler];
}

- (void)addRecorderInteractionStickerInfoToArray:(NSMutableArray *)recorderInteractionStickers idx:(NSInteger)stickerIndex
{
    // 复用编辑页的compoundHandler的方法，但是传入不同的array，之后在调用处存入recorderInteractionStickers中
    [self.compoundHandler addInteractionStickerInfoToArray:recorderInteractionStickers idx:stickerIndex];
}

- (void)toggleForbitHidingStickerContainerView:(BOOL)shouldForbid
{
    self.stickerContainerView.acc_recordLayoutForbidHiding = shouldForbid;
}

- (void)toggleStickerContainerViewHidden:(BOOL)shouldHide
{
    if (shouldHide) {
        if (!self.stickerContainerView.acc_recordLayoutForbidHiding) {
            [self.stickerContainerView acc_fadeHidden];
        }
    } else {
        [self.stickerContainerView acc_fadeShow];
    }
}

- (void)recoverStickers
{
    for (AWEInteractionStickerModel *interactionSticker in self.repository.repoSticker.recorderInteractionStickers) {
        ACCRecoverStickerModel *model = [[ACCRecoverStickerModel alloc] init];
        model.interactionSticker = interactionSticker;
        [self.compoundHandler recoverSticker:model];
    }
}

- (void)updateStickerContainer
{
    [self.compoundHandler.handlers enumerateObjectsUsingBlock:^(ACCStickerHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.stickerContainerView = self.stickerContainerView;
    }];
}

#pragma mark - Getters and Setters

- (ACCStickerContainerView *)stickerContainerView
{
    if (!_stickerContainerView) {
        _stickerContainerView = ACCBLOCK_INVOKE(self.getStickerContainerViewBlock);
    }
    return _stickerContainerView;
}

- (ACCStickerCompoundHandler *)compoundHandler
{
    if (!_compoundHandler) {
        _compoundHandler = [ACCRecorderStickerCompoundHandler compoundHandler];
    }
    return _compoundHandler;
}

@end
