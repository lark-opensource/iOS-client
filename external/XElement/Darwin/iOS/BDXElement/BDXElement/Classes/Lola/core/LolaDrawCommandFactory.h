//
//  LolaDrawCommandFactory.h
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LolaDrawCommand, LolaDrawContext;

NS_ASSUME_NONNULL_BEGIN

@interface LolaDrawCommandFactory : NSObject

@property (nonatomic, strong, readonly) NSMutableArray <LolaDrawCommand*> *currentDrawCommands;

@property (nonatomic, strong, readonly) NSMutableArray <LolaDrawCommand*> *appendDrawCommands;

-(void)createCommandsWithData:(NSDictionary *)commandsMap context:(LolaDrawContext *)context isAppend:(BOOL)isAppend;

@end

NS_ASSUME_NONNULL_END
