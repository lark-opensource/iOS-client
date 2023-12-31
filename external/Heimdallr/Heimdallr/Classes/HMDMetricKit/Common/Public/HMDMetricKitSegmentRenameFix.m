//
//  HMDMetricKitSegmentRenameFix.m
//  AppHost-Heimdallr-Unit-Tests
//
//  Created by ByteDance on 2023/8/16.
//
#include <sys/mman.h>

#import "HMDMetricKitSegmentRenameFix.h"
#import "HeimdallrUtilities.h"
#import "hmd_thread_backtrace.h"
#import "HMDCompactUnwind.hpp"
#import "NSDictionary+HMDSafe.h"
#import "HMDUserDefaults.h"
#import "HMDInfo+AppInfo.h"
#import "HMDFileTool.h"

static NSString *const HMDMetricKitExpandDir = @"MetricKit";
static NSString *const HMDMetricKitPreSegmentDir = @"preSegment";
static NSString *const HMDMetricKitAppImagesTextSegmentInfoFile = @"appImagesTextSegmentInfo.plist";

#define HMDMaxBinaryNameLength 100
#define HMDMaxBinaryUUIDLength 40

#define HMDMaxSegmentFixInfoCount 50

struct hmd_segment_fix_info {
    // AwemeCore
    char binary_name[HMDMaxBinaryNameLength];
    
    // 80e4456d62783c6b9116dc486b4c6b94
    char uuid[HMDMaxBinaryUUIDLength];
    
    uintptr_t start_address;
    
    uintptr_t end_address;
    
    uintptr_t anchor;
};

typedef struct hmd_segments_fix_info_table {
    int index;
    struct hmd_segment_fix_info segment_fix_info_list[HMDMaxSegmentFixInfoCount];
} hmd_segments_fix_info_table_t;


static int current_pre_segment_fd = -1;
static hmd_segments_fix_info_table_t *segment_table = NULL;


static hmd_segments_fix_info_table_t * hmd_get_map_segments_fix_info_table(int fd) {
    size_t size = round_page(sizeof(hmd_segments_fix_info_table_t));
    
    void *mapped = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (!mapped) {
        close(fd);
        return NULL;
    }
    
    return (hmd_segments_fix_info_table_t *)mapped;
}

static void hmd_release_map_segments_fix_info_table(hmd_segments_fix_info_table_t *segments_table_ptr, int fd) {
    if (segments_table_ptr && fd > 0) {
        size_t size = round_page(sizeof(hmd_segments_fix_info_table_t));
        
        int rst = munmap(segments_table_ptr, size);
        if (rst != 0) {
            HMDLog(@"[MetricKit] munmap segments_table err, %s", strerror(errno));
        }
    }
    
    if (fd > 0) {
        close(fd);
    }
}

@implementation HMDMetricKitSegmentInfo

@end

@interface HMDMetricKitSegmentRenameFix()

@property(nonatomic, strong)dispatch_queue_t serialQueue;

@property(nonatomic, strong)NSString *expandDir;

@property(nonatomic, strong)NSString *appImagesTextSegmentInfoFilePath;

@property(nonatomic, strong)NSString *preSegmentDir;

@property(nonatomic, strong)NSString *currentPreSegmentFilePath;


    
@end

@implementation HMDMetricKitSegmentRenameFix


+(instancetype)shared {
    static dispatch_once_t onceToken;
    static HMDMetricKitSegmentRenameFix *shared;
    dispatch_once(&onceToken, ^{
        shared = [[HMDMetricKitSegmentRenameFix alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("com.heimdallr.metric_kit.record_segment_info", DISPATCH_QUEUE_SERIAL);
        
        _expandDir = [[HeimdallrUtilities heimdallrRootPath]
                                            stringByAppendingPathComponent:HMDMetricKitExpandDir];
        _appImagesTextSegmentInfoFilePath = [_expandDir
                                             stringByAppendingPathComponent:HMDMetricKitAppImagesTextSegmentInfoFile];
        _preSegmentDir = [_expandDir stringByAppendingPathComponent:HMDMetricKitPreSegmentDir];
        
        //use current time as file name, record segment info
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSString *currentPreSegmentFileName = [NSString stringWithFormat:@"%f.data", currentTime];
        _currentPreSegmentFilePath = [_preSegmentDir stringByAppendingPathComponent:currentPreSegmentFileName];
    }
    return self;
}

#pragma mark - segment file manage

-(hmd_segments_fix_info_table_t *)initMapSegmentsTableOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self checkAndRemoveOldPreSegmentFile];
        
        if ([self createDirWithPath:self.expandDir]) {
            if ([self createDirWithPath:self.preSegmentDir]) {
                
                current_pre_segment_fd = open([self.currentPreSegmentFilePath UTF8String], O_RDWR | O_CREAT, S_IRWXU);
                if (current_pre_segment_fd < 0) {
                    HMDLog(@"[MetricKit] open currentPreSegmentFilePath err, %s", strerror(errno));
                    return;
                }
                
                size_t size = round_page(sizeof(hmd_segments_fix_info_table_t));
                int err;
                if (!HMDFileAllocate(current_pre_segment_fd, size, &err)) {
                    close(current_pre_segment_fd);
                    current_pre_segment_fd = -1;
                    HMDLog(@"[MetricKit] HMDFileAllocate currentPreSegmentFilePath err, %s", strerror(errno));
                    return;
                }
                
                segment_table = hmd_get_map_segments_fix_info_table(current_pre_segment_fd);
            }
        }
    });
    
    return segment_table;
}

-(BOOL)removeExpendDir API_AVAILABLE(ios(14.0)) {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExit = [manager fileExistsAtPath:_expandDir isDirectory:&isDir];
    NSError *err;
    if (isExit) {
        [manager removeItemAtPath:self->_expandDir error:&err];
        if (err) {
            HMDLog(@"[MetricKit] remove expend dir err, %@", err);
            return NO;
        }
    }
    return YES;
}

-(BOOL)createDirWithPath:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExist = [manager fileExistsAtPath:path isDirectory:&isDir];
    NSError *err;
    if (isExist && !isDir) {
        [manager removeItemAtPath:path error:&err];
        if (err) {
            HMDLog(@"[MetricKit] remove %@ dir err, %@", path, err);
            return NO;
        }
    }
    if (!isExist || !isDir) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            HMDLog(@"[MetricKit]create %@ dir err, %@", path, err);
            return NO;
        }
    }
    return YES;
}

-(void)checkAndRemoveOldPreSegmentFile {
    
    NSFileManager *manager =  [NSFileManager defaultManager];
    
    BOOL isDir;
    BOOL isExist = [manager fileExistsAtPath:_preSegmentDir isDirectory:&isDir];
    if (!isExist || !isDir) {
        return;
    }
    
    NSError *err;
    NSArray *fileList = [manager contentsOfDirectoryAtPath:_preSegmentDir error:&err];
    if (err) {
        HMDLog(@"[MetricKit]checkAndRemoveOldPreSegmentFile error, %@", err);
        return;
    }
    
    //if count of preSegment files more than 10, maybe a serial crash happened. remove some old file.
    if (fileList.count >= 10) {
        
        NSArray *sortFileList = [fileList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *str1 = obj1;
            NSString *str2 = obj2;
            return [str1 compare:str2];
        }];
        
        for (int i = 0; i < sortFileList.count; ++i) {
            @autoreleasepool {
                if (i < 5) {
                    NSString *filePath = [_preSegmentDir stringByAppendingPathComponent:sortFileList[i]];
                    BOOL isSuccess = [manager removeItemAtPath:filePath error:&err];
                    if (err || !isSuccess) {
                        HMDLog(@"[MetricKit] checkAndRemoveOldPreSegmentFile error, remove %@ %@", filePath, err);
                        return;
                    }
                }
            }
        }
    }

}
#pragma mark - MetricKit tracker segment rename fix V1

- (NSDictionary *)fetchCurrentImageNameUUIDMap {
    
    static NSDictionary *binaryImage = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSMutableDictionary *imageNameMap = [NSMutableDictionary dictionary];
        
        hmd_enumerate_app_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
            NSString *imageName = @"unknown";
            if(image->macho_image.name != NULL){
                NSString *path = [NSString stringWithUTF8String:image->macho_image.name];
                imageName = [path lastPathComponent];
            }
            NSString *uuid = [NSString stringWithUTF8String:image->macho_image.uuid];
            [imageNameMap setValue:uuid forKey:imageName];
        });
        
        binaryImage = [imageNameMap copy];
    });
    return binaryImage;
}

- (NSDictionary *)getCurrentAppVersionMainOffset {
    __block NSDictionary *appImage = nil;
    hmd_setup_shared_image_list(); 
    hmd_async_image_list_set_reading(&shared_app_image_list, true);
    hmd_async_image_t *mainImage = hmd_async_image_containing_address(&shared_app_image_list, hmdbt_get_app_main_addr());
    hmd_async_image_list_set_reading(&shared_app_image_list, false);
    
    if (mainImage) {
        NSString *imageName = @"unknown";
        if(mainImage->macho_image.name != NULL){
            NSString *path = [NSString stringWithUTF8String:mainImage->macho_image.name];
            imageName = [path lastPathComponent];
        }
        NSString *uuid = [NSString stringWithUTF8String:mainImage->macho_image.uuid];
        appImage = @{
            @"binary_name": imageName,
            @"uuid": uuid,
            //must get main address from main thread stack, This main address is not begin of function, but has a small offset.
            @"main_address":@(hmdbt_get_app_main_addr() - mainImage->macho_image.header_addr)
        };
    }
    
    return appImage;
}


//fetch current and last app version‘s main function offset
- (NSDictionary *)fetchRecentAppVersionMainOffset {
    NSMutableDictionary *appImages = [NSMutableDictionary new];
    
    NSDictionary *lastVersionImage = [[HMDUserDefaults standardUserDefaults] dictForKey:@"last_app_image"];
    
    NSString *currentVersion = [[HMDInfo defaultInfo] buildVersion];
    
    if (lastVersionImage && [lastVersionImage hmd_hasKey:@"version"] && [lastVersionImage hmd_hasKey:@"app_image"]){
        
        NSString *lastVersion = [lastVersionImage hmd_stringForKey:@"version"];
        
        [appImages setObject:[lastVersionImage hmd_dictForKey:@"app_image"] forKey:lastVersion];
        
        if(lastVersion == currentVersion){
            
            return [appImages copy];
        }
    }
    
    NSDictionary *currentMainImage =[self getCurrentAppVersionMainOffset];
    NSDictionary *currentVersionImage = nil;
    if (currentVersion && currentMainImage){
        currentVersionImage = @{
            @"version": currentVersion,
            @"app_image": currentMainImage
        };
    }
    
    if (currentVersionImage){
        //获取当前版本的image信息并进行存储
        [appImages setObject:[currentVersionImage hmd_dictForKey:@"app_image"] forKey:[currentVersionImage hmd_stringForKey:@"version"]];
        [[HMDUserDefaults standardUserDefaults] setObject:currentVersionImage forKey:@"last_app_image"];
    }
    return [appImages copy];
}


#pragma mark - MetricKit tracker segment rename fix V2

- (NSArray *)fetchCurrentAppImagesTextSegmentRange {
    unsigned long mainAddress = hmdbt_get_app_main_addr();
    NSMutableArray *imageInfos = [NSMutableArray new];
    hmd_enumerate_app_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        NSString *binaryName = [[NSString stringWithUTF8String:image->macho_image.name] lastPathComponent];

        //recode sum range of all execute segments
        hmd_vm_address_t endAddress = image->macho_image.text_segment.addr + image->macho_image.text_segment.size;
        for(int i=0; i< image->macho_image.segment_count; i++) {
            hmd_async_segment segment = image->macho_image.segments[i];
            if (segment.initprot & VM_PROT_EXECUTE) {
                hmd_vm_address_t tempEndAddr = segment.range.addr + segment.range.size;
                if (tempEndAddr > endAddress) endAddress = tempEndAddr;
            }
        }

        [imageInfos addObject:@{
            @"mainAddress":@(mainAddress),
            @"binaryUUID":[NSString stringWithUTF8String: image->macho_image.uuid],
            @"startAddressBinaryTextSegment":@(image->macho_image.header_addr),
            @"endAddressBinaryTextSegment":@(endAddress),
            @"binaryName": binaryName
        }];
    });
    return [imageInfos copy];
}

/*
 [{
     @"mainAddress":@(mainAddress),
     @"binaryUUID":[NSString stringWithUTF8String: image->macho_image.uuid],
     @"startAddressBinaryTextSegment":@(image->macho_image.header_addr),
     @"endAddressBinaryTextSegment":@(endAddress),
     @"binaryName": binaryName
 }]
 */
- (NSArray *)historyAppImageTextSegmentInfos {
    static dispatch_once_t onceToken;
    static NSArray *historyAppImageInfos;
    dispatch_once(&onceToken, ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *err;
        NSURL *fileURL = [NSURL fileURLWithPath:self->_appImagesTextSegmentInfoFilePath];
        if([manager fileExistsAtPath:_appImagesTextSegmentInfoFilePath]) {
            // read image info from local file.
            historyAppImageInfos = [[NSArray alloc] initWithContentsOfURL:fileURL error:&err];
            if (err) {
                HMDLog(@"[MetricKit]read image info to file err, %@", err);
                [manager removeItemAtPath:self->_appImagesTextSegmentInfoFilePath error:nil];
            }
        }
    });
    
    return historyAppImageInfos;
}

/*
{
 "4875319496":
    [{
         "binaryName": "Aweme",
         "binaryUUID": "0fec82e570263352a61ff3d72f649dd2",
         "endAddressBinaryTextSegment": 4329635840,
         "startAddressBinaryTextSegment": 4329570304
    }]
}
 */
-(NSDictionary *)historyAppImageTextSegmentMap {
    NSMutableDictionary<NSString*, NSMutableArray*> *imageInfoDict = [NSMutableDictionary new];
    
    NSArray *historyAppImageInfos = [self historyAppImageTextSegmentInfos];
    
    [historyAppImageInfos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *imageInfo = (NSDictionary *)obj;
        NSString *mainAddress = [imageInfo hmd_stringForKey:@"mainAddress"];
        if (mainAddress) {
            if ([imageInfoDict hmd_hasKey:mainAddress]) {
                NSMutableArray *images = [imageInfoDict objectForKey:mainAddress];
                [images addObject:imageInfo];
            }else {
                NSMutableArray *images = [NSMutableArray new];
                [images addObject:imageInfo];
                [imageInfoDict hmd_setObject:images forKey:mainAddress];
            }
        }
    }];
    
    return [imageInfoDict copy];
}

- (void)asyncRecordRecordAppImagesTextSegmentInfo {
    
    hmd_setup_shared_image_list_if_need();
    
    //get image info base on hmd_enumerate_app_image_list_using_block, so async to hmd_shared_binary_image_queue.
    dispatch_async(hmd_shared_binary_image_queue(), ^{
        
        NSArray *currentAppImageInfos = [self fetchCurrentAppImagesTextSegmentRange];
        
        dispatch_async(self.serialQueue, ^{
            NSMutableArray *historyAppImageInfos = [[self historyAppImageTextSegmentInfos] mutableCopy];
            if (currentAppImageInfos && currentAppImageInfos.count > 0){
                // prevent local files too large
                if (historyAppImageInfos && historyAppImageInfos.count >= 100 && currentAppImageInfos.count > 0) {
                    [historyAppImageInfos removeObjectsInRange: NSMakeRange(0, currentAppImageInfos.count)];
                }
                [historyAppImageInfos addObjectsFromArray:currentAppImageInfos];
                
                NSError *err;
                NSURL *filePath = [NSURL fileURLWithPath:self.appImagesTextSegmentInfoFilePath];
                BOOL ok = [historyAppImageInfos writeToURL:filePath error:&err];
                if (ok) {
                    dispatch_async(self.serialQueue, ^{
                        //MetricKit tracker has recorded all app image info, remove current preSegment info file.
                        hmd_release_map_segments_fix_info_table(segment_table, current_pre_segment_fd);
                        current_pre_segment_fd = -1;
                        segment_table = NULL;
                        [[NSFileManager defaultManager] removeItemAtPath:self.currentPreSegmentFilePath error:NULL];
                        if (self.callback) {
                            self.callback();
                        }
                    });
                }else {
                    HMDLog(@"[MetricKit]write image info to file err, %@", err);
                }
            }
        });
    });
    
}

-(void)resetAppImagesTextSegmentRangeFile {
    NSURL *fileURL = [NSURL fileURLWithPath:_appImagesTextSegmentInfoFilePath];
    NSArray *appImageInfos = [self fetchCurrentAppImagesTextSegmentRange];
    NSError *err;
    [appImageInfos writeToURL:fileURL error:&err];
    if (err) {
        HMDLog(@"[MetricKit]create image info file err, %@", err);
    }
}


#pragma mark - preSegment rename fix V3

- (void)asyncPreRecordAppImagesTextSegmentInfo:(HMDMetricKitSegmentInfo * _Nonnull)info {
    if (!info) {
        return;
    }
    dispatch_async(_serialQueue, ^{
        
        //init dir -> /Heimdallr/MetricKit/preSegment, mmap file -> /Heimdallr/MetricKit/preSegment/{current timestamp}
        [self initMapSegmentsTableOnce];
        
        if (segment_table && segment_table->index < HMDMaxSegmentFixInfoCount && current_pre_segment_fd > 0) {
            
            struct hmd_segment_fix_info *segment_info = segment_table->segment_fix_info_list + segment_table->index;

            if (info.binaryName && info.binaryUUID) {
                
                size_t name_size = info.binaryName.length < HMDMaxBinaryNameLength ? info.binaryName.length : HMDMaxBinaryNameLength;
                memmove(segment_info->binary_name, [info.binaryName UTF8String], name_size);
                
                size_t uuid_size = info.binaryUUID.length < HMDMaxBinaryUUIDLength ? info.binaryUUID.length : HMDMaxBinaryUUIDLength;
                memmove(segment_info->uuid, [info.binaryUUID UTF8String], uuid_size);
                
                segment_info->start_address = info.startAddressBinaryTextSegment;
                
                segment_info->end_address = info.endAddressBinaryTextSegment;
                
                segment_info->anchor = info.anchorPoint;
                
                segment_table->index++;
                
                //msync mmap memory to file
                size_t size = round_page(sizeof(hmd_segments_fix_info_table_t));
                msync(segment_table, size, MS_SYNC);
            }
        }
        
    });
}

- (void)preRecordAppImagesTextSegmentInfo:(HMDMetricKitSegmentInfo *)info {
    if (!info) {
        return;
    }
    dispatch_sync(_serialQueue, ^{
        
        //init dir -> /Heimdallr/MetricKit/preSegment, mmap file -> /Heimdallr/MetricKit/preSegment/{current timestamp}
        [self initMapSegmentsTableOnce];
        
        if (segment_table && segment_table->index < HMDMaxSegmentFixInfoCount && current_pre_segment_fd > 0) {
            
            struct hmd_segment_fix_info *segment_info = segment_table->segment_fix_info_list + segment_table->index;

            if (info.binaryName && info.binaryUUID) {
                
                size_t name_size = info.binaryName.length < HMDMaxBinaryNameLength ? info.binaryName.length : HMDMaxBinaryNameLength;
                memmove(segment_info->binary_name, [info.binaryName UTF8String], name_size);
                
                size_t uuid_size = info.binaryUUID.length < HMDMaxBinaryUUIDLength ? info.binaryUUID.length : HMDMaxBinaryUUIDLength;
                memmove(segment_info->uuid, [info.binaryUUID UTF8String], uuid_size);
                
                segment_info->start_address = info.startAddressBinaryTextSegment;
                
                segment_info->end_address = info.endAddressBinaryTextSegment;
                
                segment_info->anchor = info.anchorPoint;
                
                segment_table->index++;
                
                //msync mmap memory to file
                size_t size = round_page(sizeof(hmd_segments_fix_info_table_t));
                msync(segment_table, size, MS_SYNC);
            }
        }
        
    });
}

/*
 [{
     @"anchorPoint":@(anchorPoint),
     @"binaryUUID":[NSString stringWithUTF8String: image->macho_image.uuid],
     @"startAddressBinaryTextSegment":@(image->macho_image.header_addr),
     @"endAddressBinaryTextSegment":@(endAddress),
     @"binaryName": binaryName
 }]
 */
- (NSArray *)historyPreAppImageTextSegmentInfos {
    static dispatch_once_t onceToken;
    static NSArray *historyAppImageInfos;
    dispatch_once(&onceToken, ^{
        NSMutableArray *allImageInfos = [NSMutableArray new];
        NSFileManager *manager =  [NSFileManager defaultManager];
        
        NSError *err;
        NSArray *fileList = [manager contentsOfDirectoryAtPath:self.preSegmentDir error:&err];
        if (err) {
            HMDLog(@"[MetricKit]get historyPreAppImageTextSegmentMap error, get file list %@", err);
            return;
        }
        
        if (fileList.count == 0) {
            return;
        }

        for (int i = 0; i < fileList.count; ++i) {
            NSString *filePath = [self.preSegmentDir stringByAppendingPathComponent:fileList[i]];
            if([manager fileExistsAtPath:filePath]) {
                
                // read preSegment info from local file.
                int fd = open([filePath UTF8String], O_RDWR, S_IRWXU);
                
                if (fd >= 0) {
                    
                    hmd_segments_fix_info_table_t *history_segment_table = hmd_get_map_segments_fix_info_table(fd);
                    
                    if (history_segment_table->index > 0 && history_segment_table->index <= HMDMaxSegmentFixInfoCount) {
                        for (int i = 0; i < history_segment_table->index; i++) {
                            
                            struct hmd_segment_fix_info info = history_segment_table->segment_fix_info_list[i];
                            
                            NSString *binaryName = [NSString stringWithUTF8String:info.binary_name];
                            NSString *binaryUUID = [NSString stringWithUTF8String:info.uuid];
                            
                            NSDictionary *segmentInfo = @{
                                @"binaryName": binaryName,
                                @"binaryUUID": binaryUUID,
                                @"startAddressBinaryTextSegment": @(info.start_address),
                                @"endAddressBinaryTextSegment": @(info.end_address),
                                @"anchorPoint": @(info.anchor)
                            };
                            
                            [allImageInfos addObject:segmentInfo];
                        }
                    }
                    
                    hmd_release_map_segments_fix_info_table(history_segment_table, fd);
                    
                }else {
                    HMDLog(@"[MetricKit]read preSegment info to file err, %s, path: %@", strerror(errno), filePath);
                }
                [manager removeItemAtPath:filePath error:nil];
            }
        }
        
        historyAppImageInfos = [allImageInfos copy];
        
    });
    
    return historyAppImageInfos;
}

/*
{
 "4875319496":
    [{
         "binaryName": "Aweme",
         "binaryUUID": "0fec82e570263352a61ff3d72f649dd2",
         "endAddressBinaryTextSegment": 4329635840,
         "startAddressBinaryTextSegment": 4329570304
    }]
}
 */
-(NSDictionary *)historyPreAppImageTextSegmentMap {
    
    NSArray *historyAppImageInfos = [self historyPreAppImageTextSegmentInfos];
    
    if (!historyAppImageInfos) {
        return nil;
    }
    
    NSMutableDictionary<NSString*,NSMutableArray*> *imageInfoDict = [NSMutableDictionary new];
    
    [historyAppImageInfos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *imageInfo = (NSDictionary *)obj;
        NSString *anchorPoint = [imageInfo hmd_stringForKey:@"anchorPoint"];
        if (anchorPoint) {
            if ([imageInfoDict hmd_hasKey:anchorPoint]) {
                NSMutableArray *images = [imageInfoDict objectForKey:anchorPoint];
                [images addObject:imageInfo];
            }else {
                NSMutableArray *images = [NSMutableArray new];
                [images addObject:imageInfo];
                [imageInfoDict hmd_setObject:images forKey:anchorPoint];
            }
        }
    }];
    
    return [imageInfoDict copy];
    
}

@end
