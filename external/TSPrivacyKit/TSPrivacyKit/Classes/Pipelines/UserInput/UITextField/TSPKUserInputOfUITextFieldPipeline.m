//
//  TSPKUserInputOfUITextFieldPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/12/6.
//

#import "TSPKUserInputOfUITextFieldPipeline.h"
#import "TSPKPipelineSwizzleUtil.h"
#import "NSObject+TSAddition.h"
#import <UIKit/UITextField.h>

@implementation UITextField (TSPrivacyKitUserInput)

+ (void)tspk_user_input_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKUserInputOfUITextFieldPipeline class] clazz:self];
}

- (void)tspk_user_input_setDelegate:(id<UITextFieldDelegate>)delegate
{
    [[self class] ts_swzzileMethodWithOrigClass:[delegate class] origSelector:NSSelectorFromString(@"textFieldDidEndEditing:") origBackupSelectorClass:[TSPKUserInputOfUITextFieldPipeline class] newSelector:@selector(tspk_user_input_textFieldDidEndEditing:) newClass:[self class]];
    
    [self tspk_user_input_setDelegate:delegate];
}

- (void)tspk_user_input_textFieldDidEndEditing:(UITextField *)textField
{
    [TSPKUserInputOfUITextFieldPipeline handleAPIAccess:@"textFieldDidEndEditing:" className:[TSPKUserInputOfUITextFieldPipeline stubbedClass] text:textField.text];
    
    [self tspk_user_input_textFieldDidEndEditing:textField];
}

@end

@implementation TSPKUserInputOfUITextFieldPipeline

- (void)textFieldDidEndEditing:(UITextField *)textField
{
}

+ (NSString *)pipelineType
{
    return TSPKPipelineUserInputOfUITextField;
}

+ (NSString *)dataType {
    return TSPKDataTypeUserInput;
}

+ (NSString *)stubbedClass
{
  return @"UITextField";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        @"setDelegate:"
    ];
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UITextField tspk_user_input_preload];
    });
}

@end
