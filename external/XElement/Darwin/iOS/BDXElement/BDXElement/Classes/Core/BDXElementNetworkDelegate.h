//
//  BDXElementNetworkDelegate.h
//  BDXElement-Pods-Aweme
//
//  Created by zhoumin.zoe on 2020/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LynxRequestCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

typedef void (^LynxDownloadCompletionHandler)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

@protocol BDXElementNetworkDelegate <NSObject>

- (NSString *)networkTypeString;
@optional
- (void)requestForBinaryWithResponse:(NSString *)URL
                        completionHandler:(LynxRequestCompletionHandler)completionHandler;
- (void)downloadTaskWithRequest:(NSString *)URL
                        targetPath:(NSString *)targetPath
                        completionHandler:(LynxDownloadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
