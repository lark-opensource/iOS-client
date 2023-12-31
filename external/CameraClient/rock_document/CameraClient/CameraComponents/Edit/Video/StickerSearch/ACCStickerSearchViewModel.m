//
//  ACCStickerSearchViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/18.
//

#import "ACCStickerSearchViewModel.h"
#import "ACCAddInfoStickerContext.h"
#import <EffectPlatformSDK/IESInfoStickerModel.h>

@interface ACCStickerSearchViewModel()

@property (nonatomic, strong, readwrite) RACSignal *addSearchedStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *addSearchedStickerSubject;

@property (nonatomic, strong, readwrite) RACSignal *configPannelStatusSignal;
@property (nonatomic, strong, readwrite) RACSubject *configPannelStatusSubject;

@end

@implementation ACCStickerSearchViewModel

#pragma mark - Life Cycle
- (void)dealloc
{
    [self.addSearchedStickerSubject sendCompleted];
    [self.configPannelStatusSubject sendCompleted];
}

- (void)addSearchSticker:(IESInfoStickerModel *)sticker path:(NSString *)path completion:(nullable void(^)(void))completionBlock
{
    ACCAddInfoStickerContext *context = [[ACCAddInfoStickerContext alloc] init];
    context.tabName = @"search";
    context.path = path;
    context.completion = completionBlock;
    if (sticker.dataSource == IESInfoStickerModelSourceLoki) {
        context.source = ACCInfoStickerSourceLoki;
        context.stickerModel = sticker.effectModel;
    } else if (sticker.dataSource == IESInfoStickerModelSourceThirdParty) {
        context.source = ACCInfoStickerSourceThirdParty;
        context.thirdPartyModel = sticker.thirdPartyStickerModel;
    }
    [self.addSearchedStickerSubject sendNext:context];
}

- (void)configPannlStatus:(BOOL)show
{
    [self.configPannelStatusSubject sendNext:@(show)];
}

#pragma mark - Getters
- (RACSignal *)addSearchedStickerSignal
{
    return self.addSearchedStickerSubject;
}

- (RACSubject *)addSearchedStickerSubject
{
    if (!_addSearchedStickerSubject) {
        _addSearchedStickerSubject = [[RACSubject alloc] init];
    }
    return _addSearchedStickerSubject;
}

- (RACSignal *)configPannelStatusSignal
{
    return self.configPannelStatusSubject;
}

- (RACSubject *)configPannelStatusSubject
{
    if (!_configPannelStatusSubject) {
        _configPannelStatusSubject = [[RACSubject alloc] init];
    }
    return _configPannelStatusSubject;
}

@end
