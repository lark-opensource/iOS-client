//
//  LVPreprocessManager.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ResourceDownloadDomain;
extern NSString *const ReverseVideoDomain;

@class LVPreprocessManager;
@class LVTemplateDataManager;

@protocol LVPreprocessManagerDelegate <NSObject>

@optional
- (void)preprocessManagerWillBeginPreprocessing:(LVPreprocessManager *)manager;

- (void)preprocessManager:(LVPreprocessManager *)manager didChangeProgress:(CGFloat)progress;

- (void)preprocessManager:(LVPreprocessManager *)manager didFailWithError:(NSError *)error;

- (void)preprocessManagerDidComplete:(LVPreprocessManager *)manager;

@end

typedef void(^LVPreprocessCallback)(BOOL success, NSError * _Nullable error);

@interface LVPreprocessManager : NSObject

@property (nonatomic, weak) id<LVPreprocessManagerDelegate>delegate;

- (instancetype)initWithDataManager:(LVTemplateDataManager *)dataManager;

- (void)preprocess;

- (void)preprocessWithCallback:(nullable LVPreprocessCallback)callback;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
