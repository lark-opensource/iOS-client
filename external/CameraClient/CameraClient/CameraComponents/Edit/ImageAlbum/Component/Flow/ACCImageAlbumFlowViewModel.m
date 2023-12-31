//
//  ACCImageAlbumFlowViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/15.
//

#import "ACCImageAlbumFlowViewModel.h"

@interface ACCImageAlbumFlowViewModel ()

@property (nonatomic, assign) BOOL isSwitchModeBubbleAllowed;


@end

@implementation ACCImageAlbumFlowViewModel

#pragma mark - Public

- (void)updateIsSwitchModeBubbleAllowed:(BOOL)allowed
{
    self.isSwitchModeBubbleAllowed = allowed;
}

@end
