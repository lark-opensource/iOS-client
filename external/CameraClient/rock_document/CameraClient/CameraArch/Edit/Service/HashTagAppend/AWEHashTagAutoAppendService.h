//
//  AWEHashTagAutoAppendService.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACCHashTagAppendService.h"

// ************************************************************************
// ***** IM STORY 模式在用 请勿再加任何代码，后面清理IM STORY的时候回一并清理掉 *****
// ************************************************************************


@class AWEVideoPublishViewModel;

@interface AWEHashTagAutoAppendService : NSObject <ACCHashTagAppendService>

//记录从videoRouter带过来的publishTitle。 比如合拍、reaction会带默认的title。在既不是草稿,也不是备份时使用
@property (nonatomic, strong) NSString *defaultTitleFromVideoRouter;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

//用于视频编辑页
- (void)appendHashTagIfNeededWithAppendPublishTitle:(NSMutableString *)publishTitle;
- (void)updatePublishTitleWithHashTagArray:(NSArray *)currentHashTagArray appendingPublishTitle:(NSMutableString *)publishTitle;
- (NSMutableString *)appendingPublishTitle;
- (NSMutableString *)appendingPublishTitleForSelectMusic;


@end

