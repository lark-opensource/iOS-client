//
//  ACCProtocolContainer.h
//  CreationKit
//
//  Created by Howie He on 2021-05-08.
//

#import "NSObject+ACCProtocolContainer.h"
#import "NSProxy+ACCProtocolContainer.h"

#define ACCGetProtocol(obj, proto) ((id<proto>)[(id)obj acc_getProtocol:@protocol(proto)])
