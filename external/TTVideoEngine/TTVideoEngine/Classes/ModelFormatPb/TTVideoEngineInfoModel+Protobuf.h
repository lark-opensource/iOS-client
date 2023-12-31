//
//  TTVideoInfoModel.h
//  Article
//
//  Created by Dai Dongpeng on 6/2/16.
//
//

#import "TTVideoEngineInfoModel.h"
#import "TTVideoEngineThumbInfo+Protobuf.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineURLInfo (Protobuf)

- (instancetype)initVideoInfoWithPb:(TTVideoEnginePbVideo* )video;

- (instancetype)initAudioInfoWithPb:(TTVideoEnginePbAudio* )audio;

- (NSDictionary *)getVideoInfo;

@end

@interface TTVideoEngineURLInfoMap (Protobuf)

- (instancetype)initVideoListWithPb:(NSMutableArray<TTVideoEnginePbVideo*> *)video_list;

@end

@interface TTVideoEngineDynamicVideo (Protobuf)

- (instancetype)initDynamicVideoWithPb:(TTVideoEnginePbDynamicVideo*)dynamicVideo;

@end

@interface TTVideoEngineSeekTS (Protobuf)

- (instancetype)initSeekOffSetWithPb:(TTVideoEnginePbSeekOffSet *)seekOffSet;

@end

@interface TTVideoEngineInfoModel (Protobuf)

- (instancetype)initVideoInfoWithPb:(NSData * )data;

- (void)getRefStringWithPb:(TTVideoEnginePbDynamicVideo *)dynamicVideo;

@end

NS_ASSUME_NONNULL_END
