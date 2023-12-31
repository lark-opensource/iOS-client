//
//  ACCMVTemplateInfo.m
//  CameraClient-Pods-Aweme
//
// Created by Li Hui on April 16, 2020
//

#import "ACCMVTemplateInfo.h"

#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@implementation ACCMVTemplateInfo

+ (ACCMVTemplateInfo *)MVTemplateInfoFromEffect:(IESEffectModel *)effect coverURLPrefixs:(NSArray<NSString *> *)coverURLPrefixs
{
    ACCMVTemplateInfo *templateInfo = [[ACCMVTemplateInfo alloc] init];
    NSArray<NSString *> *urlPrefixs = coverURLPrefixs;
    NSData *jsonData = [effect.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            NSString *templateVideoCover = [jsonObject acc_stringValueForKey:@"template_video_cover"];
            NSString *templatePictureCover = [jsonObject acc_stringValueForKey:@"template_picture_cover"];
            NSInteger templateMinMaterial = [jsonObject acc_integerValueForKey:@"template_min_material"];
            NSInteger templateMaxMaterial = [jsonObject acc_integerValueForKey:@"template_max_material"];
            NSInteger templatePicInputWidth = [jsonObject acc_integerValueForKey:@"template_pic_input_width"];
            NSInteger templatePicInputHeight = [jsonObject acc_integerValueForKey:@"template_pic_input_height"];
            NSString *templatePicFillMode = [jsonObject acc_stringValueForKey:@"template_pic_fill_mode"];
            NSInteger templateType = [jsonObject acc_integerValueForKey:@"template_type"];

            if (urlPrefixs) {
                if (templateVideoCover) {
                    NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:urlPrefixs.count];
                    for (NSString *prefix in urlPrefixs) {
                        NSString *url = [prefix stringByAppendingString:templateVideoCover];
                        if (url) {
                            [urls addObject:url];
                        }
                    }
                    templateInfo.videoCoverURLs = urls;
                }
                if (templatePictureCover) {
                    NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:urlPrefixs.count];
                    for (NSString *prefix in urlPrefixs) {
                        NSString *url = [prefix stringByAppendingString:templatePictureCover];
                        if (url) {
                            [urls addObject:url];
                        }
                    }
                    templateInfo.photoCoverURLs = urls;
                }
            }

            templateInfo.minMaterial = templateMinMaterial;
            templateInfo.maxMaterial = templateMaxMaterial;
            templateInfo.photoInputWidth = templatePicInputWidth;
            templateInfo.photoInputHeight = templatePicInputHeight;
            templateInfo.photoFillMode = templatePicFillMode;
            templateInfo.templateType = templateType;
            return templateInfo;
        }
    }
    return templateInfo;
}

@end
