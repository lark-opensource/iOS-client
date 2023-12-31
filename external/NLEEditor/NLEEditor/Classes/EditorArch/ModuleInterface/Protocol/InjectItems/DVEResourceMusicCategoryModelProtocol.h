//
//   DVEResourceMusicCategoryModelProtocol.h
//   NLEEditor
//
//   Created  by ByteDance on 2021/11/12.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVEResourceCategoryModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEResourceMusicCategoryModelProtocol <DVEResourceCategoryModelProtocol>

///模型列表
@property(nonatomic,copy)NSArray<id<DVEResourceMusicModelProtocol>>* models;
/// 查询条件
@property(nonatomic,copy)NSString* queryKey;
/// 是否加载更多
@property(nonatomic,assign)BOOL hasMore;

/// 导入音乐标题，如果返回nil则不展示导入按钮
-(NSString*)importMusicTitle;

/// 没有音乐提示语
-(NSString*)emptyMusicText;

/// 导入音乐
/// @param url  音乐路径
/// @param title 标题
/// @param singer 歌手
- (id<DVEResourceMusicModelProtocol>)importMusicWithIdentifier:(NSString*)identifier url:(NSString*)url title:(NSString*)title duration:(NSTimeInterval)duration singer:(NSString*)singer;

/// 是否支持搜索
- (BOOL)supportSearch;

@end

NS_ASSUME_NONNULL_END
