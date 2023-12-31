//
//  BDAutoTrackFileLogger.m
//  RangersAppLog
//
//  Created by bytedance on 7/5/22.
//

#import "BDAutoTrackFileLogger.h"
#import "RangersLogManager.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"
#import "RangersConsoleLogger.h"

@interface BDAutoTrackFileLogger ()<RangersLogger>
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation BDAutoTrackFileLogger

+ (void)load
{
    [RangersLogManager registerLogger:[self class]];
}

//- (NSString *)
//
- (void)log:(nonnull RangersLogObject *)log {
    
    if (!self.fileHandle) {
        return;
    }
    @try {
        NSString *formatted = [[RangersConsoleLogger logToString:log] stringByAppendingString:@"\r\n"];
        [self.fileHandle seekToEndOfFile];
        [self.fileHandle writeData:[formatted dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
    } @finally {
    }
}

- (void)didAddLogger
{
    NSString *dirPath = bd_trackerLibraryPathForAppID(self.tracker.appID);
    self.filePath = [dirPath stringByAppendingPathComponent:@"log.dat"];
    [self initFileHandle];
}

- (void)initFileHandle
{
    if (self.fileHandle) {
        [self.fileHandle closeFile];
    }
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    if (!self.fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    } else {
        [self.fileHandle seekToEndOfFile];
    }
}

- (NSString *)dump
{
    __block NSString *tmpPath = nil;
    dispatch_sync([self queue], ^{
        if (self.fileHandle) {
            [self.fileHandle closeFile];
            NSString *dumpPath =  [bd_trackerLibraryPathForAppID(self.tracker.appID) stringByAppendingPathComponent:@"finder.log"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:dumpPath] ) {
                [[NSFileManager defaultManager] removeItemAtPath:dumpPath error:nil];
            }
            BOOL result = [[NSFileManager defaultManager] moveItemAtPath:self.filePath toPath:dumpPath error:nil];
            if (result) {
                tmpPath = dumpPath;
            }
            [self initFileHandle];
        }
    });
    return tmpPath;
}

- (nonnull dispatch_queue_t)queue {
    static dispatch_queue_t file_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *name = [NSString stringWithFormat:@"volcengine.logger.file.%p",self];
        file_queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return file_queue;
}

@end
