//
//  BDUGAutoLogDebugUploader.m
//  Pods
//
//  Created by shuncheng on 2019/6/20.
//

#import "BDUGAutoLogDebugUploader.h"
#import "BDUGLogDebugUploader.h"

@implementation BDUGAutoLogDebugUploader

+ (void)load
{
    [BDUGAutoLogDebugUploader sharedInstance];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDUGAutoLogDebugUploader *ins;
    dispatch_once(&onceToken, ^{
        ins = [[BDUGAutoLogDebugUploader alloc] init];
    });
    return ins;
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onApplicationDidFinishLaunchingNotification:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)onApplicationDidFinishLaunchingNotification:(NSDictionary *)aUserInfo
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"上传Debug日志" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[BDUGLogDebugUploader sharedInstance] uploadWithTag:@"BDUGAutoLogDebugUploader"
                                                     andCallback:^(BOOL isSuccess, NSInteger fileCount) {
                                                         if (isSuccess) {
                                                             NSLog(@"上传成功");
                                                         }
                                                     }];
        }];
        [alertController addAction:okAction];
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:alertController animated:YES completion:nil];
    });
}

@end
