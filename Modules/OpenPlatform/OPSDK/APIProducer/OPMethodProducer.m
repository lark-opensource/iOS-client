//
//  OPMethodProducter.m
//  OPSDK
//
//  Created by Nicholas Tau on 2020/12/10.
//

#import "OPMethodProducer.h"
#import "OPArguement.h"

@interface OPMethodProducer()
@property(nonatomic, copy, readwrite)  NSString  *jsName;
@property(nonatomic, copy, readwrite)  NSString  *objectClsName;
@property(nonatomic, copy, readwrite)  NSString  *objectMethodName;
@property(nonatomic, assign, readwrite)  SEL     targetSel;
//arguments which mapping from paramters map, but with a specific type already
@property(nonatomic, copy, readwrite) NSArray<OPArguement *>  *argumentList ;
@end

@implementation OPMethodProducer
- (instancetype)initWithJsapi:(NSString *)jsName
                    className:(NSString *)className
                   methodName:(NSString *)methodName
{
    self = [super init];
    if (self) {
        _jsName = jsName;
        _objectClsName = className;
        _objectMethodName = methodName;
        
        NSArray <OPArguement *> * arguements = nil;
        NSString * targetSelector = OPParseMethodSignature(methodName.UTF8String, &arguements);
        _targetSel = NSSelectorFromString(targetSelector);
        _argumentList = arguements;
    }
    return self;
}

-(void)invokeWithTarget:(id)target andParams:(NSDictionary *)params
{
    NSMethodSignature *signature = [target methodSignatureForSelector:_targetSel];
    if (signature) {
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:target];
        [invocation setSelector:_targetSel];
        
        NSDictionary *callData = params;
        if (![callData isKindOfClass:[NSDictionary class]]) {
            callData = @{};
        }
        NSInteger numberOfArguments = [signature numberOfArguments];
        [invocation retainArguments];
        for (NSInteger i = 2; i < numberOfArguments ; i++) {
            OPArguement *argument = [_argumentList objectAtIndex:i-2];
            const char *argumentType = [signature getArgumentTypeAtIndex:i];
            /**
             nil           |     undefined
             NSNull        |        null
             NSString      |       string
             NSNumber      |   number, boolean
             NSDictionary  |   Object object
             NSArray       |    Array object
             NSDate        |    Date object
             **/
            NSString *argumentName = argument.name;
            NSString *targetArgumentType = argument.type;
            OPNullability nullAbility = argument.nullability;
            id tmpData = [callData objectForKey:argumentName];
            switch(argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                case 'B':{
                    BOOL arg = NO;
                    if([tmpData respondsToSelector:@selector(boolValue)]){
                        arg = [tmpData boolValue];
                    }else{
                        
                    }
                    [invocation setArgument:&arg atIndex:i];
                    break;
                }
                case '@': {
                    if ([targetArgumentType isEqualToString:@"SomeObject"]) {
//                        [invocation setArgument:& atIndex:i]; to process some sepcific logic
                    }else if([targetArgumentType isEqualToString:@"SomeCallback"]){
                        
//                        [invocation setArgument:&block atIndex:i];
                    }else if([argumentName isEqualToString:@"originParam"]){
                        [invocation setArgument:&callData atIndex:i];
                    } else if ([NSClassFromString(targetArgumentType) isSubclassOfClass:NSClassFromString(@"SomeRequestBaseClass")]) {
                        // should be some custom type，we can mapping from dic to obj here
                        id obj = nil;//[[self class] initWithDic:callData type:NSClassFromString(targetArgumentType)];
                        //if maping result is nil, there's somethng wrong happened here
                        if (callData.count != 0 && obj == nil) {
                            //callback error ?
                        } else {
                            //everything seems okay!
                            [invocation setArgument:&obj atIndex:i];
                        }
                    }else{
                        if (nullAbility == OPNullable || nullAbility == OPNullabilityUnspecified) {
                            if ([tmpData isKindOfClass:NSClassFromString(targetArgumentType)]) {
                                [invocation setArgument:&tmpData atIndex:i];
                            }else if(!tmpData){
                                [invocation setArgument:&tmpData atIndex:i];
                            }else{
                                //arguments map error, callback error?
                                //asset here
                            }
                        }else{
                            if ([tmpData isKindOfClass:NSClassFromString(targetArgumentType)]) {
                                [invocation setArgument:&tmpData atIndex:i];
                            }else{
                                // this argument is necessary, but we can't find it in the map dynammically
                                // callback error?
                                return;
                            }
                        }
                    }
                    break;
                }
            }
        }
        [invocation invoke];
    }
}
@end
