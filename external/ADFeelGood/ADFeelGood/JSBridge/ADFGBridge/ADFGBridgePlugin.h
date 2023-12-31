//
//  ADFGBridgePlugin.h
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//

#import <Foundation/Foundation.h>
#import "ADFGBridgeEngine.h"

@interface ADFGBridgePlugin : NSObject

/**
 plugin执行时所处的engine
 */
@property (nonatomic, weak) id<ADFGBridgeEngine> engine;


+ (void)_doRegisterIfNeeded;

@end
