//
//  BDWebViewDetectBlankContent.h
//  BDWebKit
//
//  Created by 杨牧白 on 2020/3/13.
//

#import <Foundation/Foundation.h>
#import "BDWebKitUtil+BlankDetect.h"

typedef NS_ENUM(NSInteger, BDDetectBlankStatus)
{
    eBDDetectBlankStatusImageError = 1,   //旧的检测接口，生成图片失败
    eBDDetectBlankStatusNewAPIError ,     //新的检测接口，API返回失败
    eBDDetectBlankUnsupportError,         //不支持检测，UI或WKiOS11以下 needOldSapshotDetect设置强制不检测，直接返回NO
    eBDDetectBlankStatusSuccess = 100,
};

typedef NS_ENUM(NSInteger, BDDetectBlankMethod)
{
    eBDDetectBlankMethodNew = 0, // 新方法
    eBDDetectBlankMethodOld , // 旧方法
};

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebViewBlankDetectListenerDelegate <NSObject>

- (void)onDetectResult:(UIView *)view isBlank:(BOOL)isBlank detectType:(BDDetectBlankMethod)detectType detectImage:(UIImage *)image error:(NSError *)error costTime:(NSInteger)costTime;

@end

@interface BDWebViewBlankDetect : NSObject

/// WKWebView 白屏检测方案，效率更高（推荐）
/// @param wkWebview 被检测的WKWebView
/// @param block 返回检测结果
+ (void)detectBlankByNewSnapshotWithWKWebView:(WKWebView *)wkWebview CompleteBlock:(void(^)(BOOL isBlank, UIImage *image, NSError *error)) block;

/// 通用白屏检测方案
/// @param view 被检测的View
/// @param block 返回检测结果
+ (void)detectBlankByOldSnapshotWithView:(UIView *)view CompleteBlock:(void(^)(BOOL isBlank, UIImage *image, NSError *error)) block;

/// 添加白屏检测结果的统一监听者
/// @param monitorListener 监听者
+ (void)addBlankDetectMonitorListener:(id<BDWebViewBlankDetectListenerDelegate>)monitorListener;

@end

NS_ASSUME_NONNULL_END
