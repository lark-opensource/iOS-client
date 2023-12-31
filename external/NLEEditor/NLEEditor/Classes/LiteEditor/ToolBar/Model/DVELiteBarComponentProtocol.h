//
//  DVELiteBarComponentProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/5.
//

#import <Foundation/Foundation.h>
#import "DVEBarComponentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^DVEBarItemActionBlock)(UIView *itemView);

@protocol DVELiteBarComponentProtocol <DVECommonBarComponentProtocol>

/// 点击事件响应 Block（For Lite Only）
@property (nonatomic, copy) DVEBarItemActionBlock actionBlock;

@end

NS_ASSUME_NONNULL_END
