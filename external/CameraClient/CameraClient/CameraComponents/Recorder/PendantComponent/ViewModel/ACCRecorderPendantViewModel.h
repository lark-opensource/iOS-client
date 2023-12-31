//
//  ACCRecorderPendantViewModel.h
//  Indexer
//
//  Created by HuangHongsen on 2021/11/2.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCRecorderPendantDefines.h"

@interface ACCRecorderPendantViewModel : ACCRecorderViewModel

- (NSString * _Nullable)activityID;

- (BOOL)userDidClosePendant;

- (void)checkPendantShouldShowWithCompletion:(void (^)(ACCRecorderPendantResourceType, NSArray * _Nullable, NSDictionary * _Nullable))completion;

- (void)handleUserClosePandent;

- (void)handleUserTapOnPendant;

@end
