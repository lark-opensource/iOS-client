//
//  NSURLRequest+WebviewInfo.h
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/12/22.
//
//  This file is used to avoid duplicated records of webview request by slardar
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (WebviewInfo)

//add a dictionary property for NSURLRequest parameter of requestForWebview method
@property (nonatomic, copy) NSDictionary *webviewInfo;

//add commonParams to webview request
@property (nonatomic, assign) BOOL needCommonParams;

@end

NS_ASSUME_NONNULL_END
