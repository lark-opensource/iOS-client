//
//  ACCTagsSearchBar.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/9.
//

#import <UIKit/UIKit.h>

@class ACCTagsSearchBar;

@protocol ACCTagsSearchBarDelegate <NSObject>
- (void)searchBar:(ACCTagsSearchBar * _Nonnull)searchBar textDidChange:(NSString * _Nonnull)searchText;
- (void)searchBarTextDidBeginEditing:(ACCTagsSearchBar * _Nonnull)searchBar;
- (void)searchBarCancelButtonClicked:(ACCTagsSearchBar * _Nonnull)searchBar;
- (void)searchBarSearchButtonClicked:(ACCTagsSearchBar * _Nonnull)searchBar;
@end

@interface ACCTagsSearchBar : UIView

- (instancetype)initWithLeftView:(UIView * _Nonnull)leftView leftViewWidth:(CGFloat)leftViewWidth;

@property (nonatomic, weak, nullable) id<ACCTagsSearchBarDelegate> delegate;
@property (nonatomic, strong, readonly, nonnull) UITextField *textField;

- (CGFloat)searchBarHeight;
- (void)setShowsCancelButton:(BOOL)showsCancelButton;

@end
