//
//  TTVideoEnginePlayBaseSource.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import <Foundation/Foundation.h>
#import "TTVideoEnginePlaySource.h"
#import "TTVideoEngineInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEnginePlayBaseSource : NSObject<TTVideoEnginePlaySource>

@property (nonatomic, strong) id<TTVideoEngineNetClient> netClient;

@property (nonatomic, assign) BOOL cacheVideoModelEnable;

@property (nonatomic, assign) BOOL useFallbackApi;

@property (nonatomic, assign) BOOL useEphemeralSession;

/// Some project will get  TTVideoEngineInfoModel instance.
@property (nonatomic, strong, nullable) TTVideoEngineInfoModel *fetchData;

@end

NS_ASSUME_NONNULL_END
