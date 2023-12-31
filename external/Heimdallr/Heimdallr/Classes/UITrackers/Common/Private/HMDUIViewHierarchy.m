//
// Created by wangyinhui on 2021/6/7.
//

#import "HMDUserExceptionTracker.h"
#import "HMDUserExceptionParameter.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDUIViewHierarchy.h"
#import "HeimdallrUtilities.h"
#import "HMDDynamicCall.h"

NSUInteger maxFileCount = 10;
NSUInteger clearFileCount = 5;

@implementation HMDUIViewHierarchy {
}
+ (instancetype)shared {
    static HMDUIViewHierarchy *hmdVH = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmdVH = [[HMDUIViewHierarchy alloc] init];
        hmdVH.maxFileCount = maxFileCount;
        hmdVH.clearFileCount = clearFileCount;
    });
    return hmdVH;
}

+ (NSString *)getDescriptionForUI:(UIResponder *)responder{
    if (!responder){
        return @"";
    }
    if ([responder isKindOfClass:[UIViewController class]]){
        return responder.description;
    }
    NSString *description = [NSString stringWithFormat:@"<%@", [responder class]];
    if ([responder isKindOfClass:[UIView class]]){
        UIView *view = (UIView *)responder;
        NSString *frame = [NSString stringWithFormat:@"(%f %f; %f %f)", view.frame.origin.x,
                           view.frame.origin.y, view.frame.size.width, view.frame.size.height];
        NSString *bounds = [NSString stringWithFormat:@"(%f %f; %f %f)", view.bounds.origin.x,
                            view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height];
        description = [description stringByAppendingFormat:@" frame=%@; bounds=%@; alpha=%f; clipsToBounds=%i;",
                       frame, bounds, view.alpha, view.clipsToBounds];
        if (view.isHidden){
            description = [description stringByAppendingFormat:@" hidden=%i;", view.isHidden];
        }
        if (!view.opaque){
            description = [description stringByAppendingFormat:@" opaque=%i;", view.opaque];
        }
        if (!view.window){
            description = [description stringByAppendingFormat:@" isInWindow=%i;", NO];
        }
        if (view.backgroundColor){
            description = [description stringByAppendingFormat:@" backgroundColor=%@;", view.backgroundColor.description];
        }
        if (view.maskView){
            description = [description stringByAppendingFormat:@" maskView=(%@);", [HMDUIViewHierarchy getDescriptionForUI:view.maskView]];
        }
        if (view.layer){
            description = [description stringByAppendingFormat:@" layer=%@;", view.layer];
        }
        if (view.gestureRecognizers.count > 0){
            description = [description stringByAppendingFormat:@" gestureRecognizers.count=%ld;", view.gestureRecognizers.count];
        }
        if (!view.userInteractionEnabled) {
            description = [description stringByAppendingFormat:@" userInteractionEnabled=%i;", view.userInteractionEnabled];
        }
    }
    return [description stringByAppendingString:@">"];
}

- (void)updateConfigWithMaxFileCount:(NSUInteger)max clearFileCount:(NSUInteger)clear {
    if (max > 0) {
        _maxFileCount = max;
    }
    if (clear > 0) {
        _clearFileCount = clear;
    }
}

- (void)recordViewHierarchy:(NSDictionary *)vh {
    if (vh == nil){
        return;
    }
    NSString *rootDirPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"ViewHierarchy"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isEst = [manager fileExistsAtPath:rootDirPath];
    NSError *error = nil;
    if (!isEst) {
        BOOL rst = [manager createDirectoryAtPath:rootDirPath
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:&error];
        if (error || !rst) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] init directory failed with error %@", error);
            return;
        }
    }
    NSArray *fileList = [manager contentsOfDirectoryAtPath:rootDirPath error:&error];
    if (error) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] get file list failed with error %@", error);
        return;
    }
    NSArray *sortFileList = [fileList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];
    //如果视图栈数量超过最大存储数量，删除最老的
    if (sortFileList.count >= _maxFileCount) {
        for (int i = 0; i < sortFileList.count; ++i) {
            @autoreleasepool {
                if (i < _clearFileCount) {
                    NSString *filePath = [rootDirPath stringByAppendingPathComponent:sortFileList[i]];
                    BOOL isSuccess = [manager removeItemAtPath:filePath error:&error];
                    if (error || !isSuccess) {
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] remove old file failed with error %@", error);
                        return;
                    }
                }
            }
        }
    }

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%.0f", currentTime*1000];// *1000 是精确到毫秒，不乘就是精确到秒
    NSString *filePath = [rootDirPath stringByAppendingPathComponent:timeString];
    NSDictionary *data = @{
            @"timestamp": @(currentTime),
            @"view_hierarchy": vh,
    };
    if (@available(iOS 11.0, *)) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [data writeToURL:fileURL error:&error];
        if (error) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] write file failed with error %@", error);
            return;
        }
    } else {
        if (![data writeToFile:filePath atomically:YES]) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] write file failed");
            return;
        }
    }
}

- (void)uploadViewHierarchyIfNeedWithTitle:(NSString *)title subTitle:(NSString *)subTitle {
    NSString *rootDirPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"ViewHierarchy"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isEst = [manager fileExistsAtPath:rootDirPath isDirectory:&isDir];
    if (!isEst || !isDir) {
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[UITracker] directory is not exist");
        return;
    }
    NSError *error = nil;
    NSArray *fileList = [manager contentsOfDirectoryAtPath:rootDirPath error:&error];
    if (error) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] get file list failed with error %@", error);
        return;
    }
    if (fileList.count == 0) {
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[UITracker] there are no view hierarchy file");
        return;
    }
    for (NSString *fileName in fileList) {
        @autoreleasepool {
            NSDictionary *data = nil;
            NSString *filePath = [rootDirPath stringByAppendingPathComponent:fileName];
            if (@available(iOS 11.0, *)) {
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                data = [NSDictionary dictionaryWithContentsOfURL:fileURL error:nil];
            } else {
                data = [NSDictionary dictionaryWithContentsOfFile:filePath];
            }
            if (data && [data hmd_hasKey:@"view_hierarchy"] && [data hmd_hasKey:@"timestamp"]) {
                int record_timestamp = [data hmd_intForKey:@"timestamp"];
                HMDUserExceptionParameter *param = [HMDUserExceptionParameter initBaseParameterWithExceptionType:@"UIViewHierarchy" title:title subTitle:subTitle customParams:@{@"record_timestamp": @(record_timestamp)} filters:nil];
                param.viewHierarchy = [data hmd_dictForKey:@"view_hierarchy"];
                [[HMDUserExceptionTracker sharedTracker] trackBaseExceptionWithBacktraceParameter:param callback:^(NSError * _Nullable error) {
                                    if (error) {
                                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] upload user exception failed with error %@", error);
                                    }
                }];
            }
            BOOL isSuccess = [manager removeItemAtPath:filePath error:&error];
            if (error || !isSuccess) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UITracker] remove old file failed with error %@", error);
            }
        }
    }
}


- (NSDictionary *)getViewHierarchy:(UIView *)view superView:(UIView *)superView superVC:(UIViewController *)superVC
                        withDetail:(BOOL)need targetView:(UIView *)targetView {
    UIResponder *nextResponder = [view nextResponder];
    if (nextResponder &&
            nextResponder != superView &&
            nextResponder != superVC &&
            [nextResponder isKindOfClass:[UIViewController class]]) {
        NSMutableDictionary *viewNode = [self getViewControllerNode:(UIViewController *) nextResponder withDetail:need];

        NSDictionary *subNode = [self getViewHierarchy:view
                                             superView:superView
                                               superVC:(UIViewController *) nextResponder
                                            withDetail:need targetView:targetView];
        if (subNode != nil) {
            [viewNode setValue:@[subNode] forKey:@"subviews"];
        }
        return [viewNode copy];
    }
    NSMutableDictionary *viewNode = [self getViewNode:view withDetail:need targetView:targetView];
    NSMutableArray *subNodes = [NSMutableArray new];
    for (UIView *subView in view.subviews) {
        @autoreleasepool {
            [subNodes addObject:[self getViewHierarchy:subView superView:view superVC:superVC withDetail:need
                                            targetView:targetView]];
        }
    }
    if (subNodes != nil && subNodes.count > 0) {
        [viewNode setValue:subNodes forKey:@"subviews"];
    }
    return [viewNode copy];
}

- (NSMutableDictionary *)getViewNode:(UIView *)view withDetail:(BOOL)need targetView:(UIView *)targetView {
    NSMutableDictionary *viewNode = [NSMutableDictionary new];
    [viewNode setValue:[NSString stringWithFormat:@"%@", view.class] forKey:@"name"];
    SEL frameSEL = NSSelectorFromString(@"frame");
    if ([view respondsToSelector:frameSEL]) {
        NSString *frame = [NSString stringWithFormat:@"(%f %f; %f %f)", view.frame.origin.x,
                                                     view.frame.origin.y, view.frame.size.width, view.frame.size.height];
        [viewNode setValue:frame forKey:@"frame"];
    }
    [viewNode setValue:@(NO) forKey:@"is_view_controller"];
    if (targetView != nil && view == targetView) {
        [viewNode setValue:@(YES) forKey:@"is_target_view"];
    } else {
        [viewNode setValue:@(NO) forKey:@"is_target_view"];
    }
    if (need) {
        [viewNode setValue:[HMDUIViewHierarchy getDescriptionForUI:view] forKey:@"description"];
    }
    return viewNode;
}

- (NSMutableDictionary *)getViewControllerNode:(UIViewController *)vc withDetail:(BOOL)need {
    NSMutableDictionary *viewNode = [NSMutableDictionary new];
    [viewNode setValue:[NSString stringWithFormat:@"%@", vc.class] forKey:@"name"];
    SEL frameSEL = NSSelectorFromString(@"frame");
    if ([vc.view respondsToSelector:frameSEL]) {
        NSString *frame = [NSString stringWithFormat:@"(%f %f; %f %f)", vc.view.frame.origin.x,
                                                     vc.view.frame.origin.y, vc.view.frame.size.width, vc.view.frame.size.height];
        [viewNode setValue:frame forKey:@"frame"];
    }
    [viewNode setValue:@(YES) forKey:@"is_view_controller"];
    [viewNode setValue:@(NO) forKey:@"is_target_view"];
    if (need) {
        [viewNode setValue:[HMDUIViewHierarchy getDescriptionForUI:vc] forKey:@"description"];
    }
    return viewNode;
}
@end
