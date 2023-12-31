//
//  ACCPublishRepository.h
//  CameraClient
//
//  Created by Charles on 2020/8/11.
//

#import "ACCPublishRepositoryElementProtocols.h"

#ifndef ACCPublishRepository_h
#define ACCPublishRepository_h

/*
 Regard publishViewModel/DraftModel as a repository, so that business model can be injected into ACCPublishRepository
 element model may conform to ACCPublishRepositoryElementProtocols to gain abilities.
 */

@protocol ACCPublishRepository <NSObject>

@property (nonatomic, strong) NSMutableDictionary *extensionModels;

/// set a model to Repository by it's class,
/// fail if extesionModel is nil.
- (BOOL)setExtensionModelByClass:(id)extensionModel;

- (void)removeExtensionModel:(Class)modelClass;

- (id)extensionModelOfClass:(Class)modelClass;

/// return the first one that conform to protocol
- (id)extensionModelOfProtocol:(Protocol *)protocol;

- (NSMutableDictionary *)deepCopyExtensionModels;

- (void)enumerateExtensionModels:(BOOL)needCopy requireProtocol:(Protocol *)protocol requireSelector:(SEL)sel block:(void (^)(NSString *clzStr, id model, BOOL *stop))block;

- (void)setupRegisteredRepositoryElements;

@end

#endif /* ACCPublishRepository_h */
