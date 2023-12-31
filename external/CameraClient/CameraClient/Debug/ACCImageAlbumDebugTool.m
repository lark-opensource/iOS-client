//
//  ACCImageAlbumDebugTool.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/9/10.
//

#if DEBUG || INHOUSE_TARGET

#import "ACCImageAlbumDebugTool.h"
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <CreativeKit/NSObject+ACCAdditions.h>
#import "ACCConfigKeyDefines.h"
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumSessionPlayerViewModel.h"
#import <CreativeKit/ACCMonitorToolProtocol.h>

static NSInteger kImageEditorCount_debug = 0;
static NSString *kImageViewModelDebugLogString;

@implementation ACCImageAlbumEditor (AlbumDebug)

AWELazyRegisterPremainClassCategory(ACCImageAlbumEditor, AlbumDebug)
{
    [self acc_swizzleInstanceMethod:@selector(onDidCreat) with:@selector(acc_debug_onDidCreat)];
    
    [self acc_swizzleInstanceMethod:@selector(onWillDestroy) with:@selector(acc_debug_onWillDestroy)];
}

- (void)acc_debug_onDidCreat
{
    kImageEditorCount_debug ++;
    [self acc_debug_onDidCreat];
    [ACCImageAlbumDebugTool updateDebugInfo];
}

- (void)acc_debug_onWillDestroy
{
    kImageEditorCount_debug --;
    [self acc_debug_onWillDestroy];
    [ACCImageAlbumDebugTool updateDebugInfo];
}

@end


@implementation ACCImageAlbumSessionPlayerViewModel (AlbumDebug)

AWELazyRegisterPremainClassCategory(ACCImageAlbumSessionPlayerViewModel, AlbumDebug)
{
    [self acc_swizzleInstanceMethod:@selector(onDebugInfoLogChanged:) with:@selector(acc_onDebugInfoLogChanged:)];
    
    [self acc_swizzleInstanceMethod:@selector(debugCheckPreloadIndex:currentIndex:itemCount:) with:@selector(acc_onDebug_debugCheckPreloadIndex:currentIndex:itemCount:)];
}

- (void)acc_onDebugInfoLogChanged:(NSString *)logString
{
    kImageViewModelDebugLogString = logString;
    [self acc_onDebugInfoLogChanged:logString];
    [ACCImageAlbumDebugTool updateDebugInfo];
}

- (void)acc_onDebug_debugCheckPreloadIndex:(NSArray <NSNumber *> *)indexs
                              currentIndex:(NSInteger)currentIndex
                                 itemCount:(NSInteger)itemCount
{
    [self acc_onDebug_debugCheckPreloadIndex:indexs currentIndex:currentIndex itemCount:itemCount];
    
    if (!ACCConfigBool(kConfigBool_enable_image_album_debug_tool)) {
        return;
    }
    
    BOOL indexsNotContainerCurrent = !([indexs containsObject:@(currentIndex)]);
    BOOL indexRepeted = [NSSet setWithArray:indexs?:@[]].count != indexs.count;
    __block BOOL hasOverBounceIndex = NO;
    [[indexs copy] enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.integerValue < 0 || obj.integerValue >= itemCount) {
            hasOverBounceIndex = YES;
            *stop = YES;
        }
    }];
    NSInteger minIndexCount = MIN(3, itemCount);
    BOOL isIndexsCountLoss = indexs.count < minIndexCount;

    if (indexsNotContainerCurrent || indexRepeted || hasOverBounceIndex) {
        
        NSString *log = [NSString stringWithFormat:@"预加载计算有些问题\n indexs:%@\ncurrentIndex:%@\nitemCount:%@\nindexsNotContainerCurrent:%@\nisIndexsCountLoss:%@\nindexRepeted:%@\nhasOverBounceIndex:%@\n",[indexs componentsJoinedByString:@"、"],@(currentIndex),@(itemCount),@(indexsNotContainerCurrent),@(isIndexsCountLoss),@(indexRepeted), @(hasOverBounceIndex)];
        
        [ACCMonitorTool() showWithTitle:log
                                  error:nil
                                  extra:@{@"tag": @"imagealbum-preload"}
                                  owner:@"qiuhang"
                                options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
    }
}

@end

@implementation ACCImageAlbumDebugTool

+ (void)updateDebugInfo
{
    if (!ACCConfigBool(kConfigBool_enable_image_album_debug_tool)) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        static dispatch_once_t onceToken;
        static UILabel *itemCountLabel = nil;
        dispatch_once(&onceToken, ^{
            itemCountLabel = [UILabel new];
        });
        
        NSString *debugString = [NSString stringWithFormat:@"--图集DEBUG--\nVE实例:%@\n%@", @(kImageEditorCount_debug), kImageViewModelDebugLogString?:@""];
        
        itemCountLabel.backgroundColor = [UIColor redColor];
        itemCountLabel.font = [UIFont systemFontOfSize:8];
        itemCountLabel.numberOfLines = 0;
        itemCountLabel.textColor = [UIColor whiteColor];
        itemCountLabel.text = debugString;
        [itemCountLabel sizeToFit];
        itemCountLabel.alpha = 0.5;
        itemCountLabel.frame = CGRectMake(10, 120, itemCountLabel.frame.size.width, itemCountLabel.frame.size.height);
        [itemCountLabel removeFromSuperview];
        [[UIApplication sharedApplication].delegate.window addSubview:itemCountLabel];
        
        if (kImageEditorCount_debug > 2) {
            
            [ACCMonitorTool() showWithTitle:[NSString stringWithFormat:@"图集VE实例似乎有点多了，重构后预期最多2个(编辑一个，发布一个)\n当前%@个",@(kImageEditorCount_debug)]
                                      error:nil
                                      extra:@{@"tag": @"imagealbum-ve-count"}
                                      owner:@"qiuhang"
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
        }
        
        
    });

}

@end

#endif
