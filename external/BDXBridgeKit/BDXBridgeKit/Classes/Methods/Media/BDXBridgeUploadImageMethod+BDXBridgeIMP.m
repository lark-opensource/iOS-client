//
//  BDXBridgeUploadImageMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/28.
//

#import "BDXBridgeUploadImageMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"
#import "NSString+BDXBridgeAdditions.h"
#import "NSData+BDXBridgeAdditions.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTReachability/TTReachability.h>
#import <TTNetworkManager/TTNetworkManager.h>

@implementation BDXBridgeUploadImageMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeUploadImageMethod);

- (void)callWithParamModel:(BDXBridgeUploadImageMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
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
    if (paramModel.filePath.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The file path should not be empty."]);
        return;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:[paramModel.filePath bdx_stringByAppendingSandboxPath]];
    NSString *fileName = [paramModel.filePath lastPathComponent];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:fileURL.path]) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotFound message:@"The specified file does not found."]);
        return;
    }
    
    BDXBridgeUploadImageCompletionHandler wrappedCompletionHandler = ^(id object, NSError *error) {
        BDXBridgeStatusCode statusCode = BDXBridgeStatusCodeSucceeded;
        BDXBridgeUploadImageMethodResultModel *resultModel = nil;
        NSString *description = nil;
        if (error) {
            statusCode = BDXBridgeStatusCodeFailed;
            description = error.localizedDescription;
        } else if (![object isKindOfClass:NSDictionary.class]) {
            statusCode = BDXBridgeStatusCodeMalformedResponse;
            description = @"The response returned from server is malformed.";
        } else {
            resultModel = [BDXBridgeUploadImageMethodResultModel new];
            NSDictionary *data = [object btd_dictionaryValueForKey:@"data"];
            resultModel.response = object;
            resultModel.url = [[data btd_arrayValueForKey:@"url_list"] firstObject];
            resultModel.uri = [data btd_stringValueForKey:@"uri"];
        }
        bdx_invoke_block(completionHandler, resultModel, [BDXBridgeStatus statusWithStatusCode:statusCode message:description]);
    };
    
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    NSString *mimeType = paramModel.mimeType ?: [fileData bdx_mimeType];
    if ([mediaService respondsToSelector:@selector(uploadImageWithParam:completionHandler:)]) {
        BDXBridgeUploadImageParam *param = [BDXBridgeUploadImageParam new];
        param.urlString = paramModel.url;
        param.headers = paramModel.header;
        param.params = paramModel.params;
        param.mimeType = mimeType;
        param.fileName = fileName;
        param.fileData = fileData;
        [mediaService uploadImageWithParam:param completionHandler:wrappedCompletionHandler];
    } else {
        bdx_alog_info(@"Use default implementation of '%@' with TTNetworkManager.", self.methodName);
        [TTNetworkManager.shareInstance uploadWithURL:paramModel.url headerField:paramModel.header parameters:paramModel.params constructingBodyWithBlock:^(id<TTMultipartFormData> formData) {
            [formData appendPartWithFileData:fileData name:@"file" fileName:fileName mimeType:mimeType];
        } progress:nil needcommonParams:YES callback:^(NSError *error, id jsonObj) {
            bdx_invoke_block(wrappedCompletionHandler, jsonObj, error);
        }];
    }
}

@end
