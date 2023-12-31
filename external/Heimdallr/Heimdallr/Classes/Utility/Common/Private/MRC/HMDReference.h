//
//  HMDReference.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/8/6.
//

#import <Foundation/Foundation.h>

NSUInteger HMDRetainCount(__kindof NSObject *object);

__kindof NSObject * HMDRetain(__kindof NSObject *object);

void HMDRelease(__kindof NSObject *object);

NSUInteger HMDRetainCountRaw(const void *object);

const void *HMDRetainRaw(const void *object);

void HMDReleaseRaw(const void *object);
