//
//  IESCategoryModel.m
//  EffectPlatformSDK
//
//  Created by ziyu.li on 2018/1/26.
//

#import "IESCategoryModel.h"
#import <Mantle/MTLJSONAdapter.h>
#import "EffectPlatformBookMark.h"
#import "IESEffectModel.h"
#import "IESEffectPlatformNewResponseModel.h"

@interface IESCategoryModel()<MTLJSONSerializing>
@property (nonatomic, copy) NSString *categoryIdentifier;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, copy) NSString *categoryKey;
@property (nonatomic, copy) NSArray<NSString *> *normalIconUrls;
@property (nonatomic, copy) NSArray<NSString *> *selectedIconUrls;
@property (nonatomic, copy) NSArray <NSString *> *tags;
@property (nonatomic, copy) NSString *tagsUpdatedTimeStamp;
@property (nonatomic, copy) NSArray<IESEffectModel *> *effects;
@property (nonatomic, copy) NSArray <IESEffectModel *> *collection;
@property (nonatomic, copy) NSArray<NSString *> *effectIDs;
@property (nonatomic, assign, readwrite) BOOL hasMore;
@property (nonatomic, assign, readwrite) NSInteger cursor;
@property (nonatomic, assign, readwrite) NSInteger sortingPosition;
@end

@implementation IESCategoryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"categoryIdentifier": @"id",
             @"categoryName": @"name",
             @"categoryKey": @"key",
             @"normalIconUrls": @"icon.url_list",
             @"selectedIconUrls": @"icon_selected.url_list",
             @"tags": @"tags",
             @"tagsUpdatedTimeStamp": @"tags_updated_at",
             @"effectIDs": @"effects",
             @"isDefault": @"is_default",
             @"extra": @"extra"
             };
}

#pragma mark - Public

- (void)updateEffects:(NSArray<IESEffectModel *> *)effects collection:(NSArray <IESEffectModel *> *)collection
{
    self.effects = [effects copy];
    self.collection = [collection copy];
}

- (void)updateCategoryWithResponse:(IESEffectPlatformNewResponseModel *)model isLoadMore:(BOOL)isLoadMore
{
    if ([self.categoryKey isEqualToString:model.categoryEffects.categoryKey]) {
        self.hasMore = model.categoryEffects.hasMore;
        self.cursor = model.categoryEffects.cursor;
        self.sortingPosition = model.categoryEffects.sortingPosition;
        if (isLoadMore) {
            NSMutableArray *tmpEffects = [self.effects mutableCopy];
            [tmpEffects addObjectsFromArray:model.categoryEffects.effects];
            self.effects = tmpEffects;
            
            NSMutableArray *tmpCollection = [self.collection mutableCopy];
            [tmpCollection addObjectsFromArray:model.categoryEffects.collection];
            self.collection = tmpCollection;
        } else {
            self.effects = [model.categoryEffects.effects copy];
            self.collection = [model.categoryEffects.collection copy];
        }
    }
}

#pragma mark - Private

- (NSArray<IESEffectModel *> *)downloadedEffects
{
    return [self.effects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IESEffectModel *model, NSDictionary<NSString *,id> * _Nullable bindings) {
        return model.downloaded;
    }]];
}

- (BOOL)isEqual:(IESCategoryModel *)object {
    if (object == nil || ![object isKindOfClass:[IESCategoryModel class]]) {
        return NO;
    }
    BOOL isSameCategoryID = [object.categoryIdentifier isEqualToString:self.categoryIdentifier];
    BOOL isSameCategoryName = [object.categoryName isEqualToString:self.categoryName];
    __block BOOL isSameNormalIconUrls = YES;
    __block BOOL isSameSelectedIconUrls = YES;
    __block BOOL isSameEffects = YES;
    [self.normalIconUrls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.normalIconUrls.count != object.normalIconUrls.count) {
            *stop = YES;
            isSameNormalIconUrls = NO;
            return ;
        }
        if (![obj isEqualToString:object.normalIconUrls[idx]]) {
            isSameNormalIconUrls = NO;
            *stop = YES;
        }
    }];
    [self.selectedIconUrls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.selectedIconUrls.count != object.selectedIconUrls.count) {
            *stop = YES;
            isSameSelectedIconUrls = NO;
            return ;
        }
        if (![obj isEqualToString:object.selectedIconUrls[idx]]) {
            isSameSelectedIconUrls = NO;
            *stop = YES;
        }
    }];
    [self.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.effects.count != object.effects.count) {
            *stop = YES;
            isSameEffects = NO;
            return ;
        }
        if (![obj isEqual:object.effects[idx]]) {
            isSameEffects = NO;
            *stop = YES;
        }
    }];
    return isSameCategoryID && isSameCategoryName && isSameNormalIconUrls && isSameSelectedIconUrls & isSameEffects;
}

- (void)fillEffectsWithEffectsMap:(NSDictionary <NSString *, IESEffectModel *> *)effectsMap
{
    NSMutableArray *effectsArray = [NSMutableArray array];
    [self.effectIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESEffectModel *effect = effectsMap[obj];
        if (effect) {
            [effectsArray addObject:effect];
        }
    }];
    self.effects = [effectsArray copy];
}

- (NSUInteger)hash {
    return self.categoryIdentifier.hash ^ self.categoryName.hash ^ self.normalIconUrls.hash ^ self.selectedIconUrls.hash ^ self.effects.hash;
}


@end

@implementation IESCategoryModel(BookMark)
- (BOOL)showRedDotWithTag:(NSString *)tag
{
    if (tag && tag.length > 0 && [self.tags containsObject:tag]) {
        return ![EffectPlatformBookMark isReadForCategory:self];
    }
    return NO;
}

- (void)markAsReaded
{
    [EffectPlatformBookMark markReadForCategory:self];
}

@end
