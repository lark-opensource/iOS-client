//
//  ACCGrootStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerModel.h"
#import <CreativeKit/ACCMacros.h>
#import <Mantle/EXTKeyPathCoding.h>
#import <Mantle/Mantle.h>
#import <CreationKitInfra/ACCLogHelper.h>

/// 二级模型过滤后的信息
@interface ACCGrootDetailsStickerFilterModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *speciesName;
@property (nonatomic, copy, nullable) NSNumber *prob;
@property (nonatomic, copy, nullable) NSNumber *baikeId;
@property (nonatomic, copy, nullable) NSString *baikeHeadImage;
@property (nonatomic, copy, nullable) NSString *baikeIcon;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy, nullable) NSString *engName;

@end

@implementation ACCGrootDetailsStickerFilterModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    ACCGrootDetailsStickerFilterModel *model = nil;
    NSDictionary *dic =  @{
        @keypath(model, speciesName) : @"species_name",
        @keypath(model, prob) : @"prob",
        @keypath(model, baikeId) : @"baike_id",
        @keypath(model, baikeHeadImage) : @"baike_head_image",
        @keypath(model, baikeIcon) : @"baike_icon",
        @keypath(model, categoryName) : @"category_name",
        @keypath(model, engName) : @"eng_name",
    };
    return dic;
}

//+ (NSValueTransformer *)probJSONTransformer {
//    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
//        NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
//                                                                                                          scale:20
//                                                                                               raiseOnExactness:NO
//                                                                                                raiseOnOverflow:NO
//                                                                                               raiseOnUnderflow:NO
//                                                                                            raiseOnDivideByZero:NO];
//        NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithDouble:[value doubleValue]];
//        NSDecimalNumber *result = [decimalNumber decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
//        return result;
//    }];
//}

@end

/// 一级模型&二级模型过滤后的总信息
@interface ACCGrootStickerFilterModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSNumber *hasGroot;
@property (nonatomic, copy, nullable) NSArray<ACCGrootDetailsStickerFilterModel *> *grootDetailStickerModels;
@property (nonatomic, assign) BOOL allowGrootResearch;
@property (nonatomic, copy, nullable) NSDictionary *extra;
@property (nonatomic, copy, nullable) NSDictionary *userGrootInfo;
@property (nonatomic, assign) BOOL fromRecord;

@end

@implementation ACCGrootStickerFilterModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    ACCGrootStickerFilterModel *model = nil;
    NSDictionary *dic =  @{
        @keypath(model, hasGroot) : @"first_model_result",
        @keypath(model, grootDetailStickerModels) : @"ai_lab_groot_infos",
        @keypath(model, allowGrootResearch) : @"allow_groot_research",
        @keypath(model, extra) : @"extra",
        @keypath(model, userGrootInfo) : @"user_groot_info",
        @keypath(model, fromRecord) : @"from_record"
    };
    return dic;
}

+ (NSValueTransformer *)grootDetailStickerModelsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCGrootDetailsStickerFilterModel.class];
}

@end

#pragma mark - ACCGrootDetailsStickerModel

@implementation  ACCGrootDetailsStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    ACCGrootDetailsStickerModel *model = nil;
    NSDictionary *dic =  @{
        @keypath(model, speciesName) : @"species_name",
        @keypath(model, commonName) : @"common_name",
        @keypath(model, categoryName) : @"category_name",
        @keypath(model, prob) : @"prob",
        @keypath(model, baikeId) : @"baike_id",
        @keypath(model, baikeHeadImage) : @"baike_head_image",
        @keypath(model, baikeIcon) : @"icon",
        @keypath(model, engName) : @"latin_name",
    };
    return dic;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ACCGrootDetailsStickerModel *model = [[ACCGrootDetailsStickerModel allocWithZone:zone] init];
    model.isDummy = self.isDummy;
    model.speciesName = [self.speciesName copy];
    model.commonName = [self.commonName copy];
    model.categoryName = [self.categoryName copy];
    model.prob = [self.prob copy];
    model.baikeId = [self.baikeId copy];
    model.baikeHeadImage = [self.baikeHeadImage copy];
    model.baikeIcon = [self.baikeIcon copy];
    model.engName = [self.engName copy];
    return model;
}

//+ (NSValueTransformer *)probJSONTransformer {
//    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
//        NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
//                                                                                                          scale:2
//                                                                                               raiseOnExactness:NO
//                                                                                                raiseOnOverflow:NO
//                                                                                               raiseOnUnderflow:NO
//                                                                                            raiseOnDivideByZero:NO];
//        NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithDouble:[value doubleValue]];
//        NSDecimalNumber *result = [decimalNumber decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
//        return result;
//    }];
//}

@end


#pragma mark - ACCGrootStickerModel

@interface ACCGrootStickerModel ()

@property (nonatomic, copy, nullable) NSString *effectIdentifier;

@end

@implementation ACCGrootStickerModel

#pragma mark - life cycle
 
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    ACCGrootStickerModel *model = nil;
    return @{
        @keypath(model, hasGroot) : @"first_model_result",
        @keypath(model, selectedGrootStickerModel) : @"review_groot_info",
        @keypath(model, grootDetailStickerModels) : @"ai_lab_groot_infos",
        @keypath(model, allowGrootResearch) : @"allow_groot_research",
        @keypath(model, extra) : @"extra",
        @keypath(model, userGrootInfo) : @"user_groot_info",
        @keypath(model, fromRecord) : @"from_record"
    };
}
 
+ (NSValueTransformer *)selectedGrootStickerModelJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCGrootDetailsStickerModel.class];
}
 
+ (NSValueTransformer *)grootDetailStickerModelsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCGrootDetailsStickerModel.class];
}

- (instancetype)initWithEffectIdentifier:(nullable NSString *)effectIdentifier {
    if (self = [super init]) {
        _effectIdentifier = [effectIdentifier copy];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ACCGrootStickerModel *model = [[ACCGrootStickerModel allocWithZone:zone] init];
    model.effectIdentifier = [self.effectIdentifier copy];
    model.hasGroot = [self.hasGroot copy];
    model.selectedGrootStickerModel = [self.selectedGrootStickerModel copy];
    model.grootDetailStickerModels = [self.grootDetailStickerModels copy];
    model.allowGrootResearch = self.allowGrootResearch;
    model.extra = [self.extra copy];
    model.userGrootInfo = [self.userGrootInfo copy];
    model.fromRecord = self.fromRecord;
    return model;
}

#pragma mark - draft handler

- (void)recoverDataFromDraftJsonString:(NSString *)jsonString {
    if (ACC_isEmptyString(jsonString)) {
        return;
    }
    
    ACCGrootStickerModel *draftModel = nil;
    @try {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:kNilOptions
                                                              error:nil];
        if ([dic isKindOfClass:NSDictionary.class]) {
            draftModel = [MTLJSONAdapter modelOfClass:[ACCGrootStickerModel class]
                                   fromJSONDictionary:dic
                                                error:nil];
        }
    } @catch (NSException *exception) {
        AWELogToolError2(@"Groot", AWELogToolTagEdit, @"Fail to recover gootModel.");
    }
    if (!draftModel) {
        return;
    }
    
    self.hasGroot = draftModel.hasGroot;
    self.selectedGrootStickerModel = draftModel.selectedGrootStickerModel;
    self.grootDetailStickerModels = draftModel.grootDetailStickerModels;
    self.allowGrootResearch = draftModel.allowGrootResearch;
    self.fromRecord = draftModel.fromRecord;
    self.userGrootInfo = draftModel.userGrootInfo;
}

- (NSString *)draftDataJsonString  {
    ACCGrootStickerModel *draftModel = [[ACCGrootStickerModel alloc] init];
    draftModel.selectedGrootStickerModel = [self.selectedGrootStickerModel copy];
    draftModel.grootDetailStickerModels = [self.grootDetailStickerModels copy];
    draftModel.allowGrootResearch = self.allowGrootResearch;
    draftModel.extra = [self.extra copy];
    draftModel.userGrootInfo = [self.userGrootInfo copy];
    draftModel.fromRecord = self.fromRecord;
    if (self.grootDetailStickerModels.count > 0 && !self.fromRecord) {
        self.hasGroot = @(YES);
    }
    draftModel.hasGroot = [self.hasGroot copy];
    NSString *result = nil;
    @try {
        NSDictionary *draftDic = [MTLJSONAdapter JSONDictionaryFromModel:draftModel error:nil];
        if (draftDic) {
            NSData *draftData = [NSJSONSerialization dataWithJSONObject:draftDic options:kNilOptions error:nil];
            if(draftData) {
                result = [[NSString alloc] initWithData:draftData encoding:NSUTF8StringEncoding];
            }
        }
    } @catch (NSException *exception) {
        AWELogToolError2(@"Groot", AWELogToolTagEdit, @"Fail to save gootModel.");
    }
    return result;
}

+ (NSString *)grootModelResultFilterWithString:(NSString *)grootModelResultString {
    // 最终上传给服务器的模型数据，用于序列化过滤多余字段
    if (ACC_isEmptyString(grootModelResultString)) {
        return nil;
    }
    
    ACCGrootStickerFilterModel *filterModel = nil;
    ACCGrootStickerModel *grootModel = nil;
    @try {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[grootModelResultString dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:kNilOptions
                                                              error:nil];
        if ([dic isKindOfClass:NSDictionary.class]) {
            grootModel = [MTLJSONAdapter modelOfClass:[ACCGrootStickerModel class]
                                   fromJSONDictionary:dic
                                                error:nil];
            filterModel = [MTLJSONAdapter modelOfClass:[ACCGrootStickerFilterModel class]
                                    fromJSONDictionary:dic
                                                 error:nil];
        }
    } @catch (NSException *exception) {
        AWELogToolError2(@"Groot", AWELogToolTagEdit, @"Fail to recover filter gootModel.");
        return nil;
    }
    
    NSArray<ACCGrootDetailsStickerFilterModel *> *detailModels = filterModel.grootDetailStickerModels;
    if (detailModels.count > 0 && !grootModel.fromRecord) {
        filterModel.hasGroot = @(YES);
    } else if (!filterModel.hasGroot) {
        filterModel.hasGroot = @(NO);
    }
    
    NSString *result = nil;
    @try {
        NSDictionary *draftDic = [MTLJSONAdapter JSONDictionaryFromModel:filterModel error:nil];
        if (draftDic) {
            NSData *draftData = [NSJSONSerialization dataWithJSONObject:draftDic options:kNilOptions error:nil];
            if(draftData) {
                result = [[NSString alloc] initWithData:draftData encoding:NSUTF8StringEncoding];
            }
        }
    } @catch (NSException *exception) {
        AWELogToolError2(@"Groot", AWELogToolTagEdit, @"Fail to convert filter gootModel to string.");
    }
    return result;
}

@end


#pragma mark - response model

@implementation ACCGrootCheckModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"hasGroot" : @"has_groot",
        @"extra" : @"extra",
    };
}

@end


@implementation ACCGrootListModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"grootList" : @"groot_list",
        @"extra" : @"extra",
    };
}

+ (NSValueTransformer *)grootListJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCGrootDetailsStickerModel.class];
}

@end


@implementation ACCGrootCheckModelResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [@{
        @"data" : @"data",
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)dataJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCGrootCheckModel class]];
}

@end


@implementation ACCGrootListModelResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [@{
        @"data" : @"data",
    } acc_apiPropertyKey];
}

+ (NSValueTransformer *)dataJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCGrootListModel class]];
}

@end
