//
//  BDXPickerView.m
//  BDXElement-Pods-Aweme
//
//  Created by 林茂森 on 2020/8/11.
//

#import "BDXPickerView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import "LynxUI+BDXLynx.h"
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import "BDXPickerColumnView.h"
#import <ByteDanceKit/ByteDanceKit.h>


#define kFontSize 17
#define kFontColor UIColorWithRGB(0, 0, 0)
#define kBorderWidth 1
#define kBorderColor UIColorWithRGB(0, 0, 0)
#define kRowHeight 50

@implementation BDXPickerView


- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)addPickerColumn:(LynxUI *)pickerColumn
{
    [self addSubview:pickerColumn.view];
}

- (void)updateFrameWithDirection:(BOOL) isRtl
{
    NSUInteger len = [self.subviews count];
    for(NSUInteger i = 0;i < len;i++){
        BDXPickerColumnView *pickerColumnView = [self.subviews objectAtIndex:i];
        pickerColumnView.height = self.height?:kRowHeight;
        pickerColumnView.fontSize = self.fontSize?:kFontSize;
        pickerColumnView.fontColor = self.fontColor?:kFontColor;
        pickerColumnView.fontWeight = self.fontWeight;
        pickerColumnView.borderColor = self.borderColor?:kBorderColor;
        pickerColumnView.borderWidth = self.borderWidth?:kBorderWidth;
        // TODO(wujintian): Remove line below to align the behavior on iOS and Android.
        pickerColumnView.frame = CGRectMake(self.frame.size.width / len * (isRtl ? (len - i - 1) : i), 0, self.frame.size.width / len, self.frame.size.height);
        [pickerColumnView reloadPickerFrame];
    }
}

@end

@interface BDXUIPickerView()

@property (nonatomic, copy) NSString *indicatorStyle;

@end

@implementation BDXUIPickerView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-picker-view")
#else
LYNX_REGISTER_UI("x-picker-view")
#endif

LYNX_PROP_SETTER("indicator-style", indicatorStyle, NSString *)
{
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      return;
    }
  
    _indicatorStyle = [value copy];
    
    // trim + spilt
    NSMutableString *str = [[NSMutableString alloc] initWithString:_indicatorStyle];
    str = (NSMutableString *)[str btd_stringByRemoveAllWhitespaceAndNewlineCharacters];
    NSArray *attributeArray = [str componentsSeparatedByString:@";"];
    NSUInteger len = attributeArray.count;
    for(NSUInteger i = 0;i < len;i++){
        NSString *tempStr = [attributeArray objectAtIndex:i];
        if ([tempStr containsString:@":"]) {
            NSArray *attribute = [tempStr componentsSeparatedByString:@":"];
            if ([attribute count] == 2) {
                NSString *fieldName = [attribute objectAtIndex:0];
                NSString *fieldValue = [attribute objectAtIndex:1];
                if ([fieldName isEqualToString:@"height"]) {
                    self.view.height = [LynxUnitUtils toPtFromUnitValue:fieldValue withDefaultPt:0];
                }
                else if ([fieldName isEqualToString:@"font-size"]) {
                    self.view.fontSize = [LynxUnitUtils toPtFromUnitValue:fieldValue withDefaultPt:0];
                }
                else if ([fieldName isEqualToString:@"color"]) {
                    if ([fieldValue hasPrefix:@"#"]) {
                        self.view.fontColor = UIColorWithHexString(fieldValue);
                    }
                }
                else if ([fieldName isEqualToString:@"font-weight"]) {
                    if ([fieldValue isEqualToString:@"bold"]) {
                        self.view.fontWeight = UIFontWeightBold;
                    } else {
                        self.view.fontWeight = UIFontWeightRegular;
                    }
                }
                else if ([fieldName isEqualToString:@"border-width"]) {
                    self.view.borderWidth = [LynxUnitUtils toPtFromUnitValue:fieldValue withDefaultPt:0];
                }
                else if ([fieldName isEqualToString:@"border-color"]) {
                    if([fieldValue hasPrefix:@"#"]) {
                        self.view.borderColor = UIColorWithHexString(fieldValue);
                    }
                }
            }
        }
    }
}

- (UIView *)createView {
    BDXPickerView *view = [[BDXPickerView alloc] init];
    // Disable AutoLayout
    
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    return view;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index
{
    [super didInsertChild:child atIndex:index];
    if([child isKindOfClass:[BDXUIPickerColumnView class]]){
        [self.view addPickerColumn:(LynxUI *)child];
    }
}

- (void)layoutDidFinished
{
    [self.view updateFrameWithDirection:self.isRtl];
}

@end
