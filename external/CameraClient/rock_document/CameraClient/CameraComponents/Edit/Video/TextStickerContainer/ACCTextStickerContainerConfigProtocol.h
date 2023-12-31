//
//  ACCTextStickerContainerConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 吴珂 on 2021/2/28.
//  


#import <Foundation/Foundation.h>
@class AWEVideoPublishViewModel;
NS_ASSUME_NONNULL_BEGIN

#define IESAutoInlineACCTextStickerService IESAutoInline(ACCBaseServiceProvider(), ACCTextStickerContainerConfigProtocol)

@protocol
ACCTextStickerContainerConfigProtocol <NSObject>

- (BOOL)shouldShowTextStickerBubble:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
