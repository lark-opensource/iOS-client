//
//  EMADocumentPicker.h
//  OPPluginBiz
//
//  Created by tujinqiu on 2019/8/26.
//

#import <UIKit/UIKit.h>

typedef void (^EMADocumentPickerCallback)(BOOL isCancel, NSURL *url);

NS_ASSUME_NONNULL_BEGIN

@interface EMADocumentPicker : UIDocumentPickerViewController

+ (void)showWithCallback:(EMADocumentPickerCallback)callback window:(UIWindow * _Nullable)window;

@end

NS_ASSUME_NONNULL_END
