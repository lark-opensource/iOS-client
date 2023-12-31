//
//  BDXBridgeDownloadFileMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/4/2.
//

#import "BDXBridgeDownloadFileMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"
#import <BDXBridgeKit/NSString+BDXBridgeAdditions.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTReachability/TTReachability.h>

@implementation BDXBridgeDownloadFileMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeDownloadFileMethod);

- (void)callWithParamModel:(BDXBridgeDownloadFileMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeMediaServiceProtocol> mediaService = bdx_get_service(BDXBridgeMediaServiceProtocol);
    bdx_complete_if_not_implemented(mediaService);

    if (![TTReachability isNetworkConnected]) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNetworkUnreachable message:@"Network is unreachable."]);
        return;
    }
    if (paramModel.url.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The URL should not be empty."]);
        return;
    }
    
    NSString *fileName = [[NSUUID UUID] UUIDString];
    if (paramModel.extension.length > 0) {
        fileName = [fileName stringByAppendingPathExtension:paramModel.extension];
    }
    NSString *tmpFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    
    BDXBridgeDownloadFileCompletionHandler wrappedCompletionHandler = ^(TTHttpResponse *response, NSURL *fileURL, NSError *error) {
        TTHttpResponseChromium *httpResponse = (TTHttpResponseChromium *)response;
        BDXBridgeDownloadFileMethodResultModel *resultModel = nil;
        BDXBridgeStatusCode statusCode = BDXBridgeStatusCodeSucceeded;
        NSString *description = nil;
        if (error) {
            statusCode = BDXBridgeStatusCodeFailed;
            description = error.localizedDescription;
        } else if (![response isKindOfClass:TTHttpResponseChromium.class]) {
            statusCode = BDXBridgeStatusCodeMalformedResponse;
            description = @"The response returned from server is malformed.";
        } else {
            resultModel = [BDXBridgeDownloadFileMethodResultModel new];
            resultModel.httpCode = @(httpResponse.statusCode);
            resultModel.header = [httpResponse.allHeaderFields copy];
            resultModel.filePath = [fileURL.path bdx_stringByStrippingSandboxPath];
        }
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:statusCode message:description];
        bdx_invoke_block(completionHandler, resultModel, status);
    };

    if ([mediaService respondsToSelector:@selector(downloadFileWithParam:completionHandler:)]) {
        BDXBridgeDownloadFileParam *param = [BDXBridgeDownloadFileParam new];
        param.urlString = paramModel.url;
        param.headers = paramModel.header;
        param.params = paramModel.params;
        param.filePath = tmpFilePath;
        [mediaService downloadFileWithParam:param completionHandler:wrappedCompletionHandler];
    } else {
        NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
        [[TTNetworkManager shareInstance] downloadTaskWithRequest:paramModel.url parameters:paramModel.params headerField:paramModel.header needCommonParams:YES progress:nil destination:tmpFileURL completionHandler:^(TTHttpResponse *response, NSURL *fileURL, NSError *error) {
            bdx_invoke_block(wrappedCompletionHandler, response, fileURL, error);
        }];
    }
}

@end
