//
//  BDPCommon.m
//  TTHelium
//
//  Created by CsoWhy on 2018/10/14.
//

#import "BDPCommon.h"
#import <ECOInfra/BDPFileSystemHelper.h>
#import <ECOInfra/BDPLog.h>
#import "BDPModuleManager.h"
#import "BDPSettingsManager+BDPExtension.h"
#import "BDPStorageModuleProtocol.h"
#import "BDPTracker.h"
#import "BDPVersionManager.h"
#import "BDPTracingManager.h"
#import <ECOInfra/ECOInfra-Swift.h>

@implementation BDPCommon

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithModel:(BDPModel *)model schema:(BDPSchema *)schema
{
    self = [super init];
    if (self) {
        _model = model;
        _uniqueID = model.uniqueID;
        
        _schema = schema;
        _coldBootSchema = [schema copy];
        _sandbox = [BDPGetResolvedModule(BDPStorageModuleProtocol, _uniqueID.appType) createSandboxWithUniqueID:model.uniqueID pkgName:model.pkgName];
        [_sandbox clearTmpPath];
        [_sandbox clearPrivateTmpPath];
        _auth = [[BDPAuthorization alloc] initWithAuthDataSource:model storage:_sandbox.privateStorage];
        
        _sdkVersion = [BDPVersionManager localLibBaseVersionString];
        _sdkUpdateVersion = [BDPVersionManager localLibVersionString];
        
        _isActive = NO;
        _isReady = NO;
        _isDestroyed = NO;
        
        [self setSchema:schema];
    }
    return self;
}

- (instancetype)initWithSchema:(BDPSchema *)schema uniqueID:(BDPUniqueID *)uniqueID
{
    self = [super init];
    if (self) {
        _uniqueID = uniqueID;
        
        _schema = schema;
        _coldBootSchema = [schema copy];
        
        [self setSchema:schema];
    }
    return self;
}

- (void)updateWithModel:(BDPModel *)model
{
    _model = model;
    _sandbox = [BDPGetResolvedModule(BDPStorageModuleProtocol, self.uniqueID.appType) createSandboxWithUniqueID:model.uniqueID pkgName:model.pkgName];
    _auth = [[BDPAuthorization alloc] initWithAuthDataSource:model storage:_sandbox.privateStorage];
    
    _sdkVersion = [BDPVersionManager localLibBaseVersionString];
    _sdkUpdateVersion = [BDPVersionManager localLibVersionString];
    
    _isActive = NO;
    _isReady = NO;
    _isDestroyed = NO;
}

- (void)setSchema:(BDPSchema *)schema
{
    if (_schema != schema) {
        _schema = schema;
        if ([[BDPSettingsManager.sharedManager s_arrayValueForKey:kBDPSLaunchAppWiteList] containsObject:_schema.scene]) {
            _canLaunchApp = YES;
        } else if (![[BDPSettingsManager.sharedManager s_arrayValueForKey:kBDPSLaunchAppGrayList] containsObject:_schema.scene]) {
            _canLaunchApp = NO;
        }
    }
}

- (void)dealloc
{
    BDPLogInfo(@"dealloc, id=%@", self.uniqueID);
    [BDPFileSystemHelper clearFolderInBackground:self.sandbox.tmpPath];
    [BDPTracker removeCommomParamsForUniqueID:self.uniqueID];
}

- (OPTrace *)getTrace {
    return [[BDPTracingManager sharedInstance] getTracingByUniqueID:_uniqueID] ?: [[BDPTracingManager sharedInstance] generateTracingByUniqueID:_uniqueID];
}

- (ECONetworkRequestSourceWapper *)getSource {
    return [[ECONetworkRequestSourceWapper alloc] initWithSource:ECONetworkRequestSourceApi];
}

@end
