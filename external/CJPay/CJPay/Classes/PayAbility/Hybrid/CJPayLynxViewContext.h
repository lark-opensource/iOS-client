//
//  CJPayLynxViewContext.h
//  Aweme_xiaohong
//
//  Created by wangxiaohong on 2023/3/2.
//

#import <Foundation/Foundation.h>

#import "CJPayLynxViewPlugin.h"
#import <Puzzle/PuzzleHybridContainer.h>

NS_ASSUME_NONNULL_BEGIN

@class PuzzleHybridContainer;
@interface CJPayLynxViewContext : NSObject<IESHYHybridViewLifecycleProtocol>

@property (nonatomic, weak) PuzzleHybridContainer *lynxCardView;
@property (nonatomic, weak) id<CJPayLynxViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
