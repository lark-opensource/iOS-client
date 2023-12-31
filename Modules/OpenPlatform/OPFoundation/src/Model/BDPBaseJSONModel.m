//
//  BDPBasePluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/5.
//

#import "BDPBaseJSONModel.h"

@implementation BDPBaseJSONModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    NSError *initError = nil;
    self = [super initWithDictionary:dict error:&initError];
    if (initError && err) *err = initError;
    return self;
}

@end
