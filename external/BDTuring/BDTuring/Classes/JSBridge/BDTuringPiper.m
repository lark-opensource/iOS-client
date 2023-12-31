//
//  BDTuringPiper.m
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDTuringPiperConstant.h"
#import "BDTuringPiperCommand.h"
#import "BDTuringMacro.h"

@interface BDTuringPiper ()<WKScriptMessageHandler>

@property (nonatomic, weak, nullable)  WKWebView *webView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDTuringPiperCommand *> *webOnCommands;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<BDTuringPiperCommand *> *> *nativeOnCommands;

@end

@implementation BDTuringPiper

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        self.webOnCommands = [NSMutableDictionary new];
        self.nativeOnCommands = [NSMutableDictionary new];
        self.webView = webView;
        [webView.configuration.userContentController addScriptMessageHandler:self name:kBDTuringCallMethod];
    }

    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = [message.body isKindOfClass:NSDictionary.class] ? message.body : nil;
    if (!body) {
        return;
    }
    BDTuringPiperCommand *command = [[BDTuringPiperCommand alloc] initWithDictionary:body];
    if (command.piperType == BDTuringPiperTypeCall) {
        [self callNative:command.name command:command];
    } else if (command.piperType == BDTuringPiperTypeOn) {
        [self.webOnCommands setValue:command forKey:command.name];
    } else if (command.piperType == BDTuringPiperTypeOff) {
        [self.webOnCommands removeObjectForKey:command.name];
    }
}

- (NSMutableArray<BDTuringPiperCommand *> *)nativeOnCommandForPiperName:(NSString *)name {
    NSMutableArray<BDTuringPiperCommand *> *result = [NSMutableArray new];
    NSMutableArray<BDTuringPiperCommand *> *commands = [self.nativeOnCommands objectForKey:name];
    if (commands.count > 0) {
        for (BDTuringPiperCommand *nCommand in commands) {
            if (nCommand.onHandler != nil) {
                [result addObject:nCommand];
            }
        }
    }
    
    return result;
}

#pragma mark - Piper function call Native

- (void)callNative:(NSString *)name command:(BDTuringPiperCommand *)command {
    NSMutableArray<BDTuringPiperCommand *> *commands = [self nativeOnCommandForPiperName:name];
    if (commands.count < 1) {
        [command addCode:BDTuringPiperMsgNoHandler response:nil type:BDTuringPiperMsgTypeCallback];
        NSString *invokeJS = [NSString stringWithFormat:@"%@(%@);",kBDTuringPiperJSHandler, [command toJSONString]];
        [self.webView evaluateJavaScript:invokeJS completionHandler:nil];
        return;
    }
    
    for (BDTuringPiperCommand *nCommand in commands) {
        BDTuringWeakSelf;
        BDTuringPiperOnCallback callback = ^(BDTuringPiperMsg msg, NSDictionary *params) {
            BDTuringStrongSelf;
            WKWebView *webView = self.webView;
            if (!webView) {
                return;
            }
            [command addCode:msg response:params type:BDTuringPiperMsgTypeCallback];
            NSString *invokeJS = [NSString stringWithFormat:@"%@(%@);",kBDTuringPiperJSHandler, [command toJSONString]];
            [webView evaluateJavaScript:invokeJS completionHandler:nil];
        };
        nCommand.onHandler([command.params mutableCopy], callback);
    }
}

- (BOOL)webOnPiper:(NSString *)name {
    return [self.webOnCommands objectForKey:name] != nil;
}

#pragma mark - Piper function call JS

- (void)call:(NSString *)name
         msg:(BDTuringPiperMsg)msg
      params:(NSDictionary *)params
  completion:(BDTuringPiperCallCompletion)completion {
    if (![self.webOnCommands objectForKey:name] || !self.webView) {
        if (completion) completion(@"cb404", nil);
        return;
    }
    BDTuringWeakSelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        BDTuringStrongSelf;
        BDTuringPiperCommand *command = [self.webOnCommands objectForKey:name];
        [command addCode:msg response:params type:BDTuringPiperMsgTypeCall];
        NSString *invokeJS = [NSString stringWithFormat:@"%@(%@);",kBDTuringPiperJSHandler, [command toJSONString]];
        [self.webView evaluateJavaScript:invokeJS completionHandler:completion];
    });
}

- (void)on:(NSString *)name callback:(BDTuringPiperOnHandler)callback {
    BDTuringPiperCommand *command = [[BDTuringPiperCommand alloc] initWithName:name onHandler:callback];
    NSMutableArray<BDTuringPiperCommand *> *commands = [self.nativeOnCommands objectForKey:name];
    if (!commands) {
        commands = [NSMutableArray new];
        [self.nativeOnCommands setValue:commands forKey:name];
    }
    [commands addObject:command];
}


@end
