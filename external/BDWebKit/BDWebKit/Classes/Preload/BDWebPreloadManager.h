//
//  BDWebPreloadManager.h
//  BDWebKit
//
//  Created by li keliang on 2020/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BDWebPreloadManager;

typedef NS_ENUM(NSUInteger, BDWebPreloadStatus) {
    BDWebPreloadStatusSucceed = 0,
    BDWebPreloadStatusFailed,
    BDWebPreloadStatusCancel
};

@interface BDWebPreloadResource : NSObject

@property (nonatomic, copy) NSString *href;
@property (nonatomic, copy) NSString *type;

+ (instancetype)resourceWithHref:(NSString *)href type:(NSString *)type;

@end

@protocol BDWebPreloadManagerObserver <NSObject>

@optional
- (void)preloadManager:(BDWebPreloadManager *)manager didFinishPreloadHref:(NSString *)href baseURL:(NSURL *)URL status:(BDWebPreloadStatus)status;

@end

@interface BDWebPreloadManager : NSObject

+ (instancetype)sharedManager;

- (void)addPreloadObserver:(id<BDWebPreloadManagerObserver>)observer;

- (void)preloadResources:(NSArray<BDWebPreloadResource *> *)resources baseURL:(NSURL *)URL;

- (void)stopPreload;

@end

NS_ASSUME_NONNULL_END
