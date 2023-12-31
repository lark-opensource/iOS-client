//
//  BDUGTokenShareDialogService.m
//  Article
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGTokenShareDialogService.h"
#import "BDUGTokenShareDialogManager.h"
#import "BDUGTokenSharePreviewDialog.h"
#import "BDUGDialogBaseView.h"
#import "BDUGTokenShareAnalysisResultCommom.h"
#import "BDUGTokenShareAnalysisResultTextDialogService.h"
#import "BDUGTokenShareAnalysisResultTextAndImageDialogService.h"
#import "BDUGTokenShareAnalysisResultVideoDialogService.h"
#import <ByteDanceKit/BTDResponder.h>
#import "BDUGShareEvent.h"

#pragma mark - BDUGTokenShareDialogService

@implementation BDUGTokenShareServiceActionModel

@end

@interface BDUGTokenShareDialogService ()

@end

static BDUGTokenShareServiceActionModel *staticActionModel;
static UIColor *staticThemeColor;

@implementation BDUGTokenShareDialogService

+ (void)registerService
{
    [self registerServiceWithNotificationName:nil];
}

+ (void)registerServiceWithNotificationName:(NSString *)notificationName
{
    [BDUGTokenShareDialogManager tokenShareRegisterDialogBlock:^(BDUGTokenShareInfo *tokenModel) {
        [BDUGTokenShareDialogService showTokenDialog:tokenModel];
    }];
    [BDUGTokenShareDialogManager tokenAnalysisRegisterDialogBlock:^(BDUGTokenShareAnalysisResultModel *resultModel) {
        [BDUGTokenShareDialogService showTokenAnalysisDialog:resultModel];
    } notificationName:notificationName];
}

+ (void)registerTokenShareWithActionModel:(BDUGTokenShareServiceActionModel *)actionModel
{
    staticActionModel = actionModel;
}

+ (void)configThemeColor:(UIColor *)themeColor
{
    staticThemeColor = themeColor;
}

+ (void)showTokenDialog:(BDUGTokenShareInfo *)tokenModel {
    BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:@"去粘贴" buttonColor:staticThemeColor confirmHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        [BDUGTokenShareDialogManager shareToken:tokenModel];
    } cancelHandler:^(BDUGDialogBaseView *dialogView) {
        [dialogView hide];
        [BDUGTokenShareDialogManager cancelTokenShare:tokenModel];
    }];
    BDUGTokenSharePreviewDialog *contentView = [[BDUGTokenSharePreviewDialog alloc] initWithFrame:CGRectMake(0, 0, 300, 132)];
    [contentView refreshContent:tokenModel];
    [baseDialog addDialogContentView:contentView];
    [baseDialog show];
}

+ (void)showTokenAnalysisDialog:(BDUGTokenShareAnalysisResultModel *)resultModel {
    if (!resultModel) {
        [self.class showInvalidAlert];
        return ;
    }
    BDUGTokenShareDialogType type = resultModel.mediaType;
    
    BDUGTokenShareServiceActionModel *resultActionModel = [[BDUGTokenShareServiceActionModel alloc] init];
    resultActionModel.showHander = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
        !staticActionModel.showHander ?: staticActionModel.showHander(resultModel);
        //识别弹窗展示埋点。
        [BDUGShareEventManager event:kShareRecognizePopupShow params:@{
            @"show_from" : @"token",
            @"media_type" : @(type),
        }];
    };
    resultActionModel.actionHandler = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
        !staticActionModel.actionHandler ?: staticActionModel.actionHandler(resultModel);
        [BDUGShareEventManager event:kShareRecognizePopupClick params:@{
            @"show_from" : @"token",
            @"media_type" : @(type),
            @"click_result" : @"submit",
        }];
    };
    resultActionModel.cancelHandler = ^(BDUGTokenShareAnalysisResultModel *resultModel) {
        !staticActionModel.cancelHandler ?: staticActionModel.cancelHandler(resultModel);
        [BDUGShareEventManager event:kShareRecognizePopupClick params:@{
            @"show_from" : @"token",
            @"media_type" : @(type),
            @"click_result" : @"close",
        }];
    };
    resultActionModel.tiptapHandler = staticActionModel.tiptapHandler;
           
    switch (type) {
        default:
        case BDUGTokenShareDialogTypeText:
        {
            [BDUGTokenShareAnalysisResultTextDialogService showTokenAnalysisDialog:resultModel buttonColor:staticThemeColor actionModel:resultActionModel];
            !resultActionModel.showHander ?: resultActionModel.showHander(resultModel);
        }
            break;
        case BDUGTokenShareDialogTypeTextAndImage:
        case BDUGTokenShareDialogTypePhotos:
        case BDUGTokenShareDialogTypeAudio:
        {
            [BDUGTokenShareAnalysisResultTextAndImageDialogService showTokenAnalysisDialog:resultModel buttonColor:staticThemeColor actionModel:resultActionModel];
            !resultActionModel.showHander ?: resultActionModel.showHander(resultModel);
        }
            break;
        case BDUGTokenShareDialogTypeVideo:
        case BDUGTokenShareDialogTypeShortVideo:
        {
            [BDUGTokenShareAnalysisResultVideoDialogService showTokenAnalysisDialog:resultModel buttonColor:staticThemeColor actionModel:resultActionModel];
            !resultActionModel.showHander ?: resultActionModel.showHander(resultModel);
        }
            break;
    }
}

+ (void)showInvalidAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"口令已失效" message:@"看看别的内容吧" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
    [[BTDResponder topViewController] presentViewController:alert animated:YES completion:nil];
}

@end
