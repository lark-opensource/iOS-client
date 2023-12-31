//
//  BDPVideoViewModel.m
//  Timor
//
//  Created by CsoWhy on 2019/1/11.
//

#import "BDPVideoViewModel.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation BDPVideoViewModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{@"encryptToken":@"encrypt_token"}];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
//        [self transferHttpsToHttp];
        if (![_objectFit isEqualToString:@"contain"] && ![_objectFit isEqualToString:@"fill"] && ![_objectFit isEqualToString:@"cover"]) {
            _objectFit = @"contain";
        }
        if (![_playBtnPosition isEqualToString:@"bottom"] && ![_playBtnPosition isEqualToString:@"center"]) {
            _playBtnPosition = @"bottom";
        }
    }
    return self;
}

- (void)transferHttpsToHttp
{
    if ([self.filePath hasPrefix:@"https://"]) {
        self.filePath = [self.filePath stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
    }
}

@end
