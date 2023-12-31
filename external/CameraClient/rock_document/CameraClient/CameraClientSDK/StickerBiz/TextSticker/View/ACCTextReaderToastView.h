//
//  ACCTextReaderToastView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const kACCTextReaderToastViewLightHeight;
extern CGFloat const kACCTextReaderToastViewDarkHeight;

typedef NS_ENUM(NSUInteger, ACCTextReaderToastViewType) {
    ACCTextReaderToastViewTypeLight = 0,
    ACCTextReaderToastViewTypeDark
};

@interface ACCTextReaderToastView : UIView

- (instancetype)initWithType:(ACCTextReaderToastViewType)viewType;
- (void)updateTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
