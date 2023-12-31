//
//  CameraRecordController.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import "CameraRecordController.h"
#import "MVPBaseServiceContainer.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import <TTVideoEditor/HTSVideoData+CacheDirPath.h>
#import <CreationKitRTProtocol/ACCCameraControlProtocol.h>
#import <CreativeKit/ACCMacros.h>

@interface CameraRecordController ()
@property (nonatomic, assign) BOOL vcIsAppeared;
@end

@implementation CameraRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    [LVDCameraMonitor setTabWithPhoto:YES];
    [LVDCameraMonitor customTrack:@"public_photograph_view" params:@{}];
    [MVPBaseServiceContainer sharedContainer].camera = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    id<ACCCameraControlProtocol> cameraControl = IESAutoInline(self.serviveProvider, ACCCameraControlProtocol);
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        if (self.vcIsAppeared && cameraControl.status == IESMMCameraStatusStopped) {
            [cameraControl startVideoCapture];
        }
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    @weakify(self);
    [super dismissViewControllerAnimated:flag completion:^{
        @strongify(self);
        if (![MVPBaseServiceContainer sharedContainer].isExport) {
            self.dismissed = YES;
            [self.delegate cameraDidDismissFrom:self];
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    self.vcIsAppeared = YES;
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden: true];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [MVPBaseServiceContainer sharedContainer].isExport = NO; // 重置 isExport 属性
}

- (void)viewWillDisappear:(BOOL)animated {
    self.vcIsAppeared = NO;
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (![MVPBaseServiceContainer sharedContainer].isExport && !self.dismissed) {
        [LVDCameraMonitor logWithInfo:@"camera dismiss without export when dealloc" message:@""];
        [self.delegate cameraDidDismissFrom:self];
    }
    NSURL* documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSError* draftError;
    [[NSFileManager defaultManager] removeItemAtPath:[[documentURL path] stringByAppendingFormat:@"/drafts"] error:&draftError];
    if (draftError != NULL) {
        [LVDCameraMonitor logWithInfo:@"camera record remove drafts failed " message:[[NSString alloc] initWithFormat:@" error %@", draftError]];
    }

    NSString* cacheDirPath = [HTSVideoData cacheDirPath];

    NSDirectoryEnumerator* enumer = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirPath];
    for (NSString *path in enumer.allObjects) {
        // 这里只删除拍摄/剪辑过程中产生的文件
        if ([path hasPrefix:@"FragmentVideo_"] || [path hasPrefix:@"FinalVideo_"]) {
            NSError* error;
            NSString* fullPath = [NSString stringWithFormat:@"%@/%@", cacheDirPath, path];
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            if (error == NULL) {
                [LVDCameraMonitor logWithInfo:@"camera record remove ve cache success " message:[[NSString alloc] initWithFormat:@" path %@", fullPath]];
            } else {
                [LVDCameraMonitor logWithInfo:@"camera record remove ve cache failed " message:[[NSString alloc] initWithFormat:@" path %@ error %@", fullPath, error]];
            }
        }
    }
    [LVDCameraMonitor logWithInfo:@"camera record vc dealloc " message:[[NSString alloc] initWithFormat:@" path %@", cacheDirPath]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

@end
