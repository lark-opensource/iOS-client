//
//  Header.h
//  Pods
//
//  Created by 杨阳 on 2019/3/28.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

//针对腾讯防打压的特殊情况，需要对第一排的分享项进行筛选并按需排序
@protocol BDUGShareBlockProtocol <NSObject>

@required

//宿主控制在分享前是否需要block分享过程。
- (BOOL)shouldBlockShareWithActivity:(id<BDUGActivityProtocol>)activity;
//业务可以在该回调中弹起pr弹窗，如果需要继续完成分享动作，需要手动调用continueBlock
- (void)didBlockShareWithActivity:(id<BDUGActivityProtocol>)activity continueBlock:(void(^)(void))block;

@end

NS_ASSUME_NONNULL_END
