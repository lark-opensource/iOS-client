//
//  AWEVideoEffectSimplifiedPanelCollectionView.h
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import <UIKit/UIKit.h>

@class AWEVideoEffectChooseSimplifiedViewModel;
@class IESEffectModel;

@protocol AWEVideoEffectSimplifiedPanelCollectionViewDelegation

- (void)didTapCellAtIndex:(NSInteger)index;

@end

@interface AWEVideoEffectSimplifiedPanelCollectionView : UICollectionView

@property (nonatomic, weak, nullable) id<AWEVideoEffectSimplifiedPanelCollectionViewDelegation> viewDelegation;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithViewModel:(AWEVideoEffectChooseSimplifiedViewModel *)viewModel;
- (void)updateData;
- (void)updateCellAtIndex:(NSUInteger)index;
- (void)deselectAllItemsAnimated:(BOOL)animated;
- (NSInteger)numberOfItemsPerPage; // 一屏共有多少cell

+ (CGFloat)calculateCollectionViewHeight;

@end
