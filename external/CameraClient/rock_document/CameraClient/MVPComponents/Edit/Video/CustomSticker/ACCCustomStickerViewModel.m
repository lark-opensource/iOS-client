//
//  ACCCustomStickerViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "ACCCustomStickerViewModel.h"
#import "ACCAddInfoStickerContext.h"

@interface ACCCustomStickerViewModel ()
@property (nonatomic, strong, readwrite) RACSignal *addCustomStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *addCustomStickerSubject;
@end

@implementation ACCCustomStickerViewModel

#pragma mark - Public APIs

- (void)addCustomSticker:(IESEffectModel *)sticker path:(NSString *)path tabName:(NSString *)tabName completion:(void (^)(void))completion
{
    ACCAddInfoStickerContext *context = [[ACCAddInfoStickerContext alloc] init];
    context.stickerModel = sticker;
    context.path = path;
    context.tabName = tabName;
    context.source = ACCInfoStickerSourceCustom;
    context.completion = completion;
    [self.addCustomStickerSubject sendNext:context];
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [_addCustomStickerSubject sendCompleted];
}

#pragma mark - Getters

- (RACSignal *)addCustomStickerSignal
{
    return self.addCustomStickerSubject;
}

- (RACSubject *)addCustomStickerSubject
{
    if (!_addCustomStickerSubject) {
        _addCustomStickerSubject = [[RACSubject alloc] init];
    }
    return _addCustomStickerSubject;
}

@end
