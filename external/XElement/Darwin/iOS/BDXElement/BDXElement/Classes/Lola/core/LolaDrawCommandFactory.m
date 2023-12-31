//
//  LolaDrawCommandFactory.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "LolaDrawCommandFactory.h"
#import "LolaDrawCommand.h"

@interface LolaDrawCommandFactory ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray*> *commandPool;

@property (nonatomic, strong) NSMutableArray <LolaDrawCommand*> *currentDrawCommands;

@property (nonatomic, strong) NSMutableArray <LolaDrawCommand*> *appendDrawCommands;

@end

@implementation LolaDrawCommandFactory

+(NSString *)commandClassWithKey:(NSString *)key
{
    static dispatch_once_t onceToken;
    static NSDictionary *commandClass = nil;

    dispatch_once(&onceToken, ^{
        commandClass = @{
            @"fr" : @"FillRectCommand",
            @"ft" : @"FillTextCommand",
            @"st" : @"StrokeTextCommand",
            @"sr" : @"StrokeRectCommand",
            @"sta" :@"StateCommand",
            @"sc" : @"ScaleCommand",
            @"ro" : @"RotateCommand",
            @"ts" : @"TranslateCanvasCommand",
            @"tf" : @"TransformCommand",
            @"ps" : @"PaintSettingCommand",
            @"pas" :@"PathControlCommand",
            @"im" : @"DrawImageCommand",
            @"cr" : @"ClearRectCommand",
            @"cp" : @"ClipPathCommand",
            @"id" : @"ImageDataCommand",
        };
    });
    
    return [commandClass objectForKey:key];
}

- (instancetype)init
{
    if (self = [super init]) {
        _currentDrawCommands = [NSMutableArray new];
        _appendDrawCommands = [NSMutableArray new];
        _commandPool = [NSMutableDictionary new];

    }
    
    return self;
}

-(void)createCommandsWithData:(NSDictionary *)commandsMap context:(LolaDrawContext *)context isAppend:(BOOL)isAppend
{
    if(commandsMap.count <= 0) {
        return;
    }
    
    //when the new commands is coming, clear all old commands
    if (!isAppend) {
        [self recycle:self.currentDrawCommands];
//        drawDataManager.clear()
        [self.currentDrawCommands removeAllObjects];
        for (NSDictionary *commandData in commandsMap) {
            LolaDrawCommand *command = [self translateCommand:commandData context:context];
            if (command) {
                [self.currentDrawCommands addObject:command];
            }
        }
    } else {
        [self recycle:self.appendDrawCommands];
        [self.appendDrawCommands removeAllObjects];
        for (NSDictionary *commandData in commandsMap) {
            LolaDrawCommand *command = [self translateCommand:commandData context:context];
            if (command) {
                [self.appendDrawCommands addObject:command];
            }
        }
    }
}

- (LolaDrawCommand *)translateCommand:(NSDictionary *)commandData context:(LolaDrawContext *)context
{
    NSString *type = commandData[@"tp"];
    LolaDrawCommand *command = [self getCommandFromPool:type];
    if (!command) {
        Class commandClass = NSClassFromString([[self class] commandClassWithKey:type]);
        if (commandClass) {
            command = [commandClass new];
        }
    }
    
    [command configWithData:commandData context:context];
    
    return command;
}

#pragma mark - recycle

- (LolaDrawCommand *)getCommandFromPool:(NSString *)type
{
    if (type.length <= 0) {
        return nil;
    }
    
    LolaDrawCommand *command = nil;
    
    if (self.commandPool) {
        NSMutableArray *list = self.commandPool[type];
        
        if (list.count > 0) {
            command = list.firstObject;
            [list removeObject:command];
        }
    }
    return command;
}

- (void)recycle:(NSArray <LolaDrawCommand *> *)array
{
    for (LolaDrawCommand *command in array) {
        [self doRecyleCommand:command];
    }
}

- (void)doRecyleCommand:(LolaDrawCommand *)command
{
    NSString *type = [command typeStr];
    if (type.length <= 0) {
        return;
    }
        
    NSMutableArray *list = self.commandPool[type];
    
    if (!list) {
        list = [NSMutableArray array];
        [self.commandPool setObject:list forKey:type];
    }
    
    [command recycle];
    [list addObject:command];
}

@end
