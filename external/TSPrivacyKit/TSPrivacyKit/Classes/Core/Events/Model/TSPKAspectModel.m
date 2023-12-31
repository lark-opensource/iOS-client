//Copyright © 2022 Bytedance. All rights reserved.
#import "TSPKAspectModel.h"
#import <TSPrivacyKit/TSPKAPIModel.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKAspectModel
- (instancetype)initWithDictionary:(NSDictionary*)dict{
    if(self = [super init]){
        NSString *retstr = [dict btd_stringValueForKey:@"returnType"];
        if(retstr){
            retstr = retstr.lowercaseString;
            self.returnType = retstr;
            _returnTypeKind = TSPKAspectMethodReturnNone;
            if (!retstr || [retstr isEqualToString:@"void"]){
                _returnTypeKind = TSPKAspectMethodReturnNone;
            }else if([retstr isEqualToString:@"int"] || [retstr isEqualToString:@"double"] || [retstr isEqualToString:@"float"]) {
                _returnTypeKind = TSPKAspectMethodReturnNumeric;
            }else if([retstr characterAtIndex:0]=='@'){
                _returnTypeKind = TSPKAspectMethodReturnObject;
                self.returnType = [retstr substringFromIndex:1];
            }else if([retstr characterAtIndex:0]=='#'){
                _returnTypeKind = TSPKAspectMethodReturnStruct;
                self.returnType = [retstr substringFromIndex:1];
            }else{
                _returnTypeKind = TSPKAspectMethodReturnObject;
            }
        }
        
        NSString *aspectPositionStr = [dict btd_stringValueForKey:@"aspectPosition"];
        if ([aspectPositionStr.lowercaseString isEqualToString:@"post"]) {
            _aspectPosition = TSPKAspectPositionPost;
        }else{
            _aspectPosition = TSPKAspectPositionPre;
        }
        
        self.klassName = [dict btd_stringValueForKey:@"klassName"];
        self.methodName = [dict btd_stringValueForKey:@"methodName"];
        self.returnValue = [dict btd_stringValueForKey:@"returnValue"];
        self.methodType = [dict btd_intValueForKey:@"methodType" default:0];
        self.pipelineType = [dict btd_stringValueForKey:@"pipelineType"];
        self.registerEntryType = [dict btd_stringValueForKey:@"registerEntryType"]?:self.pipelineType;
        self.apiId = [[dict btd_stringValueForKey:@"apiId"]integerValue];
        self.dataType = [dict btd_stringValueForKey:@"dataType"];
        self.needFuse = [[dict btd_stringValueForKey:@"needFuse"]boolValue];
        self.needLogCaller = [[dict btd_stringValueForKey:@"needLogCaller"]boolValue];
        self.detector = [dict btd_stringValueForKey:@"detector"];
        self.storeType = [[dict btd_stringValueForKey:@"storeType"]integerValue];
        self.apiUsageType = [[dict btd_stringValueForKey:@"apiUsageType"]integerValue];
        self.enableDetector = [dict btd_boolValueForKey:@"enableDetector" default:YES];
        self.actions = [dict btd_arrayValueForKey:@"actions"];
        self.aspectAllMethods = [dict btd_boolValueForKey:@"aspectAllMethods" default:NO];
        self.ignoreInternalMethods = [dict btd_boolValueForKey:@"ignoreInternalMethods" default:YES];
    }
    return self;
}

- (NSString *)registerEntryType {
    if (!_registerEntryType) {
        return self.pipelineType;
    }
    
    return _registerEntryType;
}

- (void)fillPipelineType {
    if (self.pipelineType.length > 0) {
        return;
    }
    
    if (self.klassName.length == 0 || self.methodName.length == 0) {
        return;
    }
    
    self.pipelineType = [NSString stringWithFormat:@"PNS_%@_%@", self.klassName, self.methodName];
    
    switch (self.methodType) {
        case TSPKAspectMethodTypeUnknown:
            break;
        case TSPKAspectMethodTypeInstance:
            self.pipelineType  = [NSString stringWithFormat:@"%@_instance", self.pipelineType];
            break;
        case TSPKAspectMethodTypeClass:
            self.pipelineType  = [NSString stringWithFormat:@"%@_class", self.pipelineType];
            break;
    }
}

@end
