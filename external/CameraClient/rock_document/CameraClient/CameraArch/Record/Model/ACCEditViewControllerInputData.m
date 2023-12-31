//
//  ACCEditViewControllerInputData.m
//  Pods
//
//  Created by songxiangwu on 2019/9/6.
//

#import "ACCEditViewControllerInputData.h"
#import <CreationKitArch/ACCRepoContextModel.h>

@implementation ACCEditViewControllerInputData

- (nonnull NSString *)createId {
    return self.publishModel.repoContext.createId;
}

@end
