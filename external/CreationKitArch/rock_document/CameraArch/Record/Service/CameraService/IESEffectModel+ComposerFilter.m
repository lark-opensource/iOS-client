//
//  IESEffectModel+ComposerFilter.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/11.
//

#import "IESEffectModel+ComposerFilter.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <objc/message.h>

NSString *const kLeftSlidePosition = @"leftSlidePosition";
NSString *const kRightSlidePosition = @"rightSlidePosition";

@implementation IESEffectModel (ComposerFilter)

- (nullable ACCFilterEffectItem *)filterConfigItem {
    
    ACCFilterEffectItem *cachedData = objc_getAssociatedObject(self, _cmd);
    
    if (cachedData) {
        return cachedData;
    } else {
        if ([self.extra length] > 0 ) {
            NSData *data = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonSerializationError = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error:&jsonSerializationError];
            if (jsonSerializationError) {
                AWELogToolError(AWELogToolTagRecord, @"JSON Serialization error: %@", jsonSerializationError);
            }
            if ([dict isKindOfClass:NSDictionary.class]) {
                id _filter = dict[@"filterconfig"];
                if (_filter) {
                    NSDictionary *filterDict;
                    if ([_filter isKindOfClass:NSDictionary.class]) {
                        filterDict = _filter;
                    } else if ([_filter isKindOfClass:NSString.class]) {
                        jsonSerializationError = nil;
                        filterDict = [NSJSONSerialization JSONObjectWithData:[_filter dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonSerializationError];
                        if (jsonSerializationError) {
                            AWELogToolError(AWELogToolTagRecord, @"JSON Serialization error: %@", jsonSerializationError);
                        }
                    }
                    
                    NSArray *itemJsonArray = (NSArray *)([filterDict[@"items"] isKindOfClass:NSArray.class] ? filterDict[@"items"] : nil);
                    if (itemJsonArray) {
                        NSError *error = nil;
                        NSArray<ACCFilterEffectItem *> *items = [MTLJSONAdapter modelsOfClass:ACCFilterEffectItem.class fromJSONArray:itemJsonArray error:&error];
                        ACCFilterEffectItem *item = [items firstObject];
                        
                        if (error) {
                            AWELogToolError(AWELogToolTagRecord, @"json to model error: %@", error);
                        }
                        
                        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                        return item;
                    }
                }
            }
        }
    }
    
    return nil;
}

- (BOOL)isComposerFilter {
    
    id cachedData = objc_getAssociatedObject(self, _cmd);
    if (cachedData) {
        return [cachedData boolValue];
    } else {
        NSString *configFilePath = [self.resourcePath stringByAppendingPathComponent:@"config.json"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:configFilePath]) {
            return NO;
        }

        NSData *configData = [NSData dataWithContentsOfFile:configFilePath];
        if (!configData) {
            return NO;
        }

        NSError *jsonSerializationError = nil;
        NSDictionary *configContent = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&jsonSerializationError];

        if (!configContent || jsonSerializationError) {
            AWELogToolError(AWELogToolTagRecord, @"composer filter config.json Serialization error: %@", jsonSerializationError);
            return NO;
        }

        BOOL isComposerFilterResource = configContent[@"effect"] != nil;
        objc_setAssociatedObject(self, _cmd, @(isComposerFilterResource), OBJC_ASSOCIATION_ASSIGN);
        return isComposerFilterResource;
    }
}

- (NSArray<VEComposerInfo *> *)nodeInfosWithIntensity:(float)intensity {
    if (self.isComposerFilter) {
        NSString *pathTag = [NSString stringWithFormat:@"%@;%@;%f", self.resourcePath, self.filterConfigItem.tag, intensity];
        VEComposerInfo *node = [[VEComposerInfo alloc] init];
        node.node = pathTag;
        node.tag = self.extra;
        return @[node];
    } else {
        return @[];
    }
}

- (NSArray<VEComposerInfo *> *)appendedNodeInfosWithPosition:(float)position
                                                  isLeftSide:(BOOL)isLeftSide {
    if (self.isComposerFilter) {
        NSString *positionKey = isLeftSide ? kLeftSlidePosition : kRightSlidePosition;
        NSString *pathTag = [NSString stringWithFormat:@"%@;%@;%f", self.resourcePath, positionKey, position];
        VEComposerInfo *node = [[VEComposerInfo alloc] init];
        node.node = pathTag;
        node.tag = self.extra;
        return @[node];
    } else {
        return @[];
    }
}

- (NSArray<VEComposerInfo *> *)nodeInfos {
    if (self.isComposerFilter) {
        VEComposerInfo *node = [[VEComposerInfo alloc] init];
        node.node = self.resourcePath;
        node.tag = self.extra;
        return @[node];
    } else {
        return @[];
    }
}

@end
