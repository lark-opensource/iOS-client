//
//   DVEResourceMusicModelProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/19.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVEResourceModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@protocol DVEResourceMusicModelProtocol <DVEResourceModelProtocol>

@property (nonatomic, copy) NSString *singer;

@property (nonatomic, assign) NSTimeInterval duration;

/// 展示点击View
/// @param currentView 已有的View
-(UIView*)actionView:(UIView*)currentView;


@end

NS_ASSUME_NONNULL_END
