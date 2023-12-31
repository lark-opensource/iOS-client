//
//  BDUGLoggerInterface.h
//  Pods
//
//  Created by shuncheng on 2019/6/18.
//

#import <Foundation/Foundation.h>
#import <BDUGContainer/BDUGContainerProtocol.h>
#import <BDUGContainer/BDUGContainer.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDUGLoggerDebugType,
    BDUGLoggerInfoType,
    BDUGLoggerWarnType,
    BDUGLoggerErrorType,
    BDUGLoggerFatalType,
} BDUGLoggerLevType;

#define BDUGLogger BDUG_CONTAINER_OBJECT(BDUGLoggerInterface)

#define BDUGLoggerContext \
    [NSString stringWithFormat:@"%s\n %s %d\n", __FILE__, __FUNCTION__, __LINE__]

#define BDUGLoggerMessage(msg) \
    [NSString stringWithFormat:@"%@ %@", BDUGLoggerContext, msg]

#define BDUGLoggerDebug(msg) \
do { \
    [BDUGLogger logMessage:BDUGLoggerMessage(msg) withLevType:BDUGLoggerDebugType]; \
} while (0)

#define BDUGLoggerInfo(msg) \
do { \
    [BDUGLogger logMessage:BDUGLoggerMessage(msg) withLevType:BDUGLoggerInfoType]; \
} while (0)

#define BDUGLoggerWarn(msg) \
do { \
    [BDUGLogger logMessage:BDUGLoggerMessage(msg) withLevType:BDUGLoggerWarnType]; \
} while (0)

#define BDUGLoggerError(msg) \
do { \
    [BDUGLogger logMessage:BDUGLoggerMessage(msg) withLevType:BDUGLoggerErrorType]; \
} while (0)

#define BDUGLoggerFatal(msg) \
do { \
    [BDUGLogger logMessage:BDUGLoggerMessage(msg) withLevType:BDUGLoggerFatalType]; \
} while (0)

@protocol BDUGLoggerInterface <BDUGContainerProtocol>

- (void)logMessage:(NSString *)message withLevType:(BDUGLoggerLevType)lev;

@end

NS_ASSUME_NONNULL_END
