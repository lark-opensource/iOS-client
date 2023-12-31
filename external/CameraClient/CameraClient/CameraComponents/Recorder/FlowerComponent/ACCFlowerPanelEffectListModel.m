//
//  ACCFlowerPanelEffectListModel.m
//  Indexer
//
//  Created by xiafeiyu on 11/15/21.
//

#import "ACCFlowerPanelEffectListModel.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@implementation ACCFlowerPanelURLModel

+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"URI" : @"Uri",
        @"URLList" : @"UrlList",
        @"dataSize" : @"DataSize",
        @"width" : @"Width",
        @"height" : @"Height",
        @"URLKey" : @"UrlKey",
        @"fileHash" : @"FileHash",
        @"fileCS" : @"FileCs",
        @"playerAccessKey" : @"PlayerAccessKey",
    };
}

@end

@implementation ACCFlowerPanelEffectModel

+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"effectID" : @"effect_id",
        @"name" : @"name",
        @"iconURL" : @"icon",
        @"isLocked" : @"is_locked",
        @"editTaskID" : @"edit_task_id",
        @"publishTaskID" : @"publish_task_id",
        @"dType" : @"d_type",
        @"extra" : @"extra",
    };
}

+ (NSValueTransformer *)iconURLJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCFlowerPanelURLModel class]];
}

- (NSDictionary *)flowerPhotoPropEffectPanelInfo
{
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];
    if (self.dType != ACCFlowerEffectTypePhoto) {
        return infos.copy;
    }
    NSData *data = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil) {
        AWELogToolError2(@"prop", AWELogToolTagRecord, @"flower photo extra serialization failed: %@", error);
        return infos.copy;
    }
    
    if ([jsonDict isKindOfClass:[NSDictionary class]]) {
        [infos addEntriesFromDictionary:jsonDict];
    }
    return infos.copy;
}

+ (instancetype)panelEffectModelFromIESEffectModel:(IESEffectModel *)model
{
    ACCFlowerPanelEffectModel *item = [[ACCFlowerPanelEffectModel alloc] init];
    // mock server properties
    item.effectID = model.effectIdentifier;
    item.name = model.effectName;
    item.iconURL = [[ACCFlowerPanelURLModel alloc] init];
    item.iconURL.URI = model.iconDownlaodURI;
    item.iconURL.URLList = model.iconDownloadURLs;
    item.dType = ACCFlowerEffectTypeProp;
    item.extra = model.extra;
    
    // mock local properties
    item.effect = model;
    return item;
}

@end

@implementation ACCFlowerPanelPreCampainEffectListModel

+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"effectList" : @"data.list",
        @"landingIndex" : @"data.landing_index",
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)effectListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCFlowerPanelEffectModel class]];
}

@end

@implementation ACCFlowerPanelEffectListModel

+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"leftList" : @"data.left_list",
        @"rightList" : @"data.right_list",
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)leftListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCFlowerPanelEffectModel class]];
}

+ (NSValueTransformer *)rightListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCFlowerPanelEffectModel class]];
}

@end
