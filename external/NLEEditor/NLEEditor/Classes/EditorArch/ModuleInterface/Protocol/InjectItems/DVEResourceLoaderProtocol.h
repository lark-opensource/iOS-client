//
//   DVECoreResourceImp.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/14.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import "DVEResourceCategoryModelProtocol.h"
#import "DVEMusicResourceLoaderProtocol.h"
#if ENABLE_SUBTITLERECOGNIZE
#import "DVETextReaderModelProtocol.h"
#endif
#import "DVEResourceModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^DVEResourceCategoryLoadHandler)(NSArray<id<DVEResourceCategoryModelProtocol>>* _Nullable categorys,NSString* _Nullable errMsg);

typedef void (^DVEResourceModelLoadHandler)(NSArray<id<DVEResourceModelProtocol>>* _Nullable datas,NSString* _Nullable errMsg);


/// 协议中，所有接口都在非主线程被调用
@protocol DVEResourceLoaderProtocol <DVEMusicResourceLoaderProtocol>

@optional

//画布比例列表
- (void)canvasRatioModel:(DVEResourceModelLoadHandler)hander;
///调节资源列表
- (void)adjustModel:(DVEResourceModelLoadHandler)hander;
///入场动画资源列表
- (void)animationInModel:(DVEResourceModelLoadHandler)hander;
///出场动画资源列表
- (void)animationOutModel:(DVEResourceModelLoadHandler)hander;
///组合动画资源列表
- (void)animationCombinModel:(DVEResourceModelLoadHandler)hander;
///滤镜资源列表
- (void)filterModel:(DVEResourceModelLoadHandler)hander;

///音效资源列表
/// category里的models必须继承DVEResourceMusicModelImp协议
- (void)soundCategory:(void (^)(NSArray<id<DVEResourceMusicCategoryModelProtocol>> * _Nullable, NSString * _Nullable))hander;

///音效分类刷新数据，用于分页加载下拉刷新
/// @param category 现有分类数据
/// @param hander 刷新回调 （newData新数据,会被添加进category的models，原有models会被清空，触发本事件后，soundLoadMore事件会被重置可触发。error错误信息）
- (void)soundRefresh:(id<DVEResourceCategoryModelProtocol>)category handler:(void(^)(NSArray<id<DVEResourceMusicModelProtocol>>* _Nullable newData,NSString* _Nullable error))hander;

///音效乐分类加载更多数据，用于分页加载上拉更多
/// @param category 现有分类数据
/// @param hander 加载回调 （moreData新数据,会被追加进category的models，当moreData为空，则表示无更多数据，在触发下一次soundRefresh前，将不会再触发本事件。error错误信息）
- (void)soundLoadMore:(id<DVEResourceCategoryModelProtocol>)category handler:(void(^)(NSArray<id<DVEResourceMusicModelProtocol>>* _Nullable moreData,NSString* _Nullable error))hander;

///贴纸分类刷新数据
- (void)stickerModel:(DVEResourceModelLoadHandler)hander;

///文本对齐资源列表
- (void)textAlignModel:(DVEResourceModelLoadHandler)hander;
///文本字体资源列表
- (void)textFontModel:(DVEResourceModelLoadHandler)hander;
///文本颜色资源列表
- (void)textColorModel:(DVEResourceModelLoadHandler)hander;
///文本样式资源列表
- (void)textStyleModel:(DVEResourceModelLoadHandler)hander;
///文本动画资源列表
- (void)textAnimationModel:(DVEResourceModelLoadHandler)hander type:(DVEAnimationType)type;
///贴纸动画资源列表
- (void)stickerAnimationModel:(DVEResourceModelLoadHandler)hander type:(DVEAnimationType)type;
///动画资源列表
- (void)transitionModel:(DVEResourceModelLoadHandler)hander;
///合拍资源列表
- (void)duetModel:(DVEResourceModelLoadHandler)hander;
///蒙版资源列表
- (void)maskModel:(DVEResourceModelLoadHandler)hander;

///特效资源列表
- (void)effectCategory:(DVEResourceCategoryLoadHandler)hander;
///特效分类刷新数据
/// @param category 现有分类数据
/// @param hander 刷新回调
- (void)effectModel:(id<DVEResourceCategoryModelProtocol>)category handler:(DVEResourceModelLoadHandler)hander;

///花字资源列表
- (void)flowerTextModel:(DVEResourceModelLoadHandler)hander;
///文字气泡资源列表
- (void)textBubbleModel:(DVEResourceModelLoadHandler)hander;
///混合模式资源列表
- (void)mixedEffectModel:(DVEResourceModelLoadHandler)hander;

#if ENABLE_SUBTITLERECOGNIZE
/// 文本朗读效果了列表
/// @param handler DVEResourceModelLoadHandler
- (void)textReaderSoundEffectModel:(void(^)(NSArray<id<DVETextReaderModelProtocol>>* _Nullable newData, NSError* _Nullable error))handler;
#endif

/// 画布样式资源列表
- (void)canvasStyleResourceModel:(DVEResourceModelLoadHandler)handler;

/// 曲线变速资源列表
- (void)curveSpeedResourceModel:(DVEResourceModelLoadHandler)handler;

/// 文字模板资源列表
- (void)textTemplateCategory:(DVEResourceCategoryLoadHandler)hander;

/// 文字模板刷新数据
/// @param category 现有分类数据
/// @param hander 刷新回调
- (void)textTemplateModel:(id<DVEResourceCategoryModelProtocol>)category handler:(DVEResourceModelLoadHandler)hander;

///变声资源列表
- (void)audioChangModel:(DVEResourceModelLoadHandler)hander;

/// 轻剪辑滤镜分类
- (void)liteFilterCategory:(DVEResourceCategoryLoadHandler)hander;

/// 轻剪辑滤镜分类下的具体数据
/// @param category 现有分类数据
/// @param hander 刷新回调
- (void)liteFilterModel:(id<DVEResourceCategoryModelProtocol>)category
                handler:(DVEResourceModelLoadHandler)hander;

/// 轻剪辑美颜资源
- (void)liteBeautyModel:(DVEResourceModelLoadHandler)hander;

///轻剪辑表情贴纸列表
- (void)liteEmojiStickerModel:(DVEResourceModelLoadHandler)handler;


@end

NS_ASSUME_NONNULL_END
