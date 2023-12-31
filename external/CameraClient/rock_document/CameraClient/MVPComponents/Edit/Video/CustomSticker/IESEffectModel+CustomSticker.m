//
//  IESEffectModel+CustomSticker.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/12/18.
//

#import "IESEffectModel+CustomSticker.h"
#import <EffectPlatformSDK/IESEffectModel.h>
#import <objc/runtime.h>

@implementation IESEffectModel (CustomSticker)

- (AWECustomStickerLimitConfig *)limitConfig
{
    AWECustomStickerLimitConfig *model = objc_getAssociatedObject(self, @selector(limitConfig));
    if(!model) {
        if (self.extra == nil) {
            return nil;
        }
        NSData *jsonData = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        if(!jsonData) {
            return nil;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        if(err || ![dict isKindOfClass:NSDictionary.class]) {
            return nil;
        }
        model = [MTLJSONAdapter modelOfClass:AWECustomStickerLimitConfig.class fromJSONDictionary:dict error:&err];
        if(err || !model) {
            return nil;
        }
        objc_setAssociatedObject(self, @selector(limitConfig), model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return model;
}

@end

