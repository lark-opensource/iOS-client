//
//  HMDAppVCPageViewRecord.m
//  Heimdallr
//
//  Created by wangyinhui on 2023/2/21.
//

#import <pthread/pthread.h>
#import <dispatch/dispatch.h>

#import "HMDAppVCPageViewRecord.h"
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDServiceContext.h"

#define HMDAppMaxVCCount 200
#define HMDAPPMaxVCChangeTimes 5

static NSString *HMDAppVCPageViewFilePath;
static NSString *HMDAppLastVCPageViewFilePath;

static dispatch_queue_t pv_queue;


@interface HMDAppVCPageViewRecord()

@property(nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> *pvInfo;

@property(nonatomic, assign) int changedTimes;


@end

@implementation HMDAppVCPageViewRecord

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.pvInfo = [NSMutableDictionary new];
        self.changedTimes = 0;
    }
    return self;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static HMDAppVCPageViewRecord *record;
    dispatch_once(&onceToken, ^{
        record = [[HMDAppVCPageViewRecord alloc] init];
        pv_queue = dispatch_queue_create("com.heimdallr.app_exit_pv", DISPATCH_QUEUE_SERIAL);
        NSString *directory = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"vcPV"];
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isDirectory;
        BOOL isExist = [manager fileExistsAtPath:directory isDirectory:&isDirectory];
        if (!isExist || !isDirectory) {
            if (!isDirectory) {
                NSError *err;
                [manager removeItemAtPath:directory error:&err];
                if (err)
                    HMDLog(@"[App exit]create pv directory error, path: %@, err: %@", directory, err);
            }
            hmdCheckAndCreateDirectory(directory);
        }
        HMDAppVCPageViewFilePath = [directory stringByAppendingPathComponent:@"pvinfo.plist"];
        HMDAppLastVCPageViewFilePath = [directory stringByAppendingPathComponent:@"last_pvinfo.plist"];
        if([manager fileExistsAtPath:HMDAppVCPageViewFilePath]) {
            //rename last pv info file, pvinfo.plist -> last_pvinfo.plist
            if ([manager fileExistsAtPath:HMDAppLastVCPageViewFilePath])
                [manager removeItemAtPath:HMDAppLastVCPageViewFilePath error:nil];
            NSError *err;
            [manager moveItemAtPath:HMDAppVCPageViewFilePath
                             toPath:HMDAppLastVCPageViewFilePath
                              error:&err];
            if (err)
                HMDLog(@"[App exit]move pv file error, path: %@, err: %@", HMDAppVCPageViewFilePath, err);
            
        }
        
    });
    return record;
}

- (void)recordPageViewForVCAsync:(NSString *)vc {
    dispatch_async(pv_queue, ^{
        if (self->_pvInfo.count > HMDAppMaxVCCount) {
            return;
        }
            
        if ([self->_pvInfo hmd_hasKey:vc]) {
            int times = [self->_pvInfo hmd_intForKey:vc];
            [self->_pvInfo hmd_setObject:@(times + 1) forKey:vc];
        } else {
            [self->_pvInfo hmd_setObject:@(1) forKey:vc];
        }
        
        self->_changedTimes++;
        if (self->_changedTimes >= HMDAPPMaxVCChangeTimes) {
            [self writePageViewInfoToFileAsync];
        }
    });
}

- (void)writePageViewInfoToFileAsync {
    dispatch_async(pv_queue, ^{
        if (self->_changedTimes >= HMDAPPMaxVCChangeTimes) {
            NSURL *file = [[NSURL alloc] initFileURLWithPath:HMDAppVCPageViewFilePath];
            NSError *err;
            if (@available(iOS 11.0, *))
                [self->_pvInfo writeToURL:file error:&err];
            else
                [self->_pvInfo writeToURL:file atomically:YES];
            if (err)
                HMDLog(@"[App exit]write current error, path: %@, err: %@", HMDAppVCPageViewFilePath, err);
            self->_changedTimes = 0;
        }
    });
}

- (NSDictionary<NSString *,NSNumber *> *)getHistoryPageViewStatisticInfo {
    if (![[NSFileManager defaultManager] fileExistsAtPath:HMDAppLastVCPageViewFilePath])
        return nil;
    
    if (@available(iOS 11.0, *)) {
        NSURL *file = [[NSURL alloc] initFileURLWithPath:HMDAppLastVCPageViewFilePath];
        NSError *err;
        NSDictionary<NSString *,NSNumber *> *lastPvInfo =[NSDictionary dictionaryWithContentsOfURL:file error:&err];
        if (err)
            HMDLog(@"[App exit]get history pv info error, path: %@, err: %@", HMDAppLastVCPageViewFilePath, err);
        return lastPvInfo;
    }
    
    return  [NSDictionary dictionaryWithContentsOfFile:HMDAppLastVCPageViewFilePath];
    
}

- (void)reportLastPageViewInfoAsync {
    dispatch_async(pv_queue, ^{
        NSDictionary<NSString *,NSNumber *> *lastPvInfo = [self getHistoryPageViewStatisticInfo];
        if (lastPvInfo) {
            id<HMDTTMonitorServiceProtocol> defaultMonitor = hmd_get_app_ttmonitor();
            [defaultMonitor hmdTrackService:@"hmd_app_vc_pv" metric:lastPvInfo category:nil extra:nil];
        }
    });
}

@end
