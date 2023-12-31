//
//  CJPayBridgePlugin_downloadFile.m
//  Pods
//
//  Created by 易培淮 on 2021/10/13.
//

#import "CJPayBridgePlugin_downloadFile.h"
#import "NSDictionary+CJPay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"
#import "CJPayBridgeAuthManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "UIViewController+CJPay.h"

@implementation CJPayBridgePlugin_downloadFile

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_downloadFile, downloadFile),
                            @"ttcjpay.downloadFile");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)downloadFileWithParam:(NSDictionary *)param
                   callback:(TTBridgeCallback)callback
                     engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller
{
    NSString *fileUrl = [param cj_stringValueForKey:@"download_url"];
    NSString *fileName = [param cj_stringValueForKey:@"file_name"];
    if (!([fileUrl isKindOfClass:NSString.class] && [fileUrl length] > 0)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"url参数错误")
        return;
    }
    if (![self p_allowDownload:[NSURL URLWithString:fileUrl]]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"非法url")
        return;
    }
    if (!([fileName isKindOfClass:NSString.class] && [fileName length] > 0)) {
        fileName = [fileUrl componentsSeparatedByString:@"/"].lastObject;
    }
    NSURL *targetFilePath = [[NSURL alloc] initFileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) btd_objectAtIndex:0] stringByAppendingPathComponent:fileName]];
    [[NSFileManager defaultManager] removeItemAtURL:targetFilePath error:nil];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    [[TTNetworkManager shareInstance] downloadTaskWithRequest:fileUrl
                                              parameters:nil
                                             headerField:nil
                                         needCommonParams:NO
                                                progress:nil
                                              destination:targetFilePath
                                               autoResume:YES
                                            completionHandler:^(TTHttpResponse *response, NSURL *filePath, NSError *error){
        [[CJPayLoadingManager defaultService] stopLoading];
        if (error) {
            callback(TTBridgeMsgSuccess, @{@"code": @(1)}, nil);
            return;
        } else {
            [self p_share:[[NSArray alloc] initWithObjects:filePath, nil] callBack:^{
                [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
            }];
            callback(TTBridgeMsgSuccess, @{@"code": @(0)}, nil);
            return;
        }
    }];
}

- (void)p_share:(NSArray *)items callBack:(void(^)(void))callBack {
    if (0 == items.count) {
        return;
    }
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    if (@available(iOS 11.0, *)) {
        activityVC.excludedActivityTypes = @[UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks, UIActivityTypeMarkupAsPDF];
    }else {
        activityVC.excludedActivityTypes = @[UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks];
    }
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (activityType == nil && !completed) { //UIActivityViewController close
            CJ_CALL_BLOCK(callBack);
        }
    };
    __block UIViewController *vc = [UIViewController cj_topViewController];
    if (CJ_Pad || [[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            activityVC.popoverPresentationController.sourceView = vc.view;
            activityVC.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(vc.view.bounds), vc.view.cj_top, 0, 0);
            activityVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
            [vc presentViewController:activityVC animated:YES completion:nil];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc presentViewController:activityVC animated:YES completion:nil];
        });
    }
}

- (BOOL)p_allowDownload:(NSURL *)url {
    return [[[CJPayBridgeAuthManager shared] allowedDomainsForSDK] btd_contains:^BOOL(NSString * _Nonnull obj) {
        return [url.host hasSuffix:obj];
    }];
}

@end
