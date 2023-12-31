//
//  BDUGLoggerImpl.h
//  Pods
//
//  Created by shuncheng on 2019/6/18.
//

#import <Foundation/Foundation.h>
#import <BDUGLoggerInterface/BDUGLoggerInterface.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDUGLoggerImpl : NSObject <BDUGLoggerInterface>

+ (instancetype)sharedInstance;

- (void)logMessage:(NSString *)message withLevType:(BDUGLoggerLevType)lev;

@end

NS_ASSUME_NONNULL_END
