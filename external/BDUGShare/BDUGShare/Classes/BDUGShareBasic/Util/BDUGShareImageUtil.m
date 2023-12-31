//
//  BDUGShareImageUtil.m
//  BDUGShare
//
//  Created by muhuai on 18/01/02.
//
//

#import "BDUGShareImageUtil.h"

@implementation BDUGShareImageUtil

+ (void)downloadImageDataWithURL:(NSURL *)url limitLength:(NSUInteger)limitLength completion:(void (^)(NSData *, NSError *))completion {
    if (!url) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]);
        }
        return;
    }
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        UIImage *image = [UIImage imageWithData:data];
        NSData *compressedData = [self compressImage:image withLimitLength:limitLength];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(compressedData, error);
            }
        });
    }] resume];
}

+ (NSData *)compressImage:(UIImage *)image withLimitLength:(NSUInteger)limitLength {
    if (![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    
    NSData *originImageData = UIImageJPEGRepresentation(image, 1.0);
    if (originImageData.length > limitLength) {
        //压缩图片
        CGFloat compression = 0.9f;
        CGFloat maxCompression = 0.1f;
        NSData *compressImageData = originImageData;
        
        while (compressImageData.length > limitLength && compression > maxCompression)
        {
            compression -= 0.1;
            compressImageData = UIImageJPEGRepresentation(image, compression);
        }
        
        if (compressImageData.length <= limitLength) {
            return compressImageData;
        }
        //缩小图片尺寸
        CGSize originImageSize = image.size;
        CGSize targetImageSize = CGSizeZero;
        if (originImageSize.width > originImageSize.height) {
            targetImageSize.width = 114.0;
            targetImageSize.height = 114.0/originImageSize.width * originImageSize.height;
        }else {
            targetImageSize.height = 114.0;
            targetImageSize.width = 114.0/originImageSize.height * originImageSize.width;
        }
        return [self drawNewImage:image withSize:targetImageSize];
        
    }else {
        return originImageData;
    }
}

+ (NSData *)drawNewImage:(UIImage *)image withSize:(CGSize)size {
    UIImage * targetImage = nil;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    targetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImageJPEGRepresentation(targetImage, 1.0);
}

@end
