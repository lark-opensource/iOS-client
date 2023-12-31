//
//  ACCSpeedControlComponentQuickAlbumPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/2.
//

#import "ACCSpeedControlComponentQuickAlbumPlugin.h"
#import "ACCSpeedControlComponent.h"
#import "ACCSpeedControlViewModel.h"
#import "ACCQuickAlbumViewModel.h"

@implementation ACCSpeedControlComponentQuickAlbumPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCSpeedControlComponent class];
}

- (void)bindToComponent:(ACCSpeedControlComponent *)component
{
    ACCSpeedControlViewModel *viewModel = [component getViewModel:[ACCSpeedControlViewModel class]];
    @weakify(component);
    [viewModel addShouldShowPrediacte:^BOOL{
        @strongify(component);
        if (!component) {
            return NO;
        }
        
        ACCQuickAlbumViewModel *quickViewModel = [component getViewModel:[ACCQuickAlbumViewModel class]];
        return !quickViewModel.isQuickAlbumShow ||
        ![quickViewModel currentRecordModeCanShow]; // 后边这个判断不知道啥意思...测试时再看
    } forHost:self];
    
    ACCQuickAlbumViewModel *quickAlbumViewModel = [component getViewModel:[ACCQuickAlbumViewModel class]];
    [quickAlbumViewModel.quickAlbumShowStateSignal subscribeNext:^(id  _Nullable x) {
        @strongify(component);
        [component showSpeedControlIfNeeded];
    }];
}

@end
