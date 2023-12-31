//
//  IESGurdEventTraceManager+Private.h
//  Pods
//
//  Created by 陈煜钏 on 2020/7/28.
//

#ifndef IESGurdEventTraceManager_Private_h
#define IESGurdEventTraceManager_Private_h

#import "IESGurdEventTraceManager.h"

@class IESGurdTraceMessageInfo, IESGurdTraceNetworkInfo;

typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSMutableArray<IESGurdTraceMessageInfo *> *> *> * IESGurdEventMessagesDictionary;

@interface IESGurdEventTraceManager ()

@property (nonatomic, strong) NSMutableArray<NSString *> *messagesArray;

@property (nonatomic, strong) IESGurdEventMessagesDictionary messagesDictionary;

@property (nonatomic, strong) NSMutableArray<IESGurdTraceNetworkInfo *> *networkInfosArray;

+ (IESGurdEventTraceManager *)sharedManager;

+ (NSString *)formedMessageWithMessage:(NSString *)message;

@end

#endif /* IESGurdEventTraceManager_Private_h */
