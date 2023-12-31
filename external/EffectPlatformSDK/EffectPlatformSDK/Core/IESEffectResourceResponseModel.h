//
//  IESEffectResourceResponseModel.h
//  Pods
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "IESEffectResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectResourceResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSArray<IESEffectResourceModel *> *resourceList;
@property (nonatomic, readonly, copy) NSArray<NSString *> *urlPrefixes;
@property (nonatomic, readonly, copy) NSString *iconURI;
@property (nonatomic, readonly, copy) NSArray<NSString *> *iconURLs;
@property (nonatomic, readonly, copy) NSString *idMap;

@property (nonatomic, readonly, copy) NSString *effectId; ///< 本地随机生成
@property (nonatomic, assign) BOOL needTriggerDownload;

- (void)generateAllURLs;
- (NSArray<NSString *> *)allResourcePaths;
- (BOOL)resourcesAllDownloaded;

@end

NS_ASSUME_NONNULL_END
