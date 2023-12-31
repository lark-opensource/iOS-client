//
//  LVResourceRequest.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/15.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^LVResourceRequestCallback)(NSString *resourceID, NSString *resourcePath);

@class LVResourceRequest;
@protocol LVResourceRequestDelegate <NSObject>

- (void)resourceRequest:(LVResourceRequest*)request md5:(NSString *)resourceMD5;

@end

@interface LVResourceRequest : NSObject

/**
 资源唯一标识
 */
@property (nonatomic, copy) NSString *resourceID;

/**
 资源分类ID
 */
@property (nonatomic, copy, nullable) NSString *categoryID;

/**
 资源分类名称
 */
@property (nonatomic, copy, nullable) NSString *categoryName;

/**
 资源具体类型
 */
@property (nonatomic, assign) LVPayloadRealType realType;

/**
 资源大类型
 */
@property (nonatomic, assign) LVPayloadRealType type;

/**
 请求回调
 */
@property (nonatomic, copy, nullable) LVResourceRequestCallback callback;

/**
 delegate
 资源存储路径发生变化 回调外部更新
 */
@property (nonatomic, weak) id <LVResourceRequestDelegate> _Nullable delegate;

/**
 缓存路径
 */
@property (nonatomic, copy) NSString *cachePath;

- (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
