//
//  ACCSelfieImageProcessAndUploadService.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/9/9.
//

#import <CreativeKit/ACCMacros.h>
#import <TTReachability/TTReachability.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <IESFoundation/NSDictionary+AWEAdditions.h>
#import "ACCSelfieImageProcessAndUploadService.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@interface ACCSelfieImageProcessAndUploadService()

@end

@implementation ACCSelfieImageProcessAndUploadService

- (void)uploadImage:(UIImage *)image andVerfyWithCompletion:(void(^)(NSError *error, ACCUploadFaceResultType type))completion {
    if (!image) {
        return;
    }
    if (![TTReachability isNetworkConnected]) {
        [ACCToast() show:@"无法生成，请检查网络情况"];
        return;
    }
    UIImage *resizedImg = [self resizeImage:image withNewSize:CGSizeMake(300, 300)];
    NSString *URLStr = [NSString stringWithFormat:@"%@/aweme/v1/upload/image/", [ACCNetService() defaultDomain]];
    [ACCNetService() uploadWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.urlString = URLStr;
        requestModel.needCommonParams = YES;
        requestModel.timeout = 60;
        requestModel.bodyBlock = ^(id<TTMultipartFormData> formData) {
            [formData appendPartWithFileData:UIImageJPEGRepresentation(resizedImg, 0.6) name:@"file" fileName:@"file" mimeType:@"image/jpeg"];
        };
    } progress:nil completion:^(id  _Nullable model, NSError * _Nullable error) {
        NSDictionary *info = ACCDynamicCast(model, NSDictionary);
        NSDictionary *data = [info awe_dictionaryValueForKey:@"data"];
        NSString *uri = [data awe_stringValueForKey:@"uri"];
        if (error || uri.length == 0) {
            ACCBLOCK_INVOKE(completion, error, ACCUploadFaceResultTypeUploadFailed);
        } else {
            NSDictionary *parma = @{@"uri": uri.length > 0 ? uri : @""};
            [ACCNetService() POST:[NSString stringWithFormat:@"%@/aweme/v1/im/resources/xmoji/upload/face_image/", [ACCNetService() defaultDomain]] params:parma modelClass:nil completion:^(id  _Nullable model, NSError * _Nullable error) {
                NSDictionary *serverDataDict = ACCDynamicCast(model, NSDictionary);
                if (!error) {
                    BOOL reviewFaild = [serverDataDict acc_boolValueForKey:@"is_ilegal"];
                    if (reviewFaild) {
                        ACCBLOCK_INVOKE(completion, error, ACCUploadFaceResultTypeReviewFailed);
                    } else {
                        ACCBLOCK_INVOKE(completion, error, ACCUploadFaceResultTypeReviewSuccess);
                    }
                } else {
                    ACCBLOCK_INVOKE(completion, error, ACCUploadFaceResultTypeReviewFailed);
                }
            }];
        }
    }];
}


- (UIImage *)resizeImage:(UIImage *)image withNewSize:(CGSize)targetSize {
    if (!image) {
        return nil;
    }
    CGSize size = CGSizeMake(image.size.width, image.size.height);
    CGFloat heightRatio = size.height / targetSize.height;
    CGFloat widthRatio = size.width / targetSize.width;
    if (widthRatio > 1.0 && widthRatio < heightRatio) {
        size = CGSizeMake(image.size.width / widthRatio, image.size.height / widthRatio);
    } else if (heightRatio > 1.0 && widthRatio > heightRatio){
        size = CGSizeMake(image.size.width / heightRatio, image.size.height / heightRatio);
    }
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end


