//
//  AWECloudCommandNetDiagnoseUpSpeed.m
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECloudCommandNetDiagnoseUpSpeed.h"
#import "AWECloudCommandNetworkUtility.h"

@implementation AWECloudCommandNetDiagnoseUpSpeed

- (void)startUpSpeedTestWithCompletion:(AWECloudCommandNetDiagnoseUpSpeedCompletion)completion
{
    NSString *path = [NSString stringWithFormat:@"%@/aweme/v1/upload/image/", @"https://aweme.snssdk.com"];
    UIImage *image = [self.class _generateImageOfSize:CGSizeMake(1024, 1024)];
    NSData *data = UIImagePNGRepresentation(image);
    NSTimeInterval st = [[NSDate date] timeIntervalSince1970];
    [AWECloudCommandNetworkUtility uploadDataWithUrl:path
                                            fileName:@"speed_test_file"
                                                data:data
                                              params:nil
                                            mimeType:@"image/png"
                                      requestHeaders:nil
                                             success:^(id responseObject, NSData *data, NSString *ran) {
                                                 if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                                     NSDictionary *dict = (NSDictionary *)responseObject;
                                                     NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - st;
                                                     CGFloat speed = data.length / duration / 1024.f;
                                                     NSArray *urlArray = [[dict valueForKey:@"data"] valueForKey:@"url_list"];
                                                     if (completion) {
                                                         completion(speed, nil, [urlArray firstObject]);
                                                     }
                                                 } else {
                                                     if (completion) {
                                                         completion(0, nil, nil);
                                                     }
                                                 }
                                             }
                                             failure:^(NSError *error) {
                                                 if (completion) {
                                                     completion(0, error, nil);
                                                 }
                                             }];
}

+ (UIImage *)_generateImageOfSize:(CGSize)size
{
    UIImage *image = nil;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextDrawPath(context, kCGPathFill);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
