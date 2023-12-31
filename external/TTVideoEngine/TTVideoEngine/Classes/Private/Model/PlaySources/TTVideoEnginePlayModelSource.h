//
//  TTVideoEnginePlayModelSource.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/5/9.
//

#import "TTVideoEnginePlayVidSource.h"
#include "TTVideoEngineModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEnginePlayModelSource : TTVideoEnginePlayVidSource

@property (nonatomic, strong, nullable) TTVideoEngineModel *videoModel;

@end

NS_ASSUME_NONNULL_END
