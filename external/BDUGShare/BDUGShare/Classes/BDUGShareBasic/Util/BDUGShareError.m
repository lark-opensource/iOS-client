//
//  BDUGShareError.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/6/4.
//

#import "BDUGShareError.h"

@implementation BDUGShareError

+ (NSError *)errorWithDomain:(NSString *)domain
                        code:(BDUGShareErrorType)type
                    userInfo:(NSDictionary *)userInfo
{
    NSString *desc = @"";
    switch (type) {
        case BDUGShareErrorTypeAppNotInstalled:
            desc = @"App is not installed";
            break;
        case BDUGShareErrorTypeAppNotSupportAPI:
            desc = @"App SDK does not support API";
            break;
        case BDUGShareErrorTypeAppNotSupportShareType:
            desc = @"Not supported share type for this App";
            break;
        case BDUGShareErrorTypeInvalidContent:
            desc = @"Invalid content";
            break;
        case BDUGShareErrorTypeNoTitle:
            desc = @"There is no title";
            break;
        case BDUGShareErrorTypeNoWebPageURL:
            desc = @"There is no url";
            break;
        case BDUGShareErrorTypeNoImage:
            desc = @"There is no image";
            break;
        case BDUGShareErrorTypeNoVideo:
            desc = @"There is no video";
            break;
        case BDUGShareErrorTypeUserCancel:
            desc = @"User canceled this action";
            break;
        case BDUGShareErrorTypeNoValidItemInPanel:
            desc = @"There isn't a valid panel";
            break;
        case BDUGShareErrorTypeExceedMaxVideoSize:
            desc = @"Video excced max size.";
            break;
        case BDUGShareErrorTypeExceedMaxImageSize:
            desc = @"(Image/Preview image) excced max size.";
            break;
        case BDUGShareErrorTypeExceedMaxTitleSize:
            desc = @"Title excced max size.";
            break;
        case BDUGShareErrorTypeExceedMaxDescSize:
            desc = @"Description excced max size.";
            break;
        case BDUGShareErrorTypeExceedMaxWebPageURLSize:
            desc = @"Web page URL excced max size.";
            break;
        case BDUGShareErrorTypeExceedMaxFileSize:
            desc = @"File excced max size.";
            break;
        case BDUGShareErrorTypeSendRequestFail:
            desc = @"Failed when sending request";
            break;
        case BDUGShareErrorTypeOther:
            desc = @"Something bad happened";
            break;
        default:
            break;
    }
    if (!userInfo || userInfo.allKeys.count == 0) {
        userInfo = @{NSLocalizedDescriptionKey: desc};
    }
    return [NSError errorWithDomain:domain code:type userInfo:userInfo];
}

@end
