//
//  HMDHTTPRequestInfo.h
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/3.
//

#import <Foundation/Foundation.h>


@interface HMDHTTPRequestInfo : NSObject

@property (nonatomic, copy, nullable) NSString *requestID;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSUInteger hasTriedTimes;
@property (nonatomic, copy, nullable) NSString *requestScene;

// webview 相关信息
@property (nonatomic, copy, nullable) NSString *webviewURL;
@property (nonatomic, copy, nullable) NSString *webviewChannel;

@end

