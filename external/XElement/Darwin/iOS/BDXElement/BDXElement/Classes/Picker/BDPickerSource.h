//
//  BDPickerSource.h
//  AWEAppConfigurations
//
//  Created by annidy on 2020/5/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBDXPickerSourceModeSelector;
extern NSString *const kBDXPickerSourceModeMultiSelector;
extern NSString *const kBDXPickerSourceModeTime;
extern NSString *const kBDXPickerSourceModeDate;
// TODO(wujintian): Delete legacy code.
extern NSString *const kBDXPickerSourceModeSelectorLegacy;
extern NSString *const kBDXPickerSourceModeMultiSelectorLegacy;
extern NSString *const kBDXPickerSourceModeTimeLegacy;
extern NSString *const kBDXPickerSourceModeDateLegacy;

@interface BDXPickerSource : NSObject

@property NSString *mode;
@property UIColor *cancelColor;
@property UIColor *confirmColor;
@property NSString *title;
@property UIColor *titleColor;
@property CGFloat titleFontSize;
@property NSString *cancelString;
@property NSString *confirmString;

- (NSInteger)numberOfComponents;
- (NSInteger)numberOfRowsInComponent:(NSInteger)component;
- (NSString *)stringValueForRow:(NSInteger)row forComponent:(NSInteger)component;
- (NSArray<NSNumber *> *)valuesRow;

- (NSDate *)startDate;
- (NSDate *)endDate;
- (NSDate *)valueDate;


@end

@interface BDXPickerSelectorSource : BDXPickerSource

@property NSArray *range;

@property NSString *rangeKey;

@property NSNumber *value;

@end

@interface BDXPickerMultiSelectorSource : BDXPickerSource

@property NSArray<NSArray *> *range;

@property NSArray *rangeKey;

@property NSArray<NSNumber *> *value;

@end


@interface BDXPickerDateTimeSource : BDXPickerSource

// "YYYY-MM-DD"
// "hh:mm:ss"

@property NSString *start;

@property NSString *end;

@property NSString *fields; // "year" | "month" | "day"
                            // "hour" | "minute" | "second"
@property NSString *value;

@property NSString *separator;


- (BOOL)isYearAndMonth;

@end

NS_ASSUME_NONNULL_END
