//
//  HMDReference.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/8/6.
//

#import "HMDReference.h"

NSUInteger HMDRetainCount(__kindof NSObject *object) {
    return [object retainCount];
}

__kindof NSObject * HMDRetain(__kindof NSObject *object) {
    return [object retain];
}

void HMDRelease(__kindof NSObject *object) {
    [object release];
}

NSUInteger HMDRetainCountRaw(const void *object) {
    return [(__kindof NSObject *)object retainCount];
}

const void *HMDRetainRaw(const void *object) {
    return [(__kindof NSObject *)object retain];
}

void HMDReleaseRaw(const void *object) {
    [(__kindof NSObject *)object release];
}

