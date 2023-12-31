//
//  BDUGTokenAnalysisResultTextDialogService.m
//  Article
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGTokenShareAnalysisResultTextDialogService.h"
#import "BDUGDialogBaseView.h"
#import "BDUGTokenShareAnalysisResultCommom.h"
#import "BDUGTokenShareAnalysisContentViewBase.h"
#import <BDUGShare/BDUGTokenShareModel.h>
#import <BDUGShare/BDUGTokenShareDialogManager.h>
#import "BDUGShareEvent.h"
#import "BDUGTokenShareDialogService.h"
#import <ByteDanceKit/UIView+BTDAdditions.h>

#pragma mark - content view

@interface BDUGTokenShareAnalysisResultTextContentView : BDUGTokenShareAnalysisContentViewBase

@end

@implementation BDUGTokenShareAnalysisResultTextContentView

- (void)refreshContent:(BDUGTokenShareAnalysisResultModel *)resultModel {
    self.titleLabel.numberOfLines = 3;
    [super refreshContent:resultModel];
}

- (void)refreshFrame {
    [super refreshFrame];
    self.titleLabel.frame = CGRectMake(self.tipsLabel.btd_left, 0, self.btd_width - 2 * self.tipsLabel.btd_left, CGRectGetMinY(self.tipsLabel.frame) - 16);
    if (self.tipsLabel.isHidden) {
        self.titleLabel.btd_centerY = self.btd_centerY - 14;
    }
}

@end

#pragma mark - BDUGTokenAnalysisResultTextDialogService

@interface BDUGTokenShareAnalysisResultTextDialogService ()

@end

@implementation BDUGTokenShareAnalysisResultTextDialogService

NSString * const kBDUGTokenShareAnalysisResultTextDialogDialogKey = @"kBDUGTokenShareAnalysisResultTextDialogDialogKey";

+ (void)showTokenAnalysisDialog:(BDUGTokenShareAnalysisResultModel *)resultModel
                    buttonColor:(UIColor *)buttonColor
                  actionModel:(BDUGTokenShareServiceActionModel *)actionModel
 {
     void (^hiddenBlock)(BDUGDialogBaseView *) = ^(BDUGDialogBaseView *dialogView){
         [self hiddenDialog:dialogView];
         !actionModel.cancelHandler ?: actionModel.cancelHandler(resultModel);
     };
     NSString *buttonDesc = resultModel.buttonText;
     if (buttonDesc.length == 0) {
         buttonDesc = @"查看";
     }
     BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:buttonDesc buttonColor:buttonColor confirmHandler:^(BDUGDialogBaseView *dialogView) {
        [self hiddenDialog:dialogView];
        !actionModel.actionHandler ?: actionModel.actionHandler(resultModel);
    } cancelHandler:^(BDUGDialogBaseView *dialogView) {
        hiddenBlock(dialogView);
    }];
    BDUGTokenShareAnalysisResultTextContentView *contentView = [[BDUGTokenShareAnalysisResultTextContentView alloc] initWithFrame:CGRectMake(0, 0, 300, 132)];
    [contentView refreshContent:resultModel];
    [baseDialog addDialogContentView:contentView];
     __weak BDUGDialogBaseView *weakBaseDialog = baseDialog;
    contentView.tipTapBlock = ^{
        __strong BDUGDialogBaseView *strongBaseDialog = weakBaseDialog;
        [self hiddenDialog:strongBaseDialog];
        !actionModel.tiptapHandler ?: actionModel.tiptapHandler(resultModel);
    };
    [baseDialog show];
}

+ (void)hiddenDialog:(BDUGDialogBaseView *)dialogView {
    [dialogView hide];
}
@end
