//
//  TTVideoEngineThumbInfo.h
//  Pods
//
//  Created by guikunzhi on 2018/5/2.
//

#import "TTVideoEngineThumbInfo.h"
#import "TTVideoEngineModelPb.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineThumbInfo (Protobuf)

- (instancetype)initWithDictionaryPb:(TTVideoEnginePbBigThumb *)bigThumb;

@end

NS_ASSUME_NONNULL_END
