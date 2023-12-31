//
//  ACCMomentDebugLogConsoleViewController.m
//  Pods
//
//  Created by Pinka on 2020/6/18.
//

#if INHOUSE_TARGET

#import "ACCMomentDebugLogConsoleViewController.h"

@interface ACCMomentDebugLogConsoleViewController ()

@property (nonatomic, strong) UITextView *logTextView;

@end

@implementation ACCMomentDebugLogConsoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.logTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.logTextView.editable = NO;
    self.logTextView.text = self.logText;
    [self.view addSubview:self.logTextView];
}

- (BOOL)btd_prefersNavigationBarHidden
{
    return NO;
}

@end

#endif
