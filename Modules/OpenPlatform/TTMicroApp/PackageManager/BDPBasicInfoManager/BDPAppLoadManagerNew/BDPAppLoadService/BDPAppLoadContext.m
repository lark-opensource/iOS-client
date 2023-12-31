//
//  BDPAppLoadContext.m
//  Timor
//
//  Created by 傅翔 on 2019/1/31.
//

#import "BDPAppLoadContext.h"
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPMacroUtils.h>
#import <objc/runtime.h>
#import <OPFoundation/OPAppVersionType.h>

@implementation OPAppUniqueID(BDPLaunchParams)

-(void)setLeastVersion:(NSString *)leastVersion {
    objc_setAssociatedObject(self, _cmd, leastVersion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)leastVersion {
    return objc_getAssociatedObject(self, @selector(setLeastVersion:));
}

@end

@interface BDPAppLoadContext ()

@property (nonatomic, assign) BOOL didExecGetModelCallback;

@property (nonatomic, copy) dispatch_block_t delayGetPkgCompletionBlk;

@end

@implementation BDPAppLoadContext

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID {
    if (self = [super init]) {
        // 默认类型为小程序
        _uniqueID = uniqueID;
    }
    return self;
}

- (void)triggerGetModelCallbackWithError:(NSError *)error meta:(BDPModel *)meta reader:(BDPPkgFileReader)reader {
    WeakSelf;
    BLOCK_EXEC_IN_MAIN(^{
        StrongSelfIfNilReturn;
        dispatch_block_t delayGetPkgCompletionBlk = nil;

        self.didExecGetModelCallback = YES;
        delayGetPkgCompletionBlk = [self.delayGetPkgCompletionBlk copy];
        self.delayGetPkgCompletionBlk = nil;

        BLOCK_EXEC(self.getModelCallback, error, meta, reader);
        BLOCK_EXEC(delayGetPkgCompletionBlk);
    });
}

- (void)triggerGetPkgCompletionWithError:(NSError *)error meta:(BDPModel *)meta {
    WeakSelf;
    BLOCK_EXEC_IN_MAIN(^{
        dispatch_block_t execBlk = ^{
            StrongSelfIfNilReturn;
            BLOCK_EXEC_IN_MAIN(self.getPkgCompletion, error, meta);
        };
        if (!self.didExecGetModelCallback) { // 防止getPkgCompletion在getModel之前触发
            self.delayGetPkgCompletionBlk = execBlk;
        } else {
            execBlk();
        }
    });
}

#pragma mark Computed Properties
- (BOOL)isReleasedApp {
    return self.uniqueID.versionType == OPAppVersionTypeCurrent;
}

@end

