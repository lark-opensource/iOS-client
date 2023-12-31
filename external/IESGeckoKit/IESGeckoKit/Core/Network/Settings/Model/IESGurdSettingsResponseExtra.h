//
//  IESGurdSettingsResponseExtra.h
//  Pods

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsResponseExtra : NSObject

@property (nonatomic, copy) NSArray<NSString *> *noLocalAk;

+ (instancetype)extraWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
