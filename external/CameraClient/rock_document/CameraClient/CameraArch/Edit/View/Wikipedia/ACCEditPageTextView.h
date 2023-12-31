//
//  ACCEditPageTextView.h
//  CameraClient
//
//  Created by resober on 2020/3/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCTextViewDelegate <UITextViewDelegate>

@end

@interface ACCEditPageTextView : UITextView
/// Use acc_delegate instead of deletage, else ACCTextView cannot intercept message.
@property (nonatomic, weak) id<ACCTextViewDelegate> acc_delegate;
@property (nonatomic, strong) NSString *textStickerId;
@property (nonatomic, assign) BOOL forCoverText;

- (BOOL)hasVisibleTexts;
@end

NS_ASSUME_NONNULL_END
