//
//  BDTuringSendCodeModel.h
//  BDTuring
//
//  Created by bob on 2021/8/6.
//

#import "BDTuringSMSModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringSendCodeModel : BDTuringSMSModel

@property (nonatomic, assign) NSInteger codeType;
@property (nonatomic, assign) NSInteger eventType;
@property (nonatomic, assign) NSInteger channelID;
/// IDFV
@property (nonatomic, copy) NSString *vid;

@end

NS_ASSUME_NONNULL_END
