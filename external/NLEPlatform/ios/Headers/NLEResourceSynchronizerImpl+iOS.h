//
//  NLEResourceSynchronizerImpl+iOS.h
//  Pods
//
//  Created by bytedance on 2021/1/11.
//

#ifndef NLEResourceSynchronizerImpl_iOS_h
#define NLEResourceSynchronizerImpl_iOS_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceFetchCallbackImpl_OC : NSObject

- (void) onReourceId:(NSString *)resourceId success:(NSString*)file;

- (void) onError:(int32_t)error;

- (void) onProgress:(long)progress;

@end

@interface NLEResourceSynchronizerImpl_OC : NSObject

/**
 * @param resourceId 输入资源ID, Uri, URS .. 等等
 * @param callback 监听器
 * @return 错误码，0 表示成功发起请求
 */
- (int32_t) fetch:(NSString*)resourceId callback:(NLEResourceFetchCallbackImpl_OC*)callback;
/**
 * @param resourceFile 输入资源文件路径, Uri, URS .. 等等
 * @param callback 监听器
 * @return 错误码，0 表示成功发起请求
 */
- (int32_t) push:(NSString*)resourceFile callback:(NLEResourceFetchCallbackImpl_OC*)callback;


@end

NS_ASSUME_NONNULL_END


#endif /* NLEResourceSynchronizerImpl_iOS_h */
