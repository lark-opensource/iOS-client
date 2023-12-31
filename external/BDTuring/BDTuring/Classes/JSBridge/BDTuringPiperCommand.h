//
//  BDTuringPiperCommand.h
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import "BDTuringPiperConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringPiperCommand : NSObject

@property (nonatomic, assign) BDTuringPiperType piperType;
@property (nonatomic, copy) NSString *messageType;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *callbackID;
@property (nonatomic, copy) NSDictionary *params;

@property (nonatomic, strong, nullable) BDTuringPiperCallCompletion callCompletion;
@property (nonatomic, strong, nullable) BDTuringPiperOnHandler onHandler;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithName:(NSString *)name onHandler:(BDTuringPiperOnHandler)onHandler;

- (void)addCode:(BDTuringPiperMsg)code response:(nullable NSDictionary *)response type:(NSString *)type;
- (NSString *)toJSONString;

@end

NS_ASSUME_NONNULL_END
