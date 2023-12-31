//
//  ACCStickerPannelViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "ACCStickerPannelViewModel.h"

@interface ACCStickerPannelViewModel ()

@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, assign) BOOL isStickerHandling;

@property (nonatomic, strong, readwrite) RACSignal *willShowStickerPanelSignal;
@property (nonatomic, strong, readwrite) RACSubject *willShowStickerPanelSubject;
@property (nonatomic, strong, readwrite) RACSignal<ACCStickerSelectionContext *> *didDismissStickerPanelSignal;
@property (nonatomic, strong, readwrite) RACSubject<ACCStickerSelectionContext *> *didDismissStickerPanelSubject;
@property (nonatomic, strong, readwrite) RACSignal *willDismissStickerPanelSignal;
@property (nonatomic, strong, readwrite) RACSubject *willDismissStickerPanelSubject;

@property (nonatomic, assign, readwrite) BOOL stickerPanelShowing;

@end

@implementation ACCStickerPannelViewModel

- (void)dealloc {
    [_didDismissStickerPanelSubject sendCompleted];
    [_willShowStickerPanelSubject sendCompleted];
    [_willDismissStickerPanelSubject sendCompleted];
    [_observers removeAllObjects];
    _observers = nil;
}

#pragma mark - Public APIs

- (void)registObserver:(id<ACCStickerPannelObserver>)observer {
    [self.observers addObject:observer];
}

- (void)willShowStickerPanel {
    [self.willShowStickerPanelSubject sendNext:nil];
}

- (void)willDismissStickerPanel:(ACCStickerSelectionContext *)selectedSticker
{
    [self.willDismissStickerPanelSubject sendNext:selectedSticker];
}

- (void)didDismissStickerPanelWithSelectedSticker:(ACCStickerSelectionContext *)selectedSticker
{
    [self.didDismissStickerPanelSubject sendNext:selectedSticker];
    self.stickerPanelShowing = NO;
}

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName {
    if (self.isStickerHandling) {
        return YES;
    }
    [self.observers sortUsingComparator:^NSComparisonResult(id<ACCStickerPannelObserver>  _Nonnull obj1, id<ACCStickerPannelObserver>  _Nonnull obj2) {
        return obj1.stikerPriority > obj2.stikerPriority;
    }];
    for (id<ACCStickerPannelObserver> observer in self.observers) {
        @weakify(self);
        BOOL canHandel = [observer handleSelectSticker:sticker fromTab:tabName willSelectHandle:^{
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isStickerHandling = NO;
            });
        } dismissPanelHandle:^ (ACCStickerType type, BOOL animated){
            @strongify(self);
            ACCStickerSelectionContext *ctx = [[ACCStickerSelectionContext alloc] init];
            ctx.stickerType = type;
            ctx.stickerModel = sticker;
            !self.dismissPanelBlock ?: self.dismissPanelBlock(ctx, animated);
        }];
        if (canHandel) {
            self.isStickerHandling = YES;
            return YES;
        }
    }
    self.isStickerHandling = NO;
    return NO;
}

- (BOOL)handleSelectThirdPartySticker:(IESThirdPartyStickerModel *)sticker
{
    if (self.isStickerHandling) {
        return YES;
    }
    for (id<ACCStickerPannelObserver> observer in self.observers) {
        @weakify(self);
        BOOL canHandel = NO;
        if ([observer respondsToSelector:@selector(handleThirdPartySelectSticker:willSelectHandle:dismissPanelHandle:)]) {
            canHandel = [observer handleThirdPartySelectSticker:sticker willSelectHandle:^{
                @strongify(self);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isStickerHandling = NO;
                });
            } dismissPanelHandle:^(BOOL animated){
                @strongify(self);
                ACCStickerSelectionContext *ctx = [[ACCStickerSelectionContext alloc] init];
                ctx.stickerType = ACCStickerTypeSearchSticker;
                ctx.thirdPartyModel = sticker;
                !self.dismissPanelBlock ?: self.dismissPanelBlock(ctx, animated);
            }];
        }
        if (canHandel) {
            self.isStickerHandling = YES;
            return YES;
        }
    }
    self.isStickerHandling = NO;
    return NO;
}

#pragma mark - Getters
- (RACSignal<ACCStickerSelectionContext *> *)didDismissStickerPanelSignal
{
    return self.didDismissStickerPanelSubject;
}

- (RACSubject<ACCStickerSelectionContext *> *)didDismissStickerPanelSubject
{
    if (!_didDismissStickerPanelSubject) {
        _didDismissStickerPanelSubject = [RACSubject subject];
    }
    return _didDismissStickerPanelSubject;
}

- (RACSignal *)willDismissStickerPanelSignal
{
    return self.willDismissStickerPanelSubject;
}

- (RACSubject *)willDismissStickerPanelSubject
{
    if (!_willDismissStickerPanelSubject) {
        _willDismissStickerPanelSubject = [RACSubject subject];
    }
    return _willDismissStickerPanelSubject;
}

- (RACSignal *)willShowStickerPanelSignal
{
    return self.willShowStickerPanelSubject;
}

- (RACSubject *)willShowStickerPanelSubject
{
    if (!_willShowStickerPanelSubject) {
        _willShowStickerPanelSubject = [RACSubject subject];
    }
    return _willShowStickerPanelSubject;
}

- (NSMutableArray *)observers {
    if (!_observers) {
        _observers = @[].mutableCopy;
    }
    return _observers;
}

@end
