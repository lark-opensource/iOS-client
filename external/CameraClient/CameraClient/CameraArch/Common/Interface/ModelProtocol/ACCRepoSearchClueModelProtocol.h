//
//  ACCRepoSearchClueModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by qiyang on 2021/3/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRepoSearchClueModelProtocol <NSObject>

@property (nonatomic, copy) NSString *clueID;
@property (nonatomic, copy) NSArray<NSString *> *extraPublishTagNames;

@end

NS_ASSUME_NONNULL_END
