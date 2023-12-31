//
//  ACCHotPropDataManager.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/14.
//

#import "ACCHotPropDataManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWEStickerPickerModel+Favorite.h"

@interface ACCHotPropDataManager()
@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, copy) NSArray<NSString *> *urlPrefix;
@property (nonatomic, strong) NSArray<IESEffectModel *> *effects;
@property (nonatomic, copy) NSArray<IESEffectModel *> *favorEffects;

@property (nonatomic, copy) NSString *panelName;
@property (nonatomic, copy) NSString *category;

@property (nonatomic, assign) NSInteger pageCount;

@property (nonatomic, assign) BOOL isFavorRequestSuccess;
@property (nonatomic, assign) BOOL isHotRequestSuccess;

@property (nonatomic, assign) BOOL isFavorRequesting;
@property (nonatomic, assign) BOOL isHotRequesting;
@property (nonatomic, assign) BOOL isRecognitionRequesting;

@end

@implementation ACCHotPropDataManager

- (instancetype)initWithCount:(NSInteger)count
{
    self = [super init];
    if (self) {
        _panelName = @"default";
        _category = @"hot";
        _pageCount = count;
    }
    return self;
}

#pragma mark - Favor

- (void)fetchFavorWithCompletion:(void (^)(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects))completion
{
    @weakify(self);
    self.isFavorRequesting = YES;
    [EffectPlatform downloadMyEffectListWithPanel:self.panelName completion:^(NSError * _Nullable error, NSArray<IESMyEffectModel *> * _Nullable myEffects) {
        @strongify(self);
        if (!self) {
            return;
        }
        self.isFavorRequesting = NO;
        if (error == nil && myEffects) {
            [self handleFavoriteEffectModels:myEffects.firstObject.effects];
            self.isFavorRequestSuccess = YES;
        }
        if (completion) {
            completion(error, self.favorEffects);
        }
    }];
}

- (void)updateFavoriteEffects:(NSArray<IESEffectModel *> *)favoriteEffects
{
    if (!self.isFavorRequestSuccess) {
        [self handleFavoriteEffectModels:favoriteEffects];
        self.isFavorRequesting = NO;
        self.isFavorRequestSuccess = YES;
    }
}

- (void)insertPropToFavorite:(IESEffectModel *)prop
{
    if (prop == nil) {
        return;
    }

    IESEffectModel *propInFavorList = [self.favorEffects acc_match:^BOOL(IESEffectModel * _Nonnull item) {
        return [item.effectIdentifier isEqual:prop.effectIdentifier];
    }];
    if (propInFavorList != nil) {
        return;
    }
    NSMutableArray *props = [[NSMutableArray alloc] init];
    [props addObject:prop];
    if (self.favorEffects.count > 0) {
        [props addObjectsFromArray:self.favorEffects];
    }
    self.favorEffects = props;
}

- (void)deletePropFromFavorite:(IESEffectModel *)prop
{
    if (prop == nil) {
        return;
    }

    if (self.favorEffects.count > 0) {
        NSMutableArray *props = [[NSMutableArray alloc] initWithArray:self.favorEffects];
        NSUInteger index = [props indexOfObject:prop];
        if (NSNotFound != index) {
            [props removeObjectAtIndex:index];
            self.favorEffects = props;
        }
    }
}

- (void)changeFavoriteWithEffect:(IESEffectModel *)effect favorite:(BOOL)favorite completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    if (effect.effectIdentifier == nil) {
        if (completionHandler) {
            completionHandler([NSError errorWithDomain:@"com.aweme.sticker" code:-1 userInfo:nil]);
        }
        return;
    }
    [self.propPickerModel updateSticker:effect favoriteStatus:favorite completion:^(BOOL success, NSError * _Nullable error) {
        if (error == nil) {
            if (favorite) {
                [self insertPropToFavorite:effect];
            } else {
                [self deletePropFromFavorite:effect];
            }
        }
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)handleFavoriteEffectModels:(NSArray<IESEffectModel *> *)favoriteEffects
{
    self.favorEffects = favoriteEffects;
    if (self.propPickerDataSource) {
        
        NSArray<IESEffectModel *> *effectListToAdd = [self.favorEffects acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
            return [self.propPickerDataSource effectFromMapForId:item.effectIdentifier] == nil;
        }];
        if (effectListToAdd.count > 0) {
            [self.propPickerDataSource addEffectsToMap:effectListToAdd];
        }
    }
}

#pragma mark - Hot Props

- (void)loadDataCompletion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion
{
    self.isHotRequesting = YES;
    [self loadDataWithOptions:[self extraParamsBeforeRequest] count:self.pageCount completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        self.isHotRequesting = NO;
        self.isHotRequestSuccess = effects.count > 0;
        completion(error, effects);
    }];
}

- (void)loadRecognitionWithParams:(NSDictionary *)params count:(NSInteger)count  completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion
{
    self.isRecognitionRequesting = YES;
    [self loadDataWithOptions:params count:count completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        self.isRecognitionRequesting = NO;
        self.recognitionEffects = effects;
        completion(error, effects);
    }];
}

- (void)clearRecognitionProps
{
    self.recognitionEffects = @[];
}

- (void)loadDataWithOptions:(NSDictionary *)options count:(NSInteger)count completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion
{
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:self.panelName category:self.category completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName category:self.category];
        if (needUpdate || !cachedResponse) {
            [EffectPlatform downloadEffectListWithPanel:self.panelName category:self.category pageCount:100 cursor:0 sortingPosition:0 completion:^(__unused NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                [self handleResponse:response requestError:error completion:completion];
            }];
        } else {
            [self handleResponse:cachedResponse requestError:nil completion:completion];
        }
    }];
}

- (void)handleResponse:(IESEffectPlatformNewResponseModel *)response requestError:(NSError *)requestError completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion
{
    if (response) {
        self.urlPrefix = response.urlPrefix;
        self.effects = [response.categoryEffects.effects copy];
        if (self.propPickerDataSource) {
            
            NSArray<IESEffectModel *> *effectListToAdd = [self.effects acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
                return [self.propPickerDataSource effectFromMapForId:item.effectIdentifier] == nil;
            }];
            if (effectListToAdd.count > 0) {
                [self.propPickerDataSource addEffectsToMap:effectListToAdd];
            }
            
            // bind
            effectListToAdd = [response.categoryEffects.bindEffects acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
                return [self.propPickerDataSource effectFromMapForId:item.effectIdentifier] == nil;
            }];
            if (effectListToAdd.count > 0) {
                [self.propPickerDataSource addEffectsToMap:effectListToAdd];
            }

            // collection
            effectListToAdd = [response.categoryEffects.collection acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
                return [self.propPickerDataSource effectFromMapForId:item.effectIdentifier] == nil;
            }];
            if (effectListToAdd.count > 0) {
                [self.propPickerDataSource addEffectsToMap:effectListToAdd];
            }
        }
    } else {
        self.urlPrefix = nil;
        self.effects = @[];
    }
    ACCBLOCK_INVOKE(completion, requestError, self.effects);
}

- (NSDictionary *)extraParamsBeforeRequest {
    // 透传给后台进行模型训练
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (self.referString.length > 0) {
        params[@"shoot_way"] = self.referString;
    }
    if (self.fromPropId.length > 0) {
        params[@"from_prop_id"] = self.fromPropId;
    }
    NSString *musicId = ACCBLOCK_INVOKE(self.currentSelectedMusicHandler);
    if (musicId.length > 0) {
        params[@"music_id"] = musicId;
    }
    return [params copy];
}

@end
