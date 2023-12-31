//
//  GamePlayManager.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "GPMaterialModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface GamePlayManager : NSObject

// process pic for ComicFace template in CutSame
- (void)processForCutSameWithResourceModels:(NSArray<GPMaterialModel *> *)resourcesModels
                                 completion:(void (^)(NSArray<GPMaterialOutputModel *> *))completionBlock;

@end

NS_ASSUME_NONNULL_END
