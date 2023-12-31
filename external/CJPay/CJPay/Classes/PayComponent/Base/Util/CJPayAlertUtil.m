//
//  CJPayAlertUtil.m
//  CJPay
//
//  Created by 尚怀军 on 2020/10/21.
//

#import "CJPayAlertUtil.h"
#import "CJPayAlertController.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"

@implementation CJPayAlertUtil

+ (UIViewController *)singleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
                  buttonDesc:(NSString *)buttonDesc
                 actionBlock:(nullable void (^)(void))actionBlock
                       useVC:(UIViewController *)useVC{
    return [self singleAlertWithTitle:title
                       content:content
                    buttonDesc:buttonDesc
                   actionBlock:actionBlock
              styleWithMessage:@""
                         useVC:useVC];
}

+ (UIViewController *)singleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
                  buttonDesc:(NSString *)buttonDesc
                 actionBlock:(nullable void (^)(void))actionBlock
            styleWithMessage:(NSString *)msg
                       useVC:(UIViewController *)useVC{
    return [self doubleAlertWithTitle:title
                       content:content
                leftButtonDesc:buttonDesc
               rightButtonDesc:nil
               leftActionBlock:actionBlock
               rightActioBlock:nil
              styleWithMessage:msg
                         useVC:useVC];
}

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
                       useVC:(UIViewController *)useVC {
    return [self doubleAlertWithTitle:title
                       content:content
                leftButtonDesc:leftButtonDesc
               rightButtonDesc:rightButtonDesc
               leftActionBlock:leftActionBlock
               rightActioBlock:rightActioBlock
              styleWithMessage:@""
                         useVC:useVC];
}

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
              cancelPosition:(CJPayAlertBoldPosition)position
                       useVC:(UIViewController *)useVC{
    CJPayLogAssert(Check_ValidString(leftButtonDesc) || Check_ValidString(rightButtonDesc), @"button desc must be nonnull!");
    
    CJPayAlertController *alertController = [CJPayAlertController alertControllerWithTitle:title
                                                                                   message:content
                                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alertController applyBindCardMessageStyleWithMessage:@""];
    
    UIAlertAction *leftAction = [UIAlertAction actionWithTitle:leftButtonDesc
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        CJ_CALL_BLOCK(leftActionBlock);
    }];
    [alertController addAction:leftAction];
    if(position == CJPayAlertBoldlLeft) {
        alertController.preferredAction = leftAction;
    }
    
    UIAlertAction *rightAction = [UIAlertAction actionWithTitle:rightButtonDesc
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        CJ_CALL_BLOCK(rightActioBlock);
    }];
    [alertController addAction:rightAction];
    if(position == CJPayAlertBoldRight) {
        alertController.preferredAction = rightAction;
    }
    
    [alertController showUse:useVC];
    return alertController;
}

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
            styleWithMessage:(NSString *)msg
                       useVC:(UIViewController *)useVC{
    
    CJPayLogAssert(Check_ValidString(leftButtonDesc) || Check_ValidString(rightButtonDesc), @"button desc must be nonnull!");
    
    CJPayAlertController *alertController = [CJPayAlertController alertControllerWithTitle:title
                                                                                   message:content
                                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alertController applyBindCardMessageStyleWithMessage:msg];
    
    if (Check_ValidString(leftButtonDesc)) {
        UIAlertAction *leftAction = [UIAlertAction actionWithTitle:leftButtonDesc
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            CJ_CALL_BLOCK(leftActionBlock);
        }];
        [alertController addAction:leftAction];
    }
    
    if (Check_ValidString(rightButtonDesc)) {
        UIAlertAction *rightAction = [UIAlertAction actionWithTitle:rightButtonDesc
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            CJ_CALL_BLOCK(rightActioBlock);
        }];
        [alertController addAction:rightAction];
    }
    
    [alertController showUse:useVC];
    return alertController;
}

+ (UIViewController *)customSingleAlertWithTitle:(NSString *)title
                           content:(NSString *)content
                        buttonDesc:(NSString *)buttonDesc
                       actionBlock:(nullable void (^)(void))actionBlock
                             useVC:(UIViewController *)useVC {
    CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    if (model && model.showNewAlertType) {
        CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
        model.type = CJPayTextPopUpTypeDefault;
        model.title = title;
        model.content = content;
        model.mainOperation = buttonDesc;
        
        CJPayDyTextPopUpViewController *popUpVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model];
        @CJWeakify(popUpVC)
        model.didClickMainOperationBlock = ^{
            @CJStrongify(popUpVC)
            [popUpVC dismissSelfWithCompletionBlock:actionBlock];
        };
        [self p_presentCustomAlertVC:popUpVC fromVC:useVC];
        return popUpVC;
    } else {
       return [self singleAlertWithTitle:title content:content buttonDesc:buttonDesc actionBlock:actionBlock useVC:useVC];
    }
}

+ (UIViewController *)customDoubleAlertWithTitle:(NSString *)title
                           content:(NSString *)content
                    leftButtonDesc:(NSString *)leftButtonDesc
                   rightButtonDesc:(NSString *)rightButtonDesc
                   leftActionBlock:(nullable void (^)(void))leftActionBlock
                   rightActioBlock:(nullable void (^)(void))rightActioBlock
                             useVC:(UIViewController *)useVC {
    CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    if ((model && model.showNewAlertType)) {
        CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
        model.type = CJPayTextPopUpTypeHorizontal;
        model.title = title;
        model.content = content;
        model.mainOperation = rightButtonDesc;
        model.secondOperation = leftButtonDesc;
        model.didClickMainOperationBlock = rightActioBlock;
        model.didClickSecondOperationBlock = leftActionBlock;
        
        CJPayDyTextPopUpViewController *popUpVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model];
        @CJWeakify(popUpVC)
        model.didClickMainOperationBlock = ^{
            @CJStrongify(popUpVC)
            [popUpVC dismissSelfWithCompletionBlock:rightActioBlock];
        };
        model.didClickSecondOperationBlock = ^{
            @CJStrongify(popUpVC)
            [popUpVC dismissSelfWithCompletionBlock:leftActionBlock];
        };
        [self p_presentCustomAlertVC:popUpVC fromVC:useVC];
        return popUpVC;
    } else {
        return [self doubleAlertWithTitle:title content:content leftButtonDesc:leftButtonDesc rightButtonDesc:rightButtonDesc leftActionBlock:leftActionBlock rightActioBlock:rightActioBlock useVC:useVC];
    }
}

+ (void)p_presentCustomAlertVC:(CJPayBaseViewController *)alertVC fromVC:(UIViewController *)fromVC {
    
    if (!alertVC || !fromVC || ![alertVC isKindOfClass:CJPayBaseViewController.class] || ![fromVC isKindOfClass:UIViewController.class]) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:fromVC];
    if (![alertVC isKindOfClass:UIAlertController.class] &&
        !CJ_Pad &&
        topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:alertVC animated:YES];
    } else {
        [(CJPayBaseViewController *)alertVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
    }
}

@end
