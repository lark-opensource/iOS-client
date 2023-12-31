//
//  AWERedPackThemeService.h
//  AWEStudioImplDOUYINLite-Pods-AwemeLite-AWEStudioLite
//
//  Created by Fengfanhua.byte on 2021/8/30.
//

#import <Foundation/Foundation.h>

@class IESCategorySampleEffectModel;
@class IESCategoryModel;
@class IESEffectModel;
@class IESEffectPlatformNewResponseModel;
@class AWEVideoPublishViewModel;
@class AWELiteRedPacketGuideInfo;

typedef void(^AWEEffectFetchCategoryListCompletionBlock)(NSError *_Nullable error, IESEffectPlatformNewResponseModel *_Nullable response);

@protocol AWERedPackThemeServiceSubscriber <NSObject>

@optional

- (void)redPackThemeServiceRecordModeChanged;
- (void)redPackThemeServiceModeStatueChanged;
- (void)redPackThemeServiceApplySticker:(nullable IESEffectModel *)sticker;
- (void)redPackThemeServiceGuideInfoDidLoad:(nullable NSError *)error;

@end

@protocol AWERedPackThemeService <NSObject>

@property (nonatomic, assign) BOOL isThemeRecordMode;
@property (nonatomic, assign) BOOL isVideoCaptureState;

@property (nonatomic, strong, nullable) IESEffectModel *effect;
@property (nonatomic, strong, nullable) IESCategoryModel *category;
@property (nonatomic, strong, nullable) NSDictionary *trackInfo;

@property (nonatomic, copy, nullable) BOOL(^recordShouldComple)(void);
@property (nonatomic, strong, nullable) NSArray<IESCategoryModel *> *categories;

- (void)addSubscriber:(nonnull id<AWERedPackThemeServiceSubscriber>)subscriber;
- (void)removeSubscriber:(nonnull id<AWERedPackThemeServiceSubscriber>)subscriber;
- (void)applySticker:(nullable IESEffectModel *)sticker;

//
- (void)fetchShootGuideInfoIfNeededWithPublishModel:(nonnull AWEVideoPublishViewModel *)publishModel;

@end
