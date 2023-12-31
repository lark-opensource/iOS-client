//
//  ACCEditVideoFilterTrackerSender.m
//  CameraClient
//
//  Created by xiangpeng on 2021/3/15.
//

#import "ACCEditVideoFilterTrackerSender.h"

@interface ACCEditVideoFilterTrackerSender ()

@property (nonatomic, strong, readwrite) RACSubject *filterClickedSignal;
@property (nonatomic, strong, readwrite) RACSubject<IESEffectModel *> *filterSwitchManagerCompleteSignal;
@property (nonatomic, strong, readwrite) RACSubject<IESEffectModel *> *tabFilterControllerWillDismissSignal;

@end

@implementation ACCEditVideoFilterTrackerSender

-(void)sendFilterClickedSignal
{
    [self.filterClickedSignal sendNext:nil];
}

- (void)sendFilterSwitchManagerCompleteSignalWithFilter:(IESEffectModel *)filter
{
    [self.filterSwitchManagerCompleteSignal sendNext:filter];
}

- (void)sendTabFilterControllerWillDismissSignalWithSelectedFilter:(IESEffectModel *)filter
{
    [self.tabFilterControllerWillDismissSignal sendNext:filter];
}

#pragma mark - Getter

-(RACSubject *)filterClickedSignal
{
    if(!_filterClickedSignal){
        _filterClickedSignal = [self createSubject];
    }
    return _filterClickedSignal;
}

-(RACSubject *)filterSwitchManagerCompleteSignal
{
    if(!_filterSwitchManagerCompleteSignal){
        _filterSwitchManagerCompleteSignal = [self createSubject];
    }
    return _filterSwitchManagerCompleteSignal;
}

-(RACSubject *)tabFilterControllerWillDismissSignal
{
    if(!_tabFilterControllerWillDismissSignal){
        _tabFilterControllerWillDismissSignal = [self createSubject];
    }
    return _tabFilterControllerWillDismissSignal;
}

@end
