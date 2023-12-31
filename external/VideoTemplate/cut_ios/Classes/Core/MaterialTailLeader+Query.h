//
//  MaterialTailLeader+Query.h
//  VideoTemplate
//
//  Created by ZhangYuanming on 2020/2/6.
//

#import <Foundation/Foundation.h>
#include <TemplateConsumer/CanvasConfig.h>
#include <TemplateConsumer/MaterialTailLeader.h>
#import "LVVEDataPackager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MaterialTailLeaderQuery : NSObject

+ (CGFloat)contentAnimationDuration;

+ (CGFloat)fitScaleWithCanvasConfig:(const CutSame::CanvasConfig &)canvasConfig;

+ (CGFloat)originLogoScale;

+ (NSDictionary *)contentTextParams:(NSString *)renderContent
                           fontPath:(NSString *)fontPath
                       fallbackList:(NSArray<NSString*>*)fallbackList;

+ (NSDictionary *)accountTextParams:(NSString *)renderContent
                           fontPath:(NSString *)fontPath
                       fallbackList:(NSArray<NSString*>*)fallbackList;

+ (CGFloat)uniformLogoCenterYOfCanvasSize:(CGSize)canvasSize
                                 logoSize:(CGSize)logoSize
                               videoScale:(CGFloat)videoScale
                        uniformTextHeight:(CGFloat)uniformTextHeight
                       uniformTextCenterY:(CGFloat)uniformTextHeight;

+ (CGFloat)uniformTextCenterYOfCanvasSize:(CGSize)canvasSize;

@end

NS_ASSUME_NONNULL_END
