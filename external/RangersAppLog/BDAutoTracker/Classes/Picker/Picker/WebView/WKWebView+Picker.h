//
//  WKWebView+Picker.h
//  Applog
//
//  Created by bob on 2019/4/16.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AppLogPickerView;

@interface WKWebView (Picker)

@property (nonatomic, assign) BOOL bd_pickJSInjected;

- (void)bd_pickerViewStart;

- (nullable AppLogPickerView *)bd_pickerView;

@end

NS_ASSUME_NONNULL_END
