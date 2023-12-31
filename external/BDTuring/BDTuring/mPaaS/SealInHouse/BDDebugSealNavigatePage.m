//
//  BDDebugSealNavigatePage.m
//  BDTuring
//
//  Created by bob on 2020/6/2.
//

#import "BDDebugSealNavigatePage.h"

@interface BDDebugSealNavigatePage ()

@end

@implementation BDDebugSealNavigatePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.text = @"业务自定义的用户协议和用户规范页面";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
}

@end
