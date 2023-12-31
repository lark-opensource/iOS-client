//
//  ACCTextReadingRequestHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/7/27.
//

#import "ACCTextReadingRequestHelper.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/ACCStickerNetServiceProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <ByteDanceKit/NSTimer+BTDAdditions.h>

static NSString *const kAWEEditTextReadingRequestMonitorKey = @"edit_text_read_request";
static char * const kACCTextReadingRequestHelperDownloadQueue = "com.aweme.cameraClient.textReaderRequestHelper.downloadQueue";

@interface ACCTextReadingRequestHelper()

@property (nonatomic, strong) NSTimer *pollTimer;

@property (nonatomic, strong) id currentTokenRequest;

@property (nonatomic, strong) id currentPollRequest;

@property (nonatomic, strong) NSMutableArray<id> *audioRequests;

@property (nonatomic, strong) dispatch_queue_t downloadQueue;

@end

@implementation ACCTextReadingRequestHelper

+ (ACCTextReadingRequestHelper *)sharedHelper
{
    static ACCTextReadingRequestHelper *sharedHelper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[ACCTextReadingRequestHelper alloc] init];
    });
    return sharedHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.audioRequests = [NSMutableArray array];
        self.downloadQueue = dispatch_queue_create(kACCTextReadingRequestHelperDownloadQueue, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)requestTextReadingForUploadText:(NSString *)uploadText
                               filePath:(NSString *)filePath
                        completionBlock:(void(^)(BOOL, NSString *, NSError *))completionBlock
{
    if (!uploadText.length) {
        ACCBLOCK_INVOKE(completionBlock,NO,nil,nil);
        return;
    }
    
    [self cancelTextReadingRequest];
    
    @weakify(self);
    self.currentTokenRequest = [IESAutoInline(ACCBaseServiceProvider(), ACCTextStickerNetServiceProtocol) requestPollTokenForTextReading:uploadText completionBlock:^(BOOL success, NSString *token, NSError *error) {
        @strongify(self);
        if (success && token.length && !error) {
            [self pollRequestForToken:token
                             filePath:filePath
                      completionBlock:^(BOOL success, NSString *filePath, NSError *error) {
                @strongify(self);
                if (success && filePath.length && !error) {
                    ACCBLOCK_INVOKE(completionBlock,YES,filePath,nil);
                } else {
                    ACCBLOCK_INVOKE(completionBlock,NO,nil,error);
                }
                [self cancelTextReadingRequest];
            }];
        } else {
            ACCBLOCK_INVOKE(completionBlock,NO,nil,error);
            [self cancelTextReadingRequest];
        }
    }];
}

- (void)cancelTextReadingRequest
{
    [ACCNetService() cancel:self.currentTokenRequest];
    self.currentTokenRequest = nil;
    [ACCNetService() cancel:self.currentPollRequest];
    self.currentPollRequest = nil;
    [self.pollTimer invalidate];
    self.pollTimer = nil;
    
    @weakify(self);
    dispatch_barrier_async(self.downloadQueue, ^{
        @strongify(self);
        NSArray *requests = [self.audioRequests copy];
        for (id request in requests) {
            [ACCNetService() cancel:request];
        }
        [self.audioRequests removeAllObjects];
    });
}

//Poll With Token
- (void)pollRequestForToken:(NSString *)token
                   filePath:(NSString *)filePath
            completionBlock:(void(^)(BOOL, NSString *, NSError *error))completionBlock
{
    NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
    NSTimeInterval pollInterval = [configs acc_floatValueForKey:@"read_text_polling_interval"] ? : 2.f;
    NSInteger pollCountLimit = [configs acc_integerValueForKey:@"read_text_polling_times"] ? : 5;
    
    __block NSUInteger pollCount = 0;
    @weakify(self);
    self.pollTimer = [NSTimer btd_scheduledTimerWithTimeInterval:pollInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        //cancel last poll request before next
        [ACCNetService() cancel:self.currentPollRequest];
        self.currentPollRequest = nil;
        self.currentPollRequest = [IESAutoInline(ACCBaseServiceProvider(), ACCTextStickerNetServiceProtocol) pollAudioForTextReadingToken:token completionBlock:^(BOOL success, NSData *data, NSError *error) {
            if (success && data && !error) {
                success = [data acc_writeToFile:filePath options:NSDataWritingAtomic error:&error];
                ACCBLOCK_INVOKE(completionBlock,success,filePath,error);
            } else if (pollCount >= pollCountLimit || error) {
                ACCBLOCK_INVOKE(completionBlock,NO,nil,error);
            }
        }];
        
        pollCount++;
        if (pollCount >= pollCountLimit) {
            [self.pollTimer invalidate];
            self.pollTimer = nil;
        }
    }];
}

- (void)requestTextReaderForUploadText:(NSString *)uploadText
                           textSpeaker:(NSString *)textSpeaker
                              filePath:(NSString *)filePath
                       completionBlock:(void(^)(BOOL, NSString *, NSError *))completionBlock
{
    if (!uploadText.length) {
        ACCBLOCK_INVOKE(completionBlock,NO,nil,nil);
        return;
    }
    
    [ACCMonitor() startTimingForKey:kAWEEditTextReadingRequestMonitorKey];
    id request = [IESAutoInline(ACCBaseServiceProvider(), ACCTextStickerReadingNetServiceProtocol) requestAudioForTextReading:uploadText
                                                                                                                         textSpeaker:textSpeaker
                                                                                                                     completionBlock:^(NSError *error, BOOL success, NSData *data) {
        BOOL readSuccess = NO;
        if (success && data && !error) {
            readSuccess = [data acc_writeToFile:filePath options:NSDataWritingAtomic error:&error];
            ACCBLOCK_INVOKE(completionBlock,readSuccess,filePath,error);
        } else {
            readSuccess = NO;
            ACCBLOCK_INVOKE(completionBlock,NO,nil,error);
        }
        [ACCMonitor() trackService:kAWEEditTextReadingRequestMonitorKey
                            status:readSuccess ? 0 : 1
                             extra:@{
                                 @"code":@(error.code),
                                 @"duration":@([ACCMonitor() timeIntervalForKey:kAWEEditTextReadingRequestMonitorKey])
                             }
         ];
        [ACCMonitor() cancelTimingForKey:kAWEEditTextReadingRequestMonitorKey];
    }];
    @weakify(self);
    dispatch_barrier_async(self.downloadQueue, ^{
        @strongify(self);
        [self.audioRequests acc_addObject:request];
    });
}

@end
