//
//  BDPSharePluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPSharePluginDelegate_h
#define BDPSharePluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPShareContext.h"

typedef NS_ENUM(NSInteger, BDPSharePluginResult) {
    BDPSharePluginResultSuccess,
    BDPSharePluginResultFailed,
    BDPSharePluginResultCancel,
};

/// shareTicketResponse -> {'shareScope':[], 'target',''} docs: https://bytedance.feishu.cn/space/doc/doccnFusJZkFZkC9PDLdS4#v5sLTb
typedef void (^BDPShareCompletion)(BDPSharePluginResult result, NSString *channel, NSError *error, NSDictionary *shareTicketResponse);

/**
 * 分享
 */
@protocol BDPSharePluginDelegate <BDPBasePluginDelegate>

/**
 * 显示分享面板
 *
 * @param context 要分享的信息的上下文。需要根据这个context和shareType 获取要分享的w信息
 * @param manager shareManager里面提供了获取分享信息的方法。
 * @param complete 分享完成的回调
 */
- (void)bdp_showShareBoardWithContext:(BDPShareContext *)context didComplete:(BDPShareCompletion)complete;

@end



#endif /* BDPSharePluginDelegate_h */
