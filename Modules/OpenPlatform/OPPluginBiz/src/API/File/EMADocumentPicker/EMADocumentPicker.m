//
//  EMADocumentPicker.m
//  OPPluginBiz
//
//  Created by tujinqiu on 2019/8/26.
//

#import "EMADocumentPicker.h"
#import <OPFoundation/OPFoundation-Swift.h>

@interface EMADocumentPicker ()<UIDocumentPickerDelegate>

@property(nonatomic, copy) EMADocumentPickerCallback callback;

@end

@implementation EMADocumentPicker

+ (void)showWithCallback:(EMADocumentPickerCallback)callback window:(UIWindow * _Nullable)window
{
    UIViewController *topVc = [OPNavigatorHelper topMostAppControllerWithWindow:window];
    if (!topVc) {
        !callback ?: callback(NO, nil);
        return;
    }

    EMADocumentPicker *picker = [[EMADocumentPicker alloc] initWithDocumentTypes:@[@"public.item"] inMode:UIDocumentPickerModeImport];
    picker.callback = callback;
    picker.allowsMultipleSelection = NO;
    picker.delegate = picker;

    [topVc presentViewController:picker animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls {
    !self.callback ?: self.callback(NO, urls.firstObject);
    self.callback = nil;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    !self.callback ?: self.callback(NO, url);
    self.callback = nil;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    !self.callback ?: self.callback(YES, nil);
    self.callback = nil;
}

@end
