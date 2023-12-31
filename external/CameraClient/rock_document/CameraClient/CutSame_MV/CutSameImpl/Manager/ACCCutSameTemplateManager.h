//
//  ACCCutSameTemplateManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

#import <VideoTemplate/LVTemplateDataManager.h>
#import <VideoTemplate/LVTemplateProcessor.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameTemplateManagerCompletion)(id<ACCMVTemplateModelProtocol> model, NSError *error);

@protocol ACCCutSameTemplateManagerDelegate <NSObject>

@optional
// mv模板开始下载回调
- (void)didStartDownloadTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel;

// mv模板下载进度
- (void)didDownloadAndProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                                  progress:(CGFloat)progress;
// mv模板下载成功回调
- (void)didFinishDownloadTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel;

// mv模板失败回调，可能是下载或处理失败
- (void)didFailTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                   withError:(NSError *)error;

// 剪同款模板专用，处理完成的回调
- (void)didFinishedProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                            dataManager:(LVTemplateDataManager *)dataManager
                              withError:(NSError *)error;

@end

@interface ACCCutSameTemplateManager : NSObject

+ (instancetype)sharedManager;

- (void)addDelegate:(id<ACCCutSameTemplateManagerDelegate>)delegate;

- (void)removeDelegate:(id<ACCCutSameTemplateManagerDelegate>)delegate;

- (LVTemplateProcessor *)downloadTemplateFromModel:(id<ACCMVTemplateModelProtocol>)model;

- (void)cancelDownloadAndProcessTemplateFromModel:(id<ACCMVTemplateModelProtocol>)model;

- (void)clearAllTemplateDraft;

- (void)clearAllTemplateCache;

@end

NS_ASSUME_NONNULL_END
