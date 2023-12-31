//
//  DVELiteExportHelper.h
//  NLEEditor
//
//  Created by Lincoln on 2022/3/7.
//

#import <Foundation/Foundation.h>
#import "DVEVCContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteExportHelper : NSObject

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext;

- (void)setupExportBlock;

- (void)adaptFullSceneVideo;

@end

NS_ASSUME_NONNULL_END
