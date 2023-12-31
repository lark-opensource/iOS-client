//
//  BDJAudioExceptionOptions.h
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDJTAudioFixType) {
    BDJTAudioFixTypeDisposeDelay = 0,
    BDJTAudioFixTypeUseCache = 1
};

@interface BDJTAudioExceptionOptions : NSObject

@property (nonatomic,assign) BOOL fixAll; //include executable and all app frameworks, default is YES

@property (nonatomic,assign) BOOL fixExecutable; //default is NO

@property (nonatomic,copy) NSArray<NSString *>* fixFrameworks; //framework names

@property (nonatomic,assign) BDJTAudioFixType fixType; //default is BDJTAudioFixTypeDisposeDelay

@end

NS_ASSUME_NONNULL_END
