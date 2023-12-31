//
//  BDPLocalFileManager.h
//  Timor
//
//  Created by liubo on 2018/11/15.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPSandboxProtocol.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPLocalFileInfo.h>
#import <OPFoundation/BDPLocalFileConst.h>
#import <OPFoundation/BDPLocalFileManagerProtocol.h>
#import <OPFoundation/BDPModuleEngineType.h>

#pragma mark - BDPLocalFileManager

NS_ASSUME_NONNULL_BEGIN

@interface BDPLocalFileManager : NSObject <BDPLocalFileManagerProtocol>

- (instancetype)initWithType:(BDPType)type accountToken:(NSString *)accountToken;

@end

NS_ASSUME_NONNULL_END
