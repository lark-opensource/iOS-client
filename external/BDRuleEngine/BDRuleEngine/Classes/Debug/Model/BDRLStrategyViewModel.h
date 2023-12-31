//
//  BDRLStrategyViewModel.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDRLStrategyViewModel;

typedef NS_ENUM(NSUInteger, BDRLStrategyPresentType) {
    BDRLStrategyPresentTypeRaw,
    BDRLStrategyPresentTypeDetail
};

@protocol BDRLJsonViewModelProtocol <NSObject>

- (NSString *)jsonFormat;

@optional

- (BDRLStrategyPresentType)presentType;

@end

@protocol BDRLStrategyViewModelProtocol <NSObject>

@optional

- (NSUInteger)count;

- (NSString *)titleAtIndexPath:(NSIndexPath *)indexPath;

- (BDRLStrategyViewModel *)viewModelAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface BDRLStrategyViewModel : NSObject <BDRLStrategyViewModelProtocol>

@end

NS_ASSUME_NONNULL_END
