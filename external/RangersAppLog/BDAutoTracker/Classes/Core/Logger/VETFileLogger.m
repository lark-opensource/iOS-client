////
////  VETFileLogger.m
////  VETracker
////
////  Created by SoulDiver on 2022/5/20.
////
//
//#import "VETFileLogger.h"
//#import "VETrackerConfiguration+Logger.h"
//#import "VETContext.h"
//#import "VETContext+Configuration.h"
//
//
//@interface VETFileLogger ()
//
//@property (nonatomic, strong) NSFileHandle *fileHandle;
//
//@end
//
//@implementation VETFileLogger
//
//- (NSString *)filePath
//{
//    return nil;
//}
//
//- (BOOL)start
//{
//    VETrackerLogConfiguration *config = self.context.config.logConfig;
//    if (config.fileLogEnabled) {
//
//        //TODO
//        //creat file and fileHandler
//
//        [REQUIRE_MODULE(self.context, Logger) addLogger:self];
//        return YES;
//    }
//    return NO;
//}
//
//- (void)log:(VETLogBody *)body
//{
//    if (!self.fileHandle) {
//        return;
//    }
//    @try {
//        NSString *message = vetlog_console_messageformat(self, body);
//        NSString *time = vetlog_full_dateformat(body.date);
//        NSString *formatted = [NSString stringWithFormat:@"%@ %@", time, message];
//        [self.fileHandle seekToEndOfFile];
//        [self.fileHandle writeData:[formatted dataUsingEncoding:NSUTF8StringEncoding]];
//    } @catch (NSException *exception) {
//    } @finally {
//    }
//}
//
//- (dispatch_queue_t)queue
//{

//}
//
//EXPORT_MODULE(Logger-file);
//
//@end
