//
//  IESEffectView.h
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import <UIKit/UIKit.h>

@class IESEffectView;
@class IESEffectModel;
@class IESCategoryModel;
@class IESEffectUIConfig;
@class IESEffectPlatformResponseModel;

static NSString * const kIESCleanAllStickerNotification = @"kIESCleanAllStickerNotification";
static NSString * const kIESCancelStickerSelectionNotification = @"kIESCancelStickerSelectionNotification";
static NSString * const kIESStickerIconDownloadedNotification = @"kIESStickerIconDownloadedNotification";


@protocol IESEffectViewDelegate <NSObject>
@required
- (void)effectView:(IESEffectView *)listView didSelectEffect:(IESEffectModel *)effect;
- (void)effectView:(IESEffectView *)listView didSelectCategory:(IESCategoryModel *)category;
- (void)effectView:(IESEffectView *)listView didDownloadedEffectWithId:(NSString *)stickerId withError:(NSError *)error duration:(CFTimeInterval)duration;
@end

@interface IESEffectView : UIView
@property (nonatomic, weak) id<IESEffectViewDelegate> delegate;

- (instancetype)initWithPanel:(NSString *)panel
             selectedCategory:(IESCategoryModel *)category
                selectedModel:(IESEffectModel *)model
                     uiConfig:(IESEffectUIConfig *)config;
- (instancetype)initWithPanel:(NSString *)panel
                     uiConfig:(IESEffectUIConfig *)config;
- (instancetype)initWithModel:(IESEffectPlatformResponseModel *)model
             selectedCategory:(IESCategoryModel *)category
                selectedModel:(IESEffectModel *)model
                     uiConfig:(IESEffectUIConfig *)config;
;
- (instancetype)initWithModel:(IESEffectPlatformResponseModel *)effect
                     uiConfig:(IESEffectUIConfig *)config;
;

- (void)cancelPreviousSelection;
@end
