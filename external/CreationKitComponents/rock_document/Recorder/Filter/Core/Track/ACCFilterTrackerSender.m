//
//  ACCFilterTrackerSender.m
//  CameraClient
//
//  Created by haoyipeng on 2021/3/5.
//

#import "ACCFilterTrackerSender.h"
#import <EffectPlatformSDK/IESCategoryModel.h>

@interface ACCFilterTrackerSender ()

@property (nonatomic, strong, readwrite) RACSubject *filterViewWillShowSignal;
// currentFilter
@property (nonatomic, strong, readwrite) RACSubject<IESEffectModel *> *filterViewWillDisappearSignal;
// switch to filter
@property (nonatomic, strong, readwrite) RACSubject<IESEffectModel *> *filterSlideSwitchCompleteSignal;
@property (nonatomic, strong, readwrite) RACSubject *filterSlideSwitchStartSignal;

// manually click category or filter
@property (nonatomic, strong, readwrite) RACSubject<IESCategoryModel *> *filterViewDidClickCategorySignal;
@property (nonatomic, strong, readwrite) RACSubject<IESEffectModel *> *filterViewDidClickFilterSignal;

@end

@implementation ACCFilterTrackerSender

- (void)dealloc
{
    [self.filterViewWillShowSignal sendCompleted];
    [self.filterViewWillDisappearSignal sendCompleted];
    [self.filterSlideSwitchCompleteSignal sendCompleted];
    [self.filterSlideSwitchStartSignal sendCompleted];
    [self.filterViewDidClickCategorySignal sendCompleted];
    [self.filterViewDidClickFilterSignal sendCompleted];
}

- (void)sendFilterViewWillShowSignal
{
    [self.filterViewWillShowSignal sendNext:nil];
}

- (void)sendFilterViewWillDisappearSignalWithFilter:(IESEffectModel *)filter
{
    [self.filterViewWillDisappearSignal sendNext:filter];
}

- (void)sendFilterSlideSwitchCompleteSignal:(IESEffectModel *)filter
{
    [self.filterSlideSwitchCompleteSignal sendNext:filter];
}

- (void)sendFilterSlideSwitchStartSignal
{
    [self.filterSlideSwitchStartSignal sendNext:nil];
}

- (void)sendFilterViewDidClickCategorySignal:(IESCategoryModel *)category
{
    [self.filterViewDidClickCategorySignal sendNext:category];
}

- (void)sendFilterViewDidClickFilterSignal:(IESEffectModel *)filter
{
    [self.filterViewDidClickFilterSignal sendNext:filter];
}

#pragma mark - Getter

- (RACSubject *)filterSlideSwitchCompleteSignal
{
    if (!_filterSlideSwitchCompleteSignal) {
        _filterSlideSwitchCompleteSignal = [self createSubject];
    }
    return _filterSlideSwitchCompleteSignal;
}

- (RACSubject *)filterSlideSwitchStartSignal
{
    if (!_filterSlideSwitchStartSignal) {
        _filterSlideSwitchStartSignal = [self createSubject];
    }
    return _filterSlideSwitchStartSignal;
}

- (RACSubject *)filterViewWillDisappearSignal
{
    if (!_filterViewWillDisappearSignal) {
        _filterViewWillDisappearSignal = [self createSubject];
    }
    return _filterViewWillDisappearSignal;
}

- (RACSubject *)filterViewWillShowSignal
{
    if (!_filterViewWillShowSignal) {
        _filterViewWillShowSignal = [self createSubject];
    }
    return _filterViewWillShowSignal;
}

- (RACSubject *)filterViewDidClickCategorySignal
{
    if (!_filterViewDidClickCategorySignal) {
        _filterViewDidClickCategorySignal = [[RACSubject alloc] init];
    }
    return _filterViewDidClickCategorySignal;
}

- (RACSubject *)filterViewDidClickFilterSignal
{
    if (!_filterViewDidClickFilterSignal) {
        _filterViewDidClickFilterSignal = [[RACSubject alloc] init];
    }
    return _filterViewDidClickFilterSignal;
}

- (AWEVideoPublishViewModel *)publishModel {
    return self.getPublishModelBlock ? self.getPublishModelBlock() : nil;
}

@synthesize publishModel = _publishModel;

@end
