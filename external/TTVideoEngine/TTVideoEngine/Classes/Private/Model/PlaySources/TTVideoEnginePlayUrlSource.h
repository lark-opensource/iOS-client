//
//  TTVideoEnginePlayUrlSource.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayBaseSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEnginePlayUrlSource : TTVideoEnginePlayBaseSource

@property (nonatomic, copy) NSString *url;

@property (nonatomic, copy) NSDictionary *mediaInfo;

+ (NSDictionary *)mediaInfo:(NSString *)videoId key:(NSString *)key urls:(NSArray *)urls;
@end


@interface TTVideoEnginePlayLocalSource : TTVideoEnginePlayUrlSource

@end

NS_ASSUME_NONNULL_END
