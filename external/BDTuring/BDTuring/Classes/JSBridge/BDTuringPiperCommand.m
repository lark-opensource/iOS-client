//
//  BDTuringPiperCommand.m
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#import "BDTuringPiperCommand.h"
#import "NSDictionary+BDTuring.h"
#import "NSObject+BDTuring.h"

@implementation BDTuringPiperCommand

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSString *messageType = [dict turing_stringValueForKey:kBDTuringPiperMsgType];
        if ([messageType isEqualToString:BDTuringPiperMsgTypeOn] || [messageType isEqualToString:BDTuringPiperMsgTypeEvent]) {
            self.piperType = BDTuringPiperTypeOn;
        } else if ([messageType isEqualToString:BDTuringPiperMsgTypeCall]) {
            self.piperType = BDTuringPiperTypeCall;
        } else if ([messageType isEqualToString:BDTuringPiperMsgTypeOff]) {
            self.piperType = BDTuringPiperTypeOff;
        }
        self.messageType = messageType;
        self.name = [dict turing_stringValueForKey:kBDTuringPiperName];
        self.callbackID = [dict turing_stringValueForKey:kBDTuringPiperCallbackID];
        self.params = [dict turing_dictionaryValueForKey:kBDTuringPiper2NativeParams];
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name onHandler:(BDTuringPiperOnHandler)onHandler {
    self = [super init];
    if (self) {
        self.messageType = BDTuringPiperMsgTypeOn;
        self.name = name;
        self.piperType = BDTuringPiperTypeOn;
        self.onHandler = onHandler;
    }

    return self;
}

- (void)addCode:(BDTuringPiperMsg)code response:(NSDictionary *)response type:(NSString *)type {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@(code) forKey:kBDTuringPiperCode];
    [param setValue:response forKey:kBDTuringPiperData];
    [param setValue:self.name forKey:kBDTuringPiperName];
    [param setValue:type forKey:kBDTuringPiperMsgType];

    self.params = param;
}

- (NSString *)toJSONString {
    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionary];
    [jsonDic setValue:[self.callbackID mutableCopy]forKey:kBDTuringPiperCallbackID];
    [jsonDic setValue:self.params forKey:kBDTuringPiper2JSParams];

    return [jsonDic turing_JSONRepresentationForJS];
}

@end
