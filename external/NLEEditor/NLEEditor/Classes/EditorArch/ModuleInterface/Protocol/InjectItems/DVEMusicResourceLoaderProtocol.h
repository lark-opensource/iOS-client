//
//   DVEMusicResourceLoaderProtocol.h
//   NLEEditor
//
//   Created  by ByteDance on 2021/11/25.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import "DVEResourceMusicModelProtocol.h"
#import "DVEResourceMusicCategoryModelProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@protocol DVEMusicResourceLoaderProtocol <NSObject>

@optional

///音乐资源列表
/// category里的models必须继承DVEResourceMusicModelImp协议
- (void)musicCategory:(void(^)(NSArray<id<DVEResourceMusicCategoryModelProtocol>>* _Nullable categorys,NSString* _Nullable errMsg))hander;

///音乐分类刷新数据，用于分页加载下拉刷新
/// @param category 现有分类数据
/// @param hander 刷新回调 （newData新数据,会被添加进category的models，原有models会被清空，触发本事件后，musicLoadMore事件会被重置可触发。error错误信息）
- (void)musicRefresh:(id<DVEResourceMusicCategoryModelProtocol>)category handler:(void(^)(NSArray<id<DVEResourceMusicModelProtocol>>* _Nullable newData,NSString* _Nullable error))hander;

///音乐分类加载更多数据，用于分页加载上拉更多
/// @param category 现有分类数据
/// @param hander 加载回调 （moreData新数据,会被追加进category的models，当moreData为空，则表示无更多数据，在触发下一次musicRefresh前，将不会再触发本事件。error错误信息）
- (void)musicLoadMore:(id<DVEResourceMusicCategoryModelProtocol>)category handler:(void(^)(NSArray<id<DVEResourceMusicModelProtocol>>* _Nullable moreData,NSString* _Nullable error))hander;


@end

NS_ASSUME_NONNULL_END
