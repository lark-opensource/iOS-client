//
//  EMAAlertTextView.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/18.
//

#import <UIKit/UIKit.h>

// 支持placeholder和最大字符数maxLength的textview

NS_ASSUME_NONNULL_BEGIN

@interface EMAAlertTextView : UITextView

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, assign) NSInteger maxLength;

@end

NS_ASSUME_NONNULL_END
