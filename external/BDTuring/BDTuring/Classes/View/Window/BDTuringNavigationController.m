//
//  BDTuringNavigationController.m
//  BDTuring
//
//  Created by bob on 2020/6/16.
//

#import "BDTuringNavigationController.h"
#import "BDTuringUIHelper.h"

@interface BDTuringNavigationController ()

@end

@implementation BDTuringNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    BDTuringUIHelper *helper = [BDTuringUIHelper sharedInstance];
    if (helper.turingForbidLandscape || !helper.supportLandscape) {
        return UIInterfaceOrientationMaskPortrait;
    }

    return [super supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    BDTuringUIHelper *helper = [BDTuringUIHelper sharedInstance];
    if (helper.turingForbidLandscape || !helper.supportLandscape) {
        return UIInterfaceOrientationPortrait;
    }
    
    return [super preferredInterfaceOrientationForPresentation];
}

@end
