//
//  ACCSpeciesInfoCardsView.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCSpeciesInfoCardsView;
@protocol ACCSpeciesInfoCardsViewDelegate <NSObject>
@optional

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didSelectItemAtIndex:(NSInteger)index withAllowResearch:(BOOL)allowResearch;

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didSlideCardFrom:(NSInteger)from to:(NSInteger)to withAllowResearch:(BOOL)allowResearch;

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didCloseAtIndex:(NSInteger)index withAllowResearch:(BOOL)allowResearch;

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didCheckAllowResearch:(BOOL)allowResearch;

@end

@protocol ACCSpeciesInfoCardsViewDataSource <UICollectionViewDataSource>
@optional

/*
 You can use this method to control display realDataTips or dummyDataTips.
 
 dummyDataTips will be displayed only when YES is returned，
 */
- (BOOL)isDummyDataInCardsView:(ACCSpeciesInfoCardsView *)cardsView;

@end

@interface ACCSpeciesInfoCardsViewConfig : NSObject

@property (nonatomic, copy) NSString *confirmText;

@property (nonatomic, copy) NSString *realDataTips;

@property (nonatomic, copy) NSString *dummyDataTips;

@property (nonatomic, copy, nullable) NSString *allowResearchTips;

@property (nonatomic, assign) BOOL allowResearch;

/*
 Use this method to initialize, you can directly use the default parameters.
 
 Default parameters:
    confirmText = "确认"
    allowResearchTips = nil
    realDataTips = "识别到的物种是"
    dummyDataTips = "未识别出动植物，你还可以"
    allowResearch = NO
 */
+ (instancetype)configWithDefaultParams;

+ (instancetype)configWithGrootParams;

@end

/*
 Implementation of reference ACCGrootStickerSelectView, will consider compatibility with the two later.
 */
@interface ACCSpeciesInfoCardsView : UIView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame config:(ACCSpeciesInfoCardsViewConfig *)config NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<ACCSpeciesInfoCardsViewDelegate> delegate;
@property (nonatomic, weak) id<ACCSpeciesInfoCardsViewDataSource> dataSource;

/*
 If you exceed the maximum number, it will be modified to 0.
 This parameter must be set before the reloadData method or resetSelectionAsDefault method is called to be effective.
 */
@property (nonatomic, assign) NSUInteger defaultSelectionIndex;
@property (nonatomic, assign, readonly) NSInteger currentSelectedIndex;

- (void)reloadData;
- (void)registerCell:(Class)cellClass;
- (void)resetSelectedIndex:(NSUInteger)index;
- (void)resetSelectionAsDefault;

+ (CGSize)designSizeWithConfig:(ACCSpeciesInfoCardsViewConfig *)config;

@end

NS_ASSUME_NONNULL_END
