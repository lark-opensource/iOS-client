//
//  ACCHotPropDataManager.h
//  Pods
//
//  Created by Shen Chen on 2020/4/14.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import "AWEStickerPicckerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCHotPropDataManager : NSObject

@property (nonatomic,   copy) NSArray<IESEffectModel *> *recognitionEffects;
@property (nonatomic, assign) BOOL needFallbackEffects;

@property (nonatomic, strong, readonly) NSArray *effects;
@property (nonatomic, copy, readonly) NSArray<IESEffectModel *> *favorEffects;

@property (nonatomic, assign) IESEffectModelTestStatusType testStatusType;

@property (nonatomic, copy) NSString *referString;
@property (nonatomic, copy) NSString *fromPropId;
@property (nonatomic, copy) NSString*(^currentSelectedMusicHandler)(void); // 音乐id
@property (nonatomic, strong) AWEStickerPicckerDataSource *propPickerDataSource;
@property (nonatomic, strong) AWEStickerPickerModel *propPickerModel;
@property (nonatomic, assign, readonly) BOOL isFavorRequestSuccess;
@property (nonatomic, assign, readonly) BOOL isHotRequestSuccess;

@property (nonatomic, assign, readonly) BOOL isFavorRequesting;
@property (nonatomic, assign, readonly) BOOL isHotRequesting;
@property (nonatomic, assign, readonly) BOOL isRecognitionRequesting;


- (instancetype)initWithCount:(NSInteger)count;

/// fetch hot prop lsit
/// @param completion completion callback
- (void)loadDataCompletion:(void (^)(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects))completion;

/// fetch recognition prop list
- (void)loadRecognitionWithParams:(NSDictionary *)params count:(NSInteger)count  completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion;

- (void)clearRecognitionProps;

- (void)updateFavoriteEffects:(NSArray<IESEffectModel *> *)favoriteEffects;

/// fetch prop data with options(recognition result currently)
/// @param options options
/// @param completion completion callback
- (void)loadDataWithOptions:(nullable NSDictionary *)options count:(NSInteger)count completion:(void (^)(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects))completion;
- (void)fetchFavorWithCompletion:(void (^)(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects))completion;
- (void)changeFavoriteWithEffect:(IESEffectModel *)effect
                        favorite:(BOOL)favorite
               completionHandler:(void (^)(NSError * _Nullable))completionHandler;
- (void)insertPropToFavorite:(IESEffectModel *)sticker;
- (void)deletePropFromFavorite:(IESEffectModel *)sticker;


@end

NS_ASSUME_NONNULL_END
