//
//  ACCPropPickerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/10.
//

#import "ACCPropPickerViewModel.h"

NSString *const ACCPropPickerHotTab = @"hot";
NSString *const ACCPropPickerFavorTab = @"favor";

@interface ACCPropPickerViewModel ()

@property (nonatomic, strong) RACSubject<NSString *> *showPanelSubject;
@property (nonatomic, strong) RACSubject<IESEffectModel *> *exposePanelPropSelectionSubject;
@property (nonatomic, strong) RACSubject<NSArray<IESEffectModel *> *> *sendFavoriteEffectsSubject;

@end

@implementation ACCPropPickerViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showPanelSubject = [RACSubject subject];
        _exposePanelPropSelectionSubject = [RACSubject subject];
        _sendFavoriteEffectsSubject = [RACSubject subject];
    }
    return self;
}

- (void)dealloc
{
    [_showPanelSubject sendCompleted];
    [_exposePanelPropSelectionSubject sendCompleted];
    [_sendFavoriteEffectsSubject sendCompleted];
}

- (RACSignal<NSString *> *)showPanelSignal
{
    return self.showPanelSubject;
}

- (RACSignal<IESEffectModel *> *)exposePanelPropSelectionSignal
{
    return self.exposePanelPropSelectionSubject;
}

- (RACSignal<NSArray<IESEffectModel *> *> *)sendFavoriteEffectsSignal
{
    return self.sendFavoriteEffectsSubject;
}

#pragma mark - public

- (void)showPanelFromTab:(NSString *)tab
{
    [self.showPanelSubject sendNext:tab];
}

- (void)selectPropFromExposePanel:(IESEffectModel *)prop
{
    [self.exposePanelPropSelectionSubject sendNext:prop];
}

- (void)sendFavoriteEffectsForRecognitionPanel:(NSArray<IESEffectModel *> *)favoriteEffects
{
    [self.sendFavoriteEffectsSubject sendNext:favoriteEffects];
}

@end
