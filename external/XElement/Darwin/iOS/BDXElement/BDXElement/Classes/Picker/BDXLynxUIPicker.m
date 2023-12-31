//
//  BDXLynxUIPicker.m
//  BDXElement
//
//  Created by annidy on 2020/5/12.
//

#import "BDXLynxUIPicker.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxColorUtils.h>
#import "BDXPickerSheetView.h"

@interface BDXLynxUIPicker()<BDXPickerSheetViewDelegate>
@property NSString *mode;
@property NSArray *range;
@property id rangeKey;
@property id value;
@property NSString *start;
@property NSString *end;
@property NSString *fields;
@property NSString *separator;

@property UIColor *cancelColor;
@property UIColor *confirmColor;
@property NSString *title;
@property UIColor *titleColor;
@property CGFloat titleFontSize;
@property NSString *cancelString;
@property NSString *confirmString;

@property BDXPickerSource *source;
@end

@implementation BDXLynxUIPicker

- (instancetype)init {
    if (self = [super init]) {
      _fields = @"day";
      _cancelColor = nil;
      _confirmColor = nil;
      _title = nil;
      _titleColor = nil;
      _titleFontSize = [UIFont buttonFontSize];
      _cancelString = @"Cancel";
      _confirmString = @"Confirm";
    }
    return self;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("picker")
#else
LYNX_REGISTER_UI("picker")
#endif

- (UIView *)createView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    // Disable AutoLayout
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(show)];
    [view addGestureRecognizer:tap];
    view.userInteractionEnabled = YES;
    return view;
}

LYNX_PROP_SETTER("mode", mode, NSString*) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _mode = nil;
      return;
    }
    _mode = [value copy];
}

LYNX_PROP_SETTER("disabled", disabled, BOOL) {
    self.view.userInteractionEnabled = !value;
}

LYNX_PROP_SETTER("range", range, NSArray *) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _range = nil;
      return;
    }
    _range = [value copy];
}

LYNX_PROP_SETTER("range-key", rangeKey, NSArray *) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _rangeKey = nil;
      return;
    }
    _rangeKey = [value copy];
}

LYNX_PROP_SETTER("value", value, id) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _value = nil;
      return;
    }
    if ([value isKindOfClass:[NSNumber class]] ||
        [value isKindOfClass:[NSArray class]]
        || [value isKindOfClass:[NSString class]]) {
        _value = [value copy];
    }
}

LYNX_PROP_SETTER("start", start, NSString *) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _start = nil;
      return;
    }
    _start = [value copy];
}

LYNX_PROP_SETTER("end", end, NSString *) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _end = nil;
      return;
    }
    _end = [value copy];
}

LYNX_PROP_SETTER("fields", fields, NSString *) {
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
        _fields = @"day";
        return;
    }
    _fields = [value copy];
}

LYNX_PROP_SETTER("separator", separator, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _separator = nil;
      return;
    }
    _separator = [value copy];
}

LYNX_PROP_SETTER("cancel-string", cancelString, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _cancelString = @"Cancel";
      return;
    }
    _cancelString = [value copy];
}

LYNX_PROP_SETTER("confirm-string", confirmString, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _confirmString = @"Confirm";
      return;
    }
    _confirmString = [value copy];
}

LYNX_PROP_SETTER("cancel-color", cancelColor, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _cancelColor = nil;
      return;
    }
    _cancelColor = [LynxColorUtils convertNSStringToUIColor:value];
}

LYNX_PROP_SETTER("confirm-color", confirmColor, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _confirmColor = nil;
      return;
    }
    _confirmColor = [LynxColorUtils convertNSStringToUIColor:value];
}

LYNX_PROP_SETTER("title", title, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _title = nil;
      return;
    }
    _title = [value copy];
}

LYNX_PROP_SETTER("title-color", titleColor, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _titleColor = nil;
      return;
    }
    _titleColor = [LynxColorUtils convertNSStringToUIColor:value];
}

LYNX_PROP_SETTER("title-font-size", titleFontSize, NSString *){
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      _titleFontSize = [UIFont buttonFontSize];
      return;
    }
    _titleFontSize = [LynxUnitUtils toPtFromUnitValue:value withDefaultPt:[UIFont buttonFontSize]];
}

- (void)show {
    void (^generalPropsSetter)(BDXPickerSource* source) = ^(BDXPickerSource* source) {
        source.mode = self.mode;
        source.cancelColor = self.cancelColor;
        source.confirmColor = self.confirmColor;
        source.cancelString = self.cancelString;
        source.confirmString = self.confirmString;
        source.title = self.title;
        source.titleColor = self.titleColor;
        source.titleFontSize = self.titleFontSize;
    };
    if ([_mode isEqualToString:kBDXPickerSourceModeSelector] || [_mode isEqualToString:kBDXPickerSourceModeSelectorLegacy] || !_mode) {
        _source = ({
            BDXPickerSelectorSource *s = [[BDXPickerSelectorSource alloc] init];
            generalPropsSetter(s);
            s.range = _range;
            if ([_rangeKey isKindOfClass:[NSString class]]) {
                s.rangeKey = (NSString *)_rangeKey;
            }
            if ([_value isKindOfClass:[NSNumber class]]) {
                s.value = (NSNumber *)_value;
            }
            s;
        });
    } else if ([_mode isEqualToString:kBDXPickerSourceModeMultiSelector] || [_mode isEqualToString:kBDXPickerSourceModeMultiSelectorLegacy]) {
        _source = ({
            BDXPickerMultiSelectorSource *s = [[BDXPickerMultiSelectorSource alloc] init];
            generalPropsSetter(s);
            s.range = _range;
            if ([_rangeKey isKindOfClass:[NSArray class]]) {
                s.rangeKey = (NSArray *)_rangeKey;
            }
            if ([_value isKindOfClass:[NSArray class]]) {
                s.value = (NSArray *)_value;
            }
            s;
        });
    } else if ([_mode isEqualToString:kBDXPickerSourceModeTime] || [_mode isEqualToString:kBDXPickerSourceModeDate] || [_mode isEqualToString:kBDXPickerSourceModeTimeLegacy] || [_mode isEqualToString:kBDXPickerSourceModeDateLegacy]) {
        _source = ({
            BDXPickerDateTimeSource *s = [[BDXPickerDateTimeSource alloc] init];
            generalPropsSetter(s);
            s.start = _start;
            s.end = _end;
            s.fields = _fields;
            s.separator = _separator;
            if([_value isKindOfClass:[NSString class]]){
                s.value = _value;
            } else if(_start) {
                s.value = _start;
            }
            s;
        });
    } 
    BDXPickerSheetView *sheet = [[BDXPickerSheetView alloc] initWithFrame:CGRectZero];
    sheet.dataSource = _source;
    sheet.delegate = self;
    sheet.showInWindow = self.showInWindow;
    [sheet showInView:self.view];
}

- (void)onPickerSheetCancel:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"cancel" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)onPickerSheetChanged:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res
{
  // TODO(wujintian): Delete legacy code.
  if ([_mode isEqualToString:kBDXPickerSourceModeMultiSelectorLegacy]) {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
  } else {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"columnchange" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
  }
}

- (void)onPickerSheetConfirm:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res
{
  // TODO(wujintian): Delete legacy code.
  if ([_mode isEqualToString:kBDXPickerSourceModeSelectorLegacy] || [_mode isEqualToString:kBDXPickerSourceModeMultiSelectorLegacy] || [_mode isEqualToString:kBDXPickerSourceModeTimeLegacy] || [_mode isEqualToString:kBDXPickerSourceModeDateLegacy]) {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"confirm" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
  } else {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
  }
}
@end
