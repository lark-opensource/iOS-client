//
//  TSPKUserInputOfUITextViewPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/12/12.
//

#import "TSPKUserInputOfUITextViewPipeline.h"
#import "TSPKPipelineSwizzleUtil.h"
#import "NSObject+TSAddition.h"
#import <UIKit/UITextView.h>

@implementation UITextView (TSPrivacyKitUserInput)

+ (void)tspk_user_input_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKUserInputOfUITextViewPipeline class] clazz:self];
}

- (void)tspk_user_input_setDelegate:(id<UITextViewDelegate>)delegate
{
    [[self class] ts_swzzileMethodWithOrigClass:[delegate class] origSelector:NSSelectorFromString(@"textViewDidEndEditing:") origBackupSelectorClass:[TSPKUserInputOfUITextViewPipeline class] newSelector:@selector(tspk_user_input_textViewDidEndEditing:) newClass:[self class]];
    
    [self tspk_user_input_setDelegate:delegate];
}

- (void)tspk_user_input_textViewDidEndEditing:(UITextView *)textView
{
    [TSPKUserInputOfUITextViewPipeline handleAPIAccess:@"textViewDidEndEditing:" className:[TSPKUserInputOfUITextViewPipeline stubbedClass] text:textView.text];
    
    [self tspk_user_input_textViewDidEndEditing:textView];
}

@end

@implementation TSPKUserInputOfUITextViewPipeline

- (void)textViewDidEndEditing:(UITextView *)textView
{
}

+ (NSString *)pipelineType
{
    return TSPKPipelineUserInputOfUITextView;
}

+ (NSString *)dataType {
    return TSPKDataTypeUserInput;
}

+ (NSString *)stubbedClass
{
  return @"UITextView";
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
        [UITextView tspk_user_input_preload];
    });
}

@end
