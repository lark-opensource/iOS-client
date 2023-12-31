//
//  BDXNavigationBarProvider.m
//  BDXContainer
//
//  Created by tianbaideng on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "BDXNavigationBarProvider.h"
#import <BDXServiceCenter/BDXSchemaParam.h>
#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import "BDXNavigationBar.h"
#import "BDXPageSchemaParam.h"
#import "BDXViewController.h"
#import "UIImage+BDXContainer.h"


@interface BDXDefaultNavigationBar()

@property (nonatomic, weak) BDXPageSchemaParam *param;

@end

@implementation BDXDefaultNavigationBar

- (void)attachToContainerWithParams:(BDXSchemaParam<BDXPageSchemaParamProtocol> *)schemaParam
{
    if (![self.container isKindOfClass:BDXViewController.class]) {
        return;
    }

    if (![schemaParam isKindOfClass:BDXPageSchemaParam.class]) {
        return;
    }

    BDXPageSchemaParam *param = (BDXPageSchemaParam*)schemaParam;
    self.param = param;

    [self setLeftButtonImage:[UIImage page_imageNamed:@"icon_navibar_back"]];
    if(!param.navBarColor){
        self.backgroundColor = UIColor.whiteColor;
    } else{
        self.backgroundColor = param.navBarColor;
    }
    self.title = param.title;
    self.titleColor = param.titleColor;

    if (param.navigationButtonType == BDXNavigationButtonTypeReport) {
        self.rightButtonImage = [UIImage page_imageNamed:@"icon_navibar_report"];
    } else if (param.navigationButtonType == BDXNavigationButtonTypeShare) {
        self.rightButtonImage = [UIImage page_imageNamed:@"icon_navibar_share"];
    } else if (param.showMoreButton) {
        self.rightButtonImage = [UIImage page_imageNamed:@"icon_navibar_more"];
    }

    self.closeNaviButton.hidden = YES;
    self.closeButtonImage = [UIImage page_imageNamed:@"icon_navibar_close"];

    @weakify(self);
    [self setLeftButtonActionBlock:^(BDXNavigationBar *_Nonnull navigationBar) {
        @strongify(self);
        if (self.container.navigationController.viewControllers.count > 1) {
            [self.container.navigationController popViewControllerAnimated:YES];
        } else {
            [self.container dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [self setCloseButtonActionBlock:^(BDXNavigationBar *_Nonnull navigationBar) {
        @strongify(self);
        if (self.container.navigationController.viewControllers.count > 1) {
            [self.container.navigationController popViewControllerAnimated:NO];
        } else {
            [self.container dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [self setRightButtonActionBlock:^(BDXNavigationBar *_Nonnull navigationBar) {
        @strongify(self);
        [self onRightButtonClicked:navigationBar];
    }];
}

- (void)onRightButtonClicked:(id)sender
{
    if (self.param.showMoreButton) {
        [self __showMorePanel];
    } else if (self.param.navigationButtonType == BDXNavigationButtonTypeReport) {
        [self onReportButtonClicked:sender];
    } else if (self.param.navigationButtonType == BDXNavigationButtonTypeShare) {
        [self onShareButtonClicked:sender];
    }
}

- (void)onReportButtonClicked:(id)sender
{
    void(^reportHandle)(id sender) = [self.container.context getObjForKey:kBDXContextKeyNavBarReportHandle];
    
    if(reportHandle){
        reportHandle(sender);
    }
}

- (void)onShareButtonClicked:(id)sender
{
    void(^shareHandle)(id sender) = [self.container.context getObjForKey:kBDXContextKeyNavBarShareHandle];

    if(shareHandle){
        shareHandle(sender);
    }
}

- (void)updateTitle:(NSString *)title
{
    self.title = title;
}

- (void)__showMorePanel
{
    UIAlertController *moreController = [UIAlertController alertControllerWithTitle:nil message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
    if (self.param.copyLinkAction) {
        [moreController addAction:[UIAlertAction
                                   actionWithTitle:@"mus_live_copy_link" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * _Nonnull action) { UIPasteboard
            *generalPasterboard = [UIPasteboard generalPasteboard];
            [generalPasterboard
             setString:self.container.originURL.absoluteString];
        }]];
    }
    
    [moreController addAction:[UIAlertAction actionWithTitle:@"cancel"
                                                       style:UIAlertActionStyleCancel handler:nil]];
    
    [self.container presentViewController:moreController animated:YES completion:nil];
}

- (void)handleReloadButton:(id)sender
{
    [self.container reloadWithContext:self.container.context];
}

@end

