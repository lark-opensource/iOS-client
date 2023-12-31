//
//  BDTuringPictureVerifyModel.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringPictureVerifyModel : BDTuringVerifyModel

@property (nonatomic, assign) CGFloat defaultWidth;
@property (nonatomic, assign) CGFloat defaultHeight;

+ (instancetype)modelWithCode:(NSInteger)challengeCode;

@end

NS_ASSUME_NONNULL_END
