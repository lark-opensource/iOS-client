//
//  BDCTAdditions+VideoRecord.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/1/3.
//

#import "BDCTAdditions+VideoRecord.h"


@implementation UIImage (BDCTVideoRecordAdditions)

+ (UIImage *)bdct_videoRecordimageWithName:(NSString *)name {
    if (!name.length) {
        return nil;
    }
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"byted_cert_video_record.bundle"]] ?: [NSBundle bdct_bundle];
    });
    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end
