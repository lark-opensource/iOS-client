//
//  ACCAutoCaptionViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import <Foundation/Foundation.h>
#import "AWEStudioCaptionsManager.h"
#import "ACCAutoCaptionServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCAutoCaptionViewModel : NSObject<ACCAutoCaptionServiceProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) AWEStudioCaptionsManager *captionManager;
@property (nonatomic, assign) BOOL isCaptionAction; //标示编辑页dismiss是否由点击字幕按钮引发

@end

NS_ASSUME_NONNULL_END
