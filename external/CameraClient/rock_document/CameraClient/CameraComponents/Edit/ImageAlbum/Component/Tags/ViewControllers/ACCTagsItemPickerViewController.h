//
//  ACCTagsItemPickerViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import <UIKit/UIKit.h>
#import "ACCEditTagsDefine.h"
#import "ACCEditTagsSearchEmptyView.h"
#import "ACCTagsSearchBar.h"
#import "AWEInteractionEditTagStickerModel.h"

typedef NS_ENUM(NSInteger, ACCTagsItemPickerLoadStatus) {
    ACCTagsItemPickerLoadStatusNone = 0,
    ACCTagsItemPickerLoadStatusInitial = 1,
    ACCTagsItemPickerLoadStatusLoading = 2,
    ACCTagsItemPickerLoadStatusSuccess = 3,
    ACCTagsItemPickerLoadStatusError = 4,
    ACCTagsItemPickerLoadStatusEmpty = 5,
};
@class ACCTagsItemPickerViewController;
@protocol ACCTagsItemPickerViewControllerDelegate<NSObject>
- (void)tagsItemPicker:(ACCTagsItemPickerViewController * _Nonnull)itemPicker didSelectItem:(AWEInteractionEditTagStickerModel * _Nonnull)item referExtra:(NSDictionary * _Nullable)referExtra;
- (void)tagsItemPickerDidTapCreateCustomTagButton:(ACCTagsItemPickerViewController * _Nonnull)itemPicker keyword:(NSString *_Nullable)keyword;

- (BOOL)isCurrentTagPicker:(ACCTagsItemPickerViewController * _Nonnull)tagsPicker;
@end

@protocol ACCTagsItemPickerTableViewCellProtocol <NSObject>

- (void)updateWithData:(NSObject *_Nullable)data;

@end

typedef void (^ACCTagSearchCompletion)(NSArray *_Nullable, NSError *_Nullable, BOOL);

@interface ACCTagsItemPickerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly, nullable) UITableView *tableView;
@property (nonatomic, strong, readonly, nullable) ACCTagsSearchBar *searchBar;
@property (nonatomic, assign) BOOL needSearchBar;
@property (nonatomic, copy, nullable) NSString *currentKeyword;
@property (nonatomic, assign) ACCTagsItemPickerLoadStatus loadStatus;
@property (nonatomic, weak, nullable) id<ACCTagsItemPickerViewControllerDelegate> delegate;
@property (nonatomic, copy, nullable) NSDictionary *trackerParams;

- (void)scrollToItem:(NSString * _Nullable)itemID;
- (void)clearSearchCondition;

//Data Management
- (void)fetchRecommendData;
- (void)searchWithKeyword:(NSString * _Nullable)searchWithKeyword completion:(ACCTagSearchCompletion)completion;
- (void)loadMoreWithKeyword:(NSString * _Nullable)searchWithKeyword completion:(ACCTagSearchCompletion)completion;

//For subclassing
- (UIView * _Nullable)currentView;
- (ACCEditTagsSearchEmptyView * _Nullable)emptyView;
- (UIView * _Nullable)errorView;
- (UIView * _Nullable)normalView;
- (UIView * _Nullable)emptyStateView;
- (NSString * _Nullable)searchBarPlaceHolder;
- (NSString * _Nonnull)cellIdentifier;
- (CGFloat)cellHeight;
- (Class)cellClass;
- (NSArray * _Nullable)dataSource;
- (NSString * _Nullable)headerText;
- (CGFloat)headerHeight;
- (NSString * _Nullable)emptyResultText;
- (void)configCell:(nullable UITableViewCell *)cell;
- (BOOL)needFooter;
- (UIView * _Nullable)bottomView;
- (CGFloat)bottomViewHeight;
- (AWEInteractionEditTagStickerModel * _Nullable)tagModelForIndexPath:(NSIndexPath * _Nullable)indexPath;
- (BOOL)needCreateCustomTagFooter;
- (NSInteger)indexOfItem:(NSString * _Nullable)item;
- (NSString * _Nullable)itemTitle;
- (void)restoreRecommendData;
- (NSString * _Nullable)tagSource;
- (BOOL)needNoMoreFooterText;
- (void)reloadData;
- (BOOL)needNetworkRequest;
- (UIView * _Nullable)searchBarLeftView;
- (BOOL)needToTrackClickEvent;

- (ACCEditTagType)type;

//Tracker
- (NSString * _Nonnull)tagTypeString;
- (NSDictionary * _Nullable)itemTrackerParamsForItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)trackCellDisplayAtIndexPath:(NSIndexPath * _Nullable)indexPath;

- (void)handleData:(NSArray * _Nullable)data error:(NSError * _Nullable)error hasMore:(BOOL)hasMore;
- (void)updateHeaderView;
- (void)hideCancelButton;
- (BOOL)networkReachable;

@end
