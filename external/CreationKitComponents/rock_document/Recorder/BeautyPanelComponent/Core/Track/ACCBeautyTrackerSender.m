//
//  ACCBeautyTrackerSender.m
//  CameraClient
//
//  Created by xiangpeng on 2021/3/15.
//

#import "ACCBeautyTrackerSender.h"

@interface ACCBeautyTrackerSender ()

@property (nonatomic, strong, readwrite) RACSubject *beautySwitchButtonClickedSignal;
@property (nonatomic, strong, readwrite) RACSubject *modernBeautyButtonClickedSignal;
@property (nonatomic, strong, readwrite) RACSubject *flowServiceDidCompleteRecordSignal;
@property (nonatomic, strong, readwrite) RACSubject *composerBeautyViewControllerDidSwitchSignal;

@end

@implementation ACCBeautyTrackerSender

-(void)sendBeautySwitchButtonClickedSignal:(BOOL)isOn
{
    [self.beautySwitchButtonClickedSignal sendNext:@(isOn)];
}

-(void)sendModernBeautyButtonClickedSignal
{
    [self.modernBeautyButtonClickedSignal sendNext:nil];
}

- (void)sendFlowServiceDidCompleteRecordSignal
{
    [self.flowServiceDidCompleteRecordSignal sendNext:nil];
}

- (void)sendComposerBeautyViewControllerDidSwitchSignal:(BOOL)isOn isManually:(BOOL)isManually
{
    [self.composerBeautyViewControllerDidSwitchSignal sendNext:RACTuplePack(@(isOn), @(isManually))];
}

#pragma mark - Getter

-(RACSubject *)beautySwitchButtonClickedSignal
{
    if(!_beautySwitchButtonClickedSignal){
        _beautySwitchButtonClickedSignal = [self createSubject];
    }
    return _beautySwitchButtonClickedSignal;
}

-(RACSubject *)modernBeautyButtonClickedSignal
{
    if(!_modernBeautyButtonClickedSignal){
        _modernBeautyButtonClickedSignal = [self createSubject];
    }
    return _modernBeautyButtonClickedSignal;
}

-(RACSubject *)flowServiceDidCompleteRecordSignal
{
    if(!_flowServiceDidCompleteRecordSignal){
        _flowServiceDidCompleteRecordSignal = [self createSubject];
    }
    return _flowServiceDidCompleteRecordSignal;
}

- (RACSubject *)composerBeautyViewControllerDidSwitchSignal
{
    if (!_composerBeautyViewControllerDidSwitchSignal) {
        _composerBeautyViewControllerDidSwitchSignal = [self createSubject];
    }
    return _composerBeautyViewControllerDidSwitchSignal;
}

- (AWEVideoPublishViewModel *)publishModel {
    return self.getPublishModelBlock ? self.getPublishModelBlock() : nil;
}

@synthesize publishModel = _publishModel;

@end
