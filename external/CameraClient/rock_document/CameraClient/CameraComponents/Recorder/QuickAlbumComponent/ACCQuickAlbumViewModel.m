//
//  ACCQuickAlbumViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/8 18:03.
//	Copyright © 2020 Bytedance. All rights reserved.
	

#import "ACCQuickAlbumViewModel.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>

@interface ACCQuickAlbumViewModel()

@property (nonatomic, strong) RACSubject *quickAlbumShowOrHideSubject;
@property (nonatomic, strong) RACSubject *quickAlbumShowStateSubject;

@property (nonatomic, strong, readwrite) RACSignal *quickAlbumShowOrHideSignal;
@property (nonatomic, strong, readwrite) RACSignal *quickAlbumShowStateSignal;

@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@end

@implementation ACCQuickAlbumViewModel

IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

- (void)dealloc
{
    [self.quickAlbumShowStateSubject sendCompleted];
    [self.quickAlbumShowOrHideSubject sendCompleted];
}

- (void)quickAlbumShowStateChange:(BOOL)isShow
{
    [self.quickAlbumShowStateSubject sendNext:@(isShow)];
}

- (void)showOrHideQuickAlbum:(BOOL)show
{
    [self showOrHideQuickAlbum:show isBlank:NO];
}

- (void)showOrHideQuickAlbum:(BOOL)show isBlank:(BOOL)isBlank
{
    [self.quickAlbumShowOrHideSubject sendNext:RACTuplePack(@(show),@(isBlank))];
}

#pragma mark - Get/Set
- (RACSubject *)quickAlbumShowOrHideSubject
{
    if (!_quickAlbumShowOrHideSubject) {
        _quickAlbumShowOrHideSubject = [RACSubject subject];
    }
    return _quickAlbumShowOrHideSubject;
}

- (RACSubject *)quickAlbumShowStateSubject
{
    if (!_quickAlbumShowStateSubject) {
        _quickAlbumShowStateSubject = [RACSubject subject];
    }
    return _quickAlbumShowStateSubject;
}

- (RACSignal *)quickAlbumShowStateSignal
{
    return self.quickAlbumShowStateSubject;
}

- (RACSignal *)quickAlbumShowOrHideSignal
{
    return self.quickAlbumShowOrHideSubject;
}

- (void)setIsQuickAlbumShow:(BOOL)isQuickAlbumShow
{
    if (_isQuickAlbumShow != isQuickAlbumShow) {
        _isQuickAlbumShow = isQuickAlbumShow;
        [self quickAlbumShowStateChange:isQuickAlbumShow];
    }
}

- (BOOL)currentRecordModeCanShow
{
    NSInteger mode = self.switchModeService.currentRecordMode.modeId;
    return ACCRecordModeStory == mode
    || [self.switchModeService isInSegmentMode]
    || ACCRecordModeTakePicture == mode;
}

@end
