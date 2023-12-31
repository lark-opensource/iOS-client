//
//  FileTabViewController.m
//  KAFileDemo
//
//  Created by Supeng on 2021/12/14.
//

#import "FileTabViewController.h"
@import Masonry;
@import KATabInterface;
@import KAFileInterface;
#import "DemoEnv.h"

@interface FileTabViewController ()

@end

@implementation FileTabViewController

- (void)viewDidAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton* button = [[UIButton alloc] init];
    [button setTitle:@"点击打开Memory.test文件" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor grayColor]];
    [button addTarget:self action:@selector(previewButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    [[self view] addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo([self view]);
    }];
}

- (void)previewButtonDidClick {
    NSString* mainBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
    NSString* demoBundlePath = [mainBundlePath stringByAppendingPathComponent:@"KADemoAssemble.bundle"];
    NSBundle* demoBundle = [NSBundle bundleWithPath:demoBundlePath];
    NSString* filePath = [demoBundle pathForResource:@"Memory" ofType:@"test"];

    id<FilePreviewer> resultPreviewer = nil;
    NSArray* allFilePreviewers = [DemoEnv allFilePreviewers];
    for (id previewer in allFilePreviewers) {
        id<FilePreviewer> p = (id<FilePreviewer>) previewer;
        if ([p canPreviewFileName:@"Memory.test"]) {
            resultPreviewer = p;
            break;;
        }
    }
    if(resultPreviewer != nil) {
        [[self navigationController] pushViewController:[resultPreviewer previewFilePath:filePath] animated:true];
    }
}

+(KATabConfig*)filePreviewerTabConfig {
    return [[KATabConfig alloc] initWithTabKey:@"FileTab"
                             tabViewController:^UIViewController *{
        UINavigationController* navi = [[UINavigationController alloc] initWithRootViewController:[[FileTabViewController alloc] init]];
        navi.hidesBottomBarWhenPushed = true;
        return navi;
    }
                                       tabName:@"FileTab"
                                       tabIcon:[UIImage systemImageNamed:@"paperplane"]
                              testSelectedIcon:[UIImage systemImageNamed:@"paperplane.fill"]
                                  quickTabIcon:[UIImage systemImageNamed:@"lasso"]
                                tabSingleClick:^void { NSLog(@"单击"); }
                                tabDoubleClick:^void { NSLog(@"双击"); }
                                   showNaviBar:true
                                  naviBarTitle:@"File Previewer Demo"
                            firstNaviBarButton:nil
                           secondNaviBarButton:nil];

}

@end
