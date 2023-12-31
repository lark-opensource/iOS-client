//
//  CoreJsLoaderManager.h
//  Pods
//
//  Created by admin on 2020/8/28.
//

#ifndef DARWIN_COMMON_LYNX_COREJSLOADERMANAGER_H_
#define DARWIN_COMMON_LYNX_COREJSLOADERMANAGER_H_

#import <Foundation/Foundation.h>

@protocol ICoreJsLoader <NSObject>

- (BOOL)jsCoreUpdate;
- (void)checkUpdate;
- (NSString *_Nullable)getCoreJs;

@end

@interface CoreJsLoaderManager : NSObject

@property(nonatomic, nullable) id<ICoreJsLoader> loader;

+ (instancetype _Nonnull)shareInstance;

@end

#endif  // DARWIN_COMMON_LYNX_COREJSLOADERMANAGER_H_
