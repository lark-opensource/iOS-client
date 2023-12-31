//
//  BDPTimorClient+Private.h
//  Timor
//
//  Created by liubo on 2019/5/24.
//

#import "BDPTimorClient.h"

@interface BDPTimorClient (Private)

// 2019-7-25 解决用户重启小程序时，如果快速点击入口，造成的黑屏不能恢复的问题。
// 是否屏蔽openURL:接口
- (void)setEnableOpenURL:(BOOL)enabled;
- (BOOL)isOpenURLEnabled;

@end
