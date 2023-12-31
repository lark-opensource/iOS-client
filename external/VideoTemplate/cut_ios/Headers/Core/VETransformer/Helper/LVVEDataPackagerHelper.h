//
//  LVVEDataPackagerHelper.h
//  VideoTemplate
//
//  Created by Lemonior on 2020/4/20.
//

#import <Foundation/Foundation.h>

@class IESMMCanvasConfig;
@class LVDraftCanvasPayload;
@class IESMMCanvasSource;
@class LVSegmentClipInfo;
@class LVMediaDraft;
@class TransformTextureVertices;
@class LVVideoCropInfo;
@class LVCanvasConfig;

@interface LVVEDataPackagerHelper : NSObject

+ (IESMMCanvasConfig *)canvasConfigForCanvasMaterial:(LVDraftCanvasPayload *)canvasPayload
                                            rootPath:(NSString *)rootPath;

+ (void)updateCanvasSource:(IESMMCanvasSource *)source
                  fromClip:(LVSegmentClipInfo *)clip
                 cropScale:(float)cropScale;

+ (NSString *)filePathInDraft:(LVMediaDraft *)draft
                  relativePath:(NSString *)relativePath;

+ (TransformTextureVertices *)verticesForCrop:(LVVideoCropInfo *)crop;

+ (CGFloat)contentAnimationDuration;
+ (CGFloat)fitScaleWithCanvasConfig:(LVCanvasConfig *)canvasConfig;
+ (CGFloat)originLogoScale;

@end
