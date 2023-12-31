//
//  TMAVideoContainer.h
//  OPPluginBiz
//
//  Created by tujinqiu on 2020/2/3.
//

#import <Foundation/Foundation.h>

@protocol TMAVideoContainerPlayerDelegate <NSObject>

@required
- (void)close;

@end

NS_ASSUME_NONNULL_BEGIN

@interface TMAVideoContainer : NSObject

+ (instancetype)sharedContainer;
- (void)addPlayer:(id<TMAVideoContainerPlayerDelegate>)player;
- (void)closeAll;

@end

NS_ASSUME_NONNULL_END
