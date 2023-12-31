//
//  BDWebImageRequestConfig.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/10/30.
//

#import <Foundation/Foundation.h>
#import "BDBaseTransformer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDWebImageRequestConfig : NSObject

@property (nonatomic, assign) CGSize size; // 指定图片加载后的大小
@property (nonatomic, assign) CFTimeInterval timeoutInterval; // 下载耗时超时间隔，超时会报超时错误
@property (nonatomic, nullable, copy) NSString *cacheName; //指定自定义缓存，需要先 register 对应 cacheName 的 cache
@property (nonatomic, nullable, strong) BDBaseTransformer *transformer; // 指定 transformer
@property (nonatomic, nullable, strong) id userInfo; // 指定业务方信息
@property (nonatomic, nullable, copy) NSString *sceneTag;
@property (nonatomic, assign) NSUInteger randomSamplingPointCount; ///< 随机采样解码后图片的像素个数，默认为30
@property (nonatomic, assign) NSUInteger transitionDuration;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *requestHeaders;   ///< 每个请求单独的 headers

@end

NS_ASSUME_NONNULL_END
