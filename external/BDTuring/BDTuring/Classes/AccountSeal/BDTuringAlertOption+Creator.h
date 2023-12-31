//
//  BDTuringAlertOption+Creator.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringAlertOption.h"
#import "BDTuringPiperConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringAlertOption (Creator)

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSDictionary *optionDictionary;
@property (atomic, strong) BDTuringPiperOnCallback callback;

+ (NSArray<BDTuringAlertOption *> *)optionsWithArray:(NSDictionary *)parameter
                                            callback:(BDTuringPiperOnCallback)callback;

@end

NS_ASSUME_NONNULL_END
