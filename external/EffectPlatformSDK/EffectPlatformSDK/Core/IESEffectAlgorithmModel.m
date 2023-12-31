//
//  IESEffectAlgorithmModel.m
//  AFNetworking
//
//  Created by nanxiang liu on 2019/1/27.
//

#import "IESEffectAlgorithmModel.h"
#import "IESEffectDecryptUtil.h"

@interface IESEffectAlgorithmModel ()
@property (nonatomic, copy) NSString *nameSec;
@end

@implementation IESEffectAlgorithmModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"name":@"name",
             @"nameSec":@"name_sec",
             @"version":@"version",
             @"modelMD5":@"file_url.uri",
             @"fileDownloadURLs":@"file_url.url_list",
             @"sizeType":@"type"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
        if (self.nameSec) {
            self.name = [IESEffectDecryptUtil decryptString:self.nameSec];
        }
    }
    return self;
}

@end
