//
//  ACCRecorderWrapper+Debug.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/6/6.
//

#if DEBUG || INHOUSE_TARGET

#import "ACCRecorderWrapper.h"

#import <CreativeKit/NSObject+ACCAdditions.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderWrapper (Debug)

@end

@interface ACCAcousticAlgorithmDebugger : NSObject

@property (nonatomic, assign) BOOL AECEnabled;
@property (nonatomic, assign) BOOL DAEnabled;
@property (nonatomic, assign) BOOL LEEnabled;
@property (nonatomic, assign) BOOL EBEnabled;
@property (nonatomic, assign) int lufs;
@property (nonatomic, assign) float delay;

@property (nonatomic, assign) VERecorderBackendMode backendMode;
@property (nonatomic, assign) BOOL useOutput;

@property (nonatomic, assign) BOOL forceRecordAudio;

+ (ACCAcousticAlgorithmDebugger *)sharedInstance;

@end

NS_ASSUME_NONNULL_END

#endif
