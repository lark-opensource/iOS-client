//
//  NLEEditorManager.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/2/15.
//

#import "NLEEditorManager.h"
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLETrack+iOS.h>
#import <NLEEditor/DVEUIFactory.h>
#import <NLEEditor/DVEAlbumResourcePickerModel.h>
#import <NLEEditor/DVEServiceInjectionLocator.h>
#import <NLEEditor/DVEGlobalExternalInjectProtocol.h>
#import <NLEEditor/DVELiteViewController.h>
#import <NLEEditor/DVECoreExportServiceProtocol.h>
#import "MVPBaseServiceContainer.h"
#import "CameraRecordController.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "LVDEditorToastService.h"
#import "LVDEditorAlertService.h"
#import "LVDEditorLoadingService.h"
#import <TTVideoEditor/VEConfigCenter.h>
#import <DVEFoundationKit/DVEPadUIAdapter.h>

@interface PrivateDVELogger: NSObject<DVELoggerProtocol>
@end

@implementation PrivateDVELogger
- (void)logType:(DVELogType)type
            tag:(NSString *)tag
           file:(const char *)file
       function:(const char *)function
           line:(int)line
        message:(NSString *)message,... {
    NSString* info = [[NSString alloc] initWithFormat:@"type %d tag %@ function %s line %d", type, tag, function, line];
    NSMutableString* allMessage = [[NSMutableString alloc] initWithString: message];
    if (message) {
        va_list args;
        va_start(args, message);
        allMessage = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
    }
    [LVDCameraMonitor logWithInfo:info message:allMessage];
}

- (void)logEvent:(NSString *)serviceName
          params:(NSDictionary *)params {
    [LVDCameraMonitor trackNLE:serviceName params:params];
}
@end


@interface NLETrack_Mock: NSObject
@property (nonatomic, copy, readonly) NSArray<NLETrackSlot_OC *> *slots;
@end
@implementation NLETrack_Mock
@end

@interface NLEModel_Mock: NSObject
- (nullable NLETrack_Mock *)dve_getMainVideoTrack;
- (CMTime)getMaxTargetEndExcludeDisabledNode:(BOOL)excludeDisable;
@end
@implementation NLEModel_Mock
- (nullable NLETrack_Mock *)dve_getMainVideoTrack {
    return NULL;
}
- (CMTime)getMaxTargetEndExcludeDisabledNode:(BOOL)excludeDisable {
    return CMTimeMake(1, 1);
}
@end

@interface GlobalExternalInject: NSObject<DVEGlobalExternalInjectProtocol, DVEResourceManagerProtocol>
@end
@implementation GlobalExternalInject

- (NSBundle *)customResourceProvideBundle {
    return [LVDCameraI18N resourceBundle];
}

- (NSString*)covertStringWithKey:(NSString*)key {
    return [LVDCameraI18N getLocalizedStringWithKey:key defaultStr:nil];
}

/// 定制 Alert 提示框
- (id<DVEAlertProtocol>)provideAlert {
    return [[LVDEditorAlertService alloc] init];
}

/// 定制 Toast 提示
- (id<DVEToastProtocol>)provideToast {
    return [[LVDEditorToastService alloc] init];
}

/// 定制 Loading 提示
- (id<DVELoadingProtocol>)provideLoading {
    return [[LVDEditorLoadingService alloc] init];
}

/// 定制 logger
- (id<DVELoggerProtocol>)provideDVELogger {
    return [[PrivateDVELogger alloc] init];
}

@end

@implementation NLEEditorManager

+(UIViewController *)createDVEViewControllerWithAssets:(NSArray<AVAsset *> *)assets  from:(UIViewController *)controller {
     [VideoEditorManagerBridge setupVideoEditorIfNeeded];
    static dispatch_once_t onceRegisterToken;
    dispatch_once(&onceRegisterToken, ^{
        DVEGlobalServiceContainerRegister([GlobalExternalInject class]);
    });

    NSMutableArray<id<DVEResourcePickerModel>>* array = [[NSMutableArray alloc] init];
    for (AVAsset *asset in assets) {
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            DVEAlbumResourcePickerModel* model = [[DVEAlbumResourcePickerModel alloc] initWithURL:[(AVURLAsset*)asset URL]];
            [array addObject:model];
        }
    }
    UIViewController *editController = [DVEUIFactory createDVELiteViewControllerWithResources:array injectService:[MVPBaseServiceContainer sharedContainer]];
    [MVPBaseServiceContainer sharedContainer].editing = editController;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIWindow* window = [LVDCameraAlert currentWindowFrom:controller];
        [DVEPadUIAdapter dve_setIPadScreenWidth: window.frame.size.width];
        [DVEPadUIAdapter dve_setIPadScreenHeight: window.frame.size.height];
    }
    [editController.rac_willDeallocSignal subscribeCompleted:^{
        // 监听编辑页面释放
        [LVDCameraSession deactiveIfNeededWith:AVAudioSessionCategoryPlayback];
        [LVDCameraMonitor endPreviewPowerMonitor];
    }];
    [LVDCameraMonitor startPreviewPowerMonitor];
    return editController;
}

+(void)sendVideo:(MVPBaseServiceContainer *)c sender:(UIControl *)sender {
    DVELiteViewController* vc = c.editing;
    id<DVECoreExportServiceProtocol> exportService =
    IESAutoInline(vc.vcContext.serviceProvider,DVECoreExportServiceProtocol);
    [LVDCameraToast showLoadingWithMessage:[LVDCameraI18N getLocalizedStringWithKey:@"transCoding" defaultStr:nil] on: vc.view];
    [sender setEnabled:NO];
    id<DVECoreDraftServiceProtocol> draftService = IESAutoInline(vc.vcContext.serviceProvider,DVECoreDraftServiceProtocol);

    NLEModel_Mock *model = (NLEModel_Mock *)[DVEAutoInline(vc.vcContext.serviceProvider, DVENLEEditorProtocol) nleModel];
    CGFloat duration = floor(CMTimeGetSeconds([model getMaxTargetEndExcludeDisabledNode:YES]));
    NSUInteger segmentsCount = [[model dve_getMainVideoTrack].slots count];

    [LVDCameraMonitor logWithInfo:@"send NLE video start" message:[[NSString alloc] initWithFormat:@" duration %f segmentsCount %d", duration, segmentsCount]];
    @weakify(c);
    [exportService exportVideoWithProgress:^(CGFloat progress) {
    } resultBlock:^(NSError * _Nonnull error, NSURL * _Nonnull result) {
        [LVDCameraMonitor logWithInfo:@"send NLE video end" message:[[NSString alloc] initWithFormat:@" result %@ error %@", result, error]];
        @strongify(c);
        [LVDCameraToast dismissOn:vc.view];
        if (error != NULL) {
            [LVDCameraToast showFailedWithMessage:[LVDCameraI18N getLocalizedStringWithKey:@"transcode_failed" defaultStr:nil] on:vc.view];
            [sender setEnabled:YES];
            return;
        }
        if (result != NULL) {
            NSInteger randNumber = arc4random();
            NSString* cacheName = [NSString stringWithFormat:@"videoEditor-%ld-%f.mov", randNumber, [[NSDate date] timeIntervalSince1970]];
            // 调整导出视频缓存路径，避免被系统删除
            NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                       NSUserDomainMask, YES) firstObject];
            cachePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"VECamera"]];
            BOOL isDirectory;
            if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
                NSError *createDirectoryError;
                [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&createDirectoryError];
                if (createDirectoryError) {
                    [LVDCameraMonitor logWithInfo:@"createDirectory failed" message:[[NSString alloc] initWithFormat:@"path %@ error %@", cachePath, error]];
                }
            }
            NSString *exportPath = [cachePath stringByAppendingPathComponent: cacheName];
            NSURL* exportURL = [[NSURL alloc] initFileURLWithPath:exportPath];
            NSError* copyError;
            [[NSFileManager defaultManager] copyItemAtURL:result toURL:exportURL error:&copyError];
            if (copyError) {
                [LVDCameraMonitor logWithInfo:@"copy result failed" message:[[NSString alloc] initWithFormat:@"path %@ error %@", exportPath, error]];
                [LVDCameraToast showFailedWithMessage:[LVDCameraI18N getLocalizedStringWithKey:@"transcode_failed" defaultStr:nil] on:vc.view];
                [sender setEnabled:YES];
                return;
            }
            [LVDCameraMonitor trackNLE:@"public_video_edit_click" params:@{
                @"click": @"send",
                @"target": @"im_chat_main_view",
                @"duration": [[NSNumber alloc] initWithFloat:duration],
                @"segments": [[NSNumber alloc] initWithUnsignedInteger:segmentsCount]
            }];
            [LVDCameraMonitor logWithInfo:@"copy finish" message:[[NSString alloc] initWithFormat:@"path %@ exists %d", exportPath, [[NSFileManager defaultManager]  fileExistsAtPath:exportPath]]];
            if ([MVPBaseServiceContainer sharedContainer].inCamera) {
                UIViewController* controller = c.camera;
                if ([controller isKindOfClass: [CameraRecordController class]]) {
                    [MVPBaseServiceContainer sharedContainer].isExport = YES;
                    CameraRecordController* vc = controller;
                    [vc.delegate cameraTakeVideo:exportURL controller:c.editing];
                } else {
                    assert("vc type is wrong");
                }
            } else {
                UIViewController* controller = c.editing;
                [[MVPBaseServiceContainer sharedContainer].editorDelegate editorTakeVideo:exportURL controller:controller];
            }
            [draftService clearAllCache:NULL];
        }
    }];
}

@end
