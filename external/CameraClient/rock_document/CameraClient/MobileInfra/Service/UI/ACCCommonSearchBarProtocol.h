//
//  ACCCommonSearchBarProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/9/7.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

typedef NS_ENUM(NSUInteger, ACCCommonSearchBarType) {
    ACCCommonSearchBarTypeRightButtonAuto,
    ACCCommonSearchBarTypeRightButtonShow,
    ACCCommonSearchBarTypeRightButtonHidden,
};
@protocol ACCCommonSearchBarProtocol;
@protocol ACCCommonSearchBarDelegate <UITextFieldDelegate>

@optional

- (void)searchBar:(id<ACCCommonSearchBarProtocol>)searchBar textDidChange:(NSString *)searchText;

@end

@protocol ACCCommonSearchBarProtocol <NSObject>

@property (nonatomic, assign) ACCCommonSearchBarType type;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, assign) BOOL shouldShowRightButton;
@property (nonatomic, weak) id<ACCCommonSearchBarDelegate> delegate;

@property (nonatomic, copy) NSString *placeHolder;
@property (nonatomic, copy) NSAttributedString *attributedPlaceHolder;
@property (nonatomic, strong, nullable) NSString *text;

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *searchTintColor;
@property (nonatomic, strong) UIColor *searchFiledBackgroundColor;
@property (nonatomic, strong, nullable) UIImage *clearImage;
@property (nonatomic, strong, nullable) UIColor *lensImageTintColor;
@property (nonatomic, strong, nullable) UIImage *lensImage;

@property (nonatomic, copy, nullable) NSString *rightButtonTitle;
@property (nonatomic, copy, nullable) void(^rightButtonClickedBlock)(void);

- (UIView *)accSearchBar;

- (void)animatedShowCancelButton:(BOOL)show;

@end

FOUNDATION_STATIC_INLINE id<ACCCommonSearchBarProtocol> ACCCommonSearchBar() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCCommonSearchBarProtocol)];
}

