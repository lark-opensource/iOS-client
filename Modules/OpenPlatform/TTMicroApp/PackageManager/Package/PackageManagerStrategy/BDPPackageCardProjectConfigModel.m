//
//  BDPPackageCardProjectConfigModel.m
//  Timor
//
//  Created by houjihu on 2020/5/25.
//

#import "BDPPackageCardProjectConfigModel.h"
#import <TTMicroApp/TTMicroApp-Swift.h>

@implementation BDPPackageCardConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *map = @{@"cardid": NSStringFromSelector(@selector(cardID))
                          };
    return [[JSONKeyMapper alloc] initWithDictionary:map];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation BDPPackageCardProjectConfigModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    if (self = [super initWithDictionary:dict error:err]) {
        self.appType = BDPTypeNativeCard;
    }
    return self;
}

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *map = @{@"appid": NSStringFromSelector(@selector(appID)),
                          @"cards": NSStringFromSelector(@selector(cardConfigs))
                          };
    return [[JSONKeyMapper alloc] initWithDictionary:map];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    if ([propertyName isEqualToString:NSStringFromSelector(@selector(appType))]) {
        return YES;
    }
    return NO;
}

@end
