//
//  ACCQuickStoryRecorderTipsViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/19.
//

#import "ACCQuickStoryRecorderTipsViewModel.h"

@interface ACCQuickStoryRecorderTipsViewModel ()

@property (nonatomic, copy) NSString *showingTips;
@property (nonatomic, copy) NSNumber *showingTipsToken;
@property (nonatomic, strong) RACSubject *switchLengthViewShowIfNeededSubject;
@property (nonatomic, strong, readwrite) RACSignal *switchLengthViewShowIfNeededSignal;

@end

@implementation ACCQuickStoryRecorderTipsViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (NSNumber *)showRecordHintLabel:(NSString *)text exclusive:(BOOL)exclusive
{
    if (exclusive) {
        self.showingTips = text;
        return self.showingTipsToken;
    } else {
        return [self showRecordHintLabel:text];
    }
}

- (NSNumber *)showRecordHintLabel:(NSString *)text
{
    if (self.showingTips != nil) {
        return nil;
    }
    self.showingTips = text;
    return self.showingTipsToken;
}

- (void)setShowingTips:(NSString *)showingTips
{
    _showingTips = showingTips;
    if (_showingTips != nil) {
        _showingTipsToken = @(arc4random());
    } else {
        _showingTipsToken = nil;
    }
}

- (void)hideRecordHintLabelWithToken:(NSNumber *)token
{
    if ([_showingTipsToken isEqual:token]) {
        self.showingTips = nil;
    }
}

- (void)hideRecordHintLabel
{
    self.showingTips = nil;
}

- (void)shouldShowSwitchLengthView:(BOOL)show
{
    [self.switchLengthViewShowIfNeededSubject sendNext:@(show)];
}

- (void)dealloc
{
    [self.switchLengthViewShowIfNeededSubject sendCompleted];
}

- (RACSubject *)switchLengthViewShowIfNeededSubject
{
    if (!_switchLengthViewShowIfNeededSubject) {
        _switchLengthViewShowIfNeededSubject = [RACSubject subject];
    }
    return _switchLengthViewShowIfNeededSubject;
}

- (RACSignal *)switchLengthViewShowIfNeededSignal
{
    return self.switchLengthViewShowIfNeededSubject;
}

@end
