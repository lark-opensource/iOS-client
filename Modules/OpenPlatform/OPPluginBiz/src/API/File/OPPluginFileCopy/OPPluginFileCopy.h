//
//  OPPluginFileCopy.h
//  OPPluginBiz
//
//  Created by yin on 2018/9/4.
//

#import <OPFoundation/BDPUniqueID.h>

@interface OPPluginFileCopy : NSObject

+ (NSString * _Nullable)copyFileFromPath:(NSString * _Nullable)sourcePath uniqueID:(BDPUniqueID * _Nullable)uniqueID;

+ (NSDictionary * _Nullable)copyFileFromUrl:(NSURL * _Nullable)url uniqueID:(BDPUniqueID * _Nullable)uniqueID;

@end
