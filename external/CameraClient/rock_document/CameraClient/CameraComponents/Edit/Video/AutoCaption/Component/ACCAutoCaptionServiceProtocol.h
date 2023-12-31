//
//  ACCAutoCaptionServiceProtocol.h
//  CameraClient
//
//  Created by raomengyun on 2020/12/29.
//

#ifndef ACCAutoCaptionServiceProtocol_h
#define ACCAutoCaptionServiceProtocol_h

@protocol ACCAutoCaptionServiceProtocol <NSObject>

// 是否正在编辑自动字幕
@property (nonatomic, assign, readonly) BOOL isCaptionAction;

@end

#endif /* ACCAutoCaptionServiceProtocol_h */
