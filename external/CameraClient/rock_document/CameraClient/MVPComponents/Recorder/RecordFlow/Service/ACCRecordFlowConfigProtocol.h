//
//  ACCRecordFlowConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/12/2.
//

#ifndef ACCRecordFlowConfigProtocol_h
#define ACCRecordFlowConfigProtocol_h

@protocol ACCRecordFlowConfigProtocol <NSObject>

// story
- (BOOL)enableLightningStyleRecordButton;

// IM
- (BOOL)enableTapToTakePictureRecordMode:(BOOL)isStoryMode;

//
- (BOOL)needJumpDirectlyAfterTakePicture;

@end

#endif /* ACCRecordFlowConfigProtocol_h */
