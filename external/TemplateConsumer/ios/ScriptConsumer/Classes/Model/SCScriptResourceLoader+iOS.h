//
//   SCScriptResourceLoader+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/6/22.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEResourceNode+iOS.h>
#import "SCScriptModel+iOS.h"

NS_ASSUME_NONNULL_BEGIN

///下载器注入类型
typedef enum : NSUInteger {
    SCDownLoadTypeNone,
    SCDownLoadTypeEffect, //目前特效，滤镜归纳为一类
    SCDownLoadTypeMusic, //音乐
    SCDownLoadTypeVideo, //视频
    SCDownLoadTypeFile, //文件
    SCDownLoadTypeTransition, //转场
    SCDownLoadTypeStickerText, ///文字字幕、贴纸
} SCDownLoadType;

typedef void(^SCScriptDownloaderHandler)(NSArray<NLEResourceNode_OC*>* __nonnull resourceNodeArray);

typedef void(^SCScriptSegmentDownloaderHandler)(NSArray<NLESegment_OC*>* __nonnull segmentArray);

@interface SCScriptResourceLoader_OC : NSObject

/// 触发所有资源下载
-(void)fetchResources:(SCScriptModel_OC*)scriptModel;

/// 注册下载代理
/// @param handler 下载器
/// @param type 下载类型
-(void)registerHandler:(SCScriptDownloaderHandler)handler forType:(SCDownLoadType)type;

/// 注册下载代理
/// @param handler 下载器
/// @param type 下载类型（目前仅支持SCDownLoadTypeTransition和SCDownLoadTypeStickerText）
-(void)registerSegmentHandler:(SCScriptSegmentDownloaderHandler)handler forType:(SCDownLoadType)type;


/// 移除下载代理
/// @param type 下载类型
-(void)unRegisterHandlerForType:(SCDownLoadType)type;

@end

NS_ASSUME_NONNULL_END
