//
//  NativeToJsBridge.m
//  BitableBridge
//
//  Created by maxiao on 2018/9/13.
//

#import "BTNativeToJsBridge.h"
#import "NSData+BitableBridge.h"

@implementation BTNativeToJsBridge

RCT_EXPORT_MODULE(IOSNativeToJsBridge)

- (NSArray<NSString *> *)supportedEvents {
    return @[@"requestFromNative", @"requestFromDocs"];
}

- (void)request:(NSString *)string {
    [self sendEventWithName:@"requestFromNative" body: string];
}

- (void)docsRequest:(NSString *)string {
    [self sendEventWithName:@"requestFromDocs" body:string];
}

@end
