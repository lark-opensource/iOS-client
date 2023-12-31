//
//  TSPKUserInputBasePipeline.h
//  Musically
//
//  Created by ByteDance on 2022/12/30.
//

#import <Foundation/Foundation.h>
#import "TSPKDetectPipeline.h"

@interface TSPKUserInputBasePipeline : TSPKDetectPipeline

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api className:(NSString *_Nullable)className text:(NSString *_Nullable)text;

@end

