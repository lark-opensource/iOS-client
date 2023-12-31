//
//  BDAutoTrack+OneID.m
//  RangersAppLog
//
//  Created by bytedance on 9/26/22.
//

#import "BDAutoTrack+OneID.h"
#import "BDTrackerErrorBuilder.h"
#import "RangersLog.h"
#import "BDAutoTrack+Private.h"
#import "BDTrackerUtility.h"
#import "NSDictionary+VETyped.h"

@implementation BDAutoTrack (OneID)

- (void)bind:(NSDictionary<NSString *,NSString *> *)idmappings
  completion:(void (^)(BOOL success,NSError *error))completion
{
    RL_INFO(self, @"OneID", @"bind call");
    if ([idmappings count] == 0) {
        NSString *message = @"bind failure due to empty idMappings.";
        RL_ERROR(self, @"OneID", message);
        if (completion) {
            completion(NO, [[[[BDTrackerErrorBuilder builder] withCode:0] withDescription:message] build] );
        }
        return;
    }
    
    
    void (^bindCallBack)(BOOL,NSError *) = [completion copy];
    NSDictionary *identities = [[NSMutableDictionary alloc] initWithDictionary:idmappings copyItems:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BDAutoTrackNetworkRequestConfig *requestConfig = [BDAutoTrackNetworkRequestConfig new];
        requestConfig.requireDeviceRegister = NO;
        [self.networkManager sync:(BDAutoTrackRequestURLOneIDBind)
                           method:@"POST"
                           header:@{}
                        parameter:@{@"header":@{@"identities":identities}}
                           config:requestConfig
                       completion:^BOOL(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            
            if (error) {
                RL_ERROR(self, @"OneID", @"bind failure due to %@", error.localizedDescription);
//                [self eventV3:@"$oneid_bind" params:@{@"identities":identities,
//                                                      @"success":@(0),
//                                                      @"error_code":@(error.code),
//                                                      @"error_message":error.localizedDescription?:@"",
//                                                      @"http_code":@(0)}];
                if (bindCallBack) bindCallBack(NO, error);
                return NO;
            }
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            NSDictionary *responseDict = [BDTrackerUtility jsonFromData:data];
            NSInteger responseCode = 0;
            NSString *responseMessage = nil;
            if ([responseDict isKindOfClass:NSDictionary.class]) {
                responseCode = [responseDict vetyped_integerForKey:@"status_code"];
                responseMessage = [responseDict vetyped_stringForKey:@"status_message"];
            }
            
            if (responseCode == 200 || responseCode == 10402) {
                RL_INFO(self, @"OneID", @"bind successful");
//                [self eventV3:@"$oneid_bind" params:@{@"identities":identities,
//                                                      @"success":@(1),
//                                                      @"status_code":@(responseCode),
//                                                      @"http_code":@(statusCode)}];
                if (bindCallBack) bindCallBack(YES, nil);
                return YES;
            }
            NSString *message;
            if (responseCode > 0) {
//                [self eventV3:@"$oneid_bind" params:@{@"identities":identities,
//                                                      @"success":@(0),
//                                                      @"error_code":@(-1),
//                                                      @"status_code":@(responseCode),
//                                                      @"error_message": responseMessage ?: @""}];
                message = [NSString stringWithFormat:@"bind failure due to [%ld] %@", (long)responseCode, responseMessage?:@"Unexpected error"];
            } else {
//                [self eventV3:@"$oneid_bind" params:@{@"identities":identities,
//                                                      @"success":@(0),
//                                                      @"error_code":@(-2),
//                                                      @"http_code":@(statusCode),
//                                                      @"error_message":[NSHTTPURLResponse localizedStringForStatusCode:statusCode]?:@""
//                                                    }];
                message = [NSString stringWithFormat:@"bind failure due to [%ld] %@", statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]];
            }
            RL_ERROR(self, @"OneID", message);
            if (bindCallBack) {
                bindCallBack(NO, [[[[BDTrackerErrorBuilder builder] withCode:responseCode] withDescription:responseMessage?:@"Unexpected error"] build] );
            }
            
            return NO;
        }];
    });
    
    
}

@end
