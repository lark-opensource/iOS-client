//
//  ACCEditTagsPOISearchTypeSelectionView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/12.
//

#import <UIKit/UIKit.h>

@interface ACCEditTagsPOISearchType : NSObject

@property (nonatomic, assign) NSInteger searchType;
@property (nonatomic, copy, nullable) NSString *searchTypeName;

@end

@class ACCEditTagsPOISearchTypeSelectionView;
@protocol ACCEditTagsPOISearchTypeSelectionViewDelegate <NSObject>

- (void)searchTypeSelectionView:(ACCEditTagsPOISearchTypeSelectionView * _Nonnull)searchTypeSelectionView didSelectSearchType:(ACCEditTagsPOISearchType * _Nonnull)searchType;

- (void)searchTypeSelectionViewWillDismiss:(ACCEditTagsPOISearchTypeSelectionView * _Nonnull)searchTypeSelectionView;
@end

@interface ACCEditTagsPOISearchTypeSelectionView : UIView<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong, nonnull) UITableView *tableView;
@property (nonatomic, weak, nullable) id<ACCEditTagsPOISearchTypeSelectionViewDelegate>delegate;
- (CGFloat)menuHeight;
- (void)setTopInset:(CGFloat)topInset;

- (void)updateWithSearchTypes:(NSArray<ACCEditTagsPOISearchType *> * _Nonnull)searchTypes selectedType:(ACCEditTagsPOISearchType * _Nonnull)selectedType;

- (void)showOnView:(UIView * _Nonnull)view;
- (void)dismiss;

- (NSTimeInterval)animationDuration;
@end
