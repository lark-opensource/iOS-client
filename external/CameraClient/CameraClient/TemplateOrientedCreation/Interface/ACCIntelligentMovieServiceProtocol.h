//
//  ACCIntelligentMovieServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#ifndef ACCIntelligentMovieServiceProtocol_h
#define ACCIntelligentMovieServiceProtocol_h

@protocol ACCIntelligentMovieServiceProtocol <NSObject>

@optional

// 视频抽帧间隔
- (NSInteger)movieFrameGeneratorFPS;

@end

#endif /* ACCIntelligentMovieServiceProtocol_h */
