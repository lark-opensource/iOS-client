//
//  ADFGLoadResource.m
//  ADFeelGoodSDK
//
//  Created by bytedance on 2020/8/27.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import "ADFGLoadResource.h"
#import "ADFGCommonMacros.h"

static inline NSBundle * resourceBundle() {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"ADFeelGood" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return bundle;
}

UIImage* _Nullable ADFG_compatImageWithName(NSString * _Nullable imageName) {
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle() compatibleWithTraitCollection:nil];
    return image;
}

void ADFG_async_compatImageWithName(NSString *_Nullable imageName,imageBlock _Nullable block) {
    if (!ADFGCheckValidString(imageName)) {
        !block?:block(nil);
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = ADFG_compatImageWithName(imageName);
            dispatch_async(dispatch_get_main_queue(), ^{
                !block?:block(image);
            });
        });
    }
}
