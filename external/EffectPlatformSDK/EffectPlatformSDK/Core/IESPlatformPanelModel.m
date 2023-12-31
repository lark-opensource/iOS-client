//
//  IESPlatformPanelModel.m
//  EffectPlatformSDK
//
//  Created by leizh007 on 2018/3/22.
//

#import "IESPlatformPanelModel.h"

@interface IESPlatformPanelModel () <MTLJSONSerializing>

@property(nonatomic, readwrite, copy) NSString *text;

@property(nonatomic, readwrite, copy) NSArray<NSString *> *iconURLs;

@property(nonatomic, readwrite, copy) NSString *iconURI;

@property(nonatomic, readwrite, copy) NSArray<NSString *> *tags;

@property(nonatomic, readwrite, copy) NSString *tagsUpdatedTimeStamp;

@end

@implementation IESPlatformPanelModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"text" : @"text",
             @"iconURLs" : @"icon.url_list",
             @"iconURI" : @"icon.uri",
             @"tags" : @"tags",
             @"tagsUpdatedTimeStamp" : @"tags_updated_at",
             @"extra": @"extra"
             };
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[IESPlatformPanelModel class]]) {
        return NO;
    }

    IESPlatformPanelModel *panelModel = (IESPlatformPanelModel *)object;

    return [self.text isEqualToString:panelModel.text] &&
    [IESPlatformPanelModel isArray:self.iconURLs equalToArray:panelModel.iconURLs] &&
    [self.iconURI isEqualToString:panelModel.iconURI] &&
    [IESPlatformPanelModel isArray:self.tags equalToArray:panelModel.tags] &&
    [self.tagsUpdatedTimeStamp isEqualToString:panelModel.tagsUpdatedTimeStamp];
}

- (NSUInteger)hash {
    return self.text.hash ^ self.iconURLs.hash ^ self.iconURI.hash ^ self.tags.hash ^ self.tagsUpdatedTimeStamp.hash;
}

+ (BOOL)isArray:(NSArray<NSString *> *)arr1 equalToArray:(NSArray<NSString *> *)arr2 {
    BOOL result = YES;
    for (NSUInteger i = 0; i < MIN(arr1.count, arr2.count); ++i) {
        if (![arr1[i] isEqualToString:arr2[i]]) {
            result = NO;
            break;
        }
    }

    return result;
}

@end
