//
//  TSPKUserInputOfYYTextViewPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/12/15.
//

#import "TSPKUserInputOfYYTextViewPipeline.h"
#import "TSPKPipelineSwizzleUtil.h"
#import "NSObject+TSAddition.h"
#import <YYText/YYTextView.h>

@implementation YYTextView (TSPrivacyKitUserInput)

+ (void)tspk_user_input_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKUserInputOfYYTextViewPipeline class] clazz:self];
}

- (void)tspk_user_input_setDelegate:(id<YYTextViewDelegate>)delegate
{
    [[self class] ts_swzzileMethodWithOrigClass:[delegate class] origSelector:NSSelectorFromString(@"textViewDidEndEditing:") origBackupSelectorClass:[TSPKUserInputOfYYTextViewPipeline class] newSelector:@selector(tspk_user_input_textViewDidEndEditing:) newClass:[self class]];
    
    [self tspk_user_input_setDelegate:delegate];
}

- (void)tspk_user_input_textViewDidEndEditing:(YYTextView *)textView
{
    [TSPKUserInputOfYYTextViewPipeline handleAPIAccess:@"textViewDidEndEditing:" className:[TSPKUserInputOfYYTextViewPipeline stubbedClass] text:textView.text];
    
    [self tspk_user_input_textViewDidEndEditing:textView];
}

@end

@implementation TSPKUserInputOfYYTextViewPipeline

- (void)textViewDidEndEditing:(YYTextView *)textView
{
}

+ (NSString *)pipelineType
{
    return TSPKPipelineUserInputOfYYTextView;
}

+ (NSString *)dataType {
    return TSPKDataTypeUserInput;
}

+ (NSString *)stubbedClass
{
  return @"YYTextView";
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
        [YYTextView tspk_user_input_preload];
    });
}

@end
