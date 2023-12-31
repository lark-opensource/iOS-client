//
//  BDTuringViewController.m
//  BDTuring
//
//  Created by bob on 2020/3/2.
//

#import "BDTuringViewController.h"
#import "BDTuringUIHelper.h"

@interface BDTuringViewController ()

@end

@implementation BDTuringViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [BDTuringUIHelper sharedInstance].showNavigationBarWhenDisappear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    BDTuringUIHelper *helper = [BDTuringUIHelper sharedInstance];
    if (helper.showNavigationBarWhenDisappear && !helper.isShowAlert) {
        self.navigationController.navigationBarHidden = NO;
    }
}

@end
