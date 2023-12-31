//
//  ACCAlgorithmService.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/12/3.
//

#import <Foundation/Foundation.h>

@interface ACCAlgorithmService : NSObject

@property (nonatomic, copy) NSArray<NSString *> *bimAlgorithm;

- (BOOL)isBIMModelReady;
- (void)updateBIMModelWithCompletion:(void (^)(BOOL success))completion;

@end

