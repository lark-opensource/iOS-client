//
//  AWEExploreStickerViewController.m
//  Indexer
//
//  Created by wanghongyu on 2021/9/6.
//

#import "AWEExploreStickerViewController.h"
#import <CameraClient/ACCLynxView.h>
#import <CameraClient/ACCAPPSettingsProtocol.h>
#import <CameraClient/ACCXBridgeTemplateProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCLynxDefaultPackage.h"
#import "ACCLynxDefaultPackageTemplate.h"

@interface AWEExploreStickerViewController () 

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) ACCLynxView *lynxView;

@end

@implementation AWEExploreStickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    self.lynxView = [[ACCLynxView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.lynxView];

    ACCMasMaker(self.lynxView, {
        make.edges.equalTo(self.view);
    });

    NSURL *url = [NSURL URLWithString:[ACCAPPSettings() stickerExploreScheme]];
    NSArray *bridges = [IESAutoInline(self.serviceProvider, ACCXBridgeTemplateProtocol) xBridgeRecorderTemplate:self.serviceProvider];
    id <ACCLynxViewConfigProtocol> config = IESAutoInline(self.serviceProvider, ACCLynxViewConfigProtocol);
    [self.lynxView loadURL:url
                 withProps:nil
                  xbridges:bridges
                    config:config];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
   return UIStatusBarStyleLightContent;
}

@end
