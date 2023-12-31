//
//  TTVideoEngineMDLFetcher.h
//  ABRInterface
//
//  Created by kun on 2021/1/19.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineInfoFetcher.h"
#import <MDLMediaDataLoader/AVMDLDataLoader.h>
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineFetcherMaker.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MDLFetchResult) {
    MDLFetchResultSuccess = 0,
    MDLFetchResultFail = -1,
};

static const NSInteger CALLBACK_URLS_TO_MDL = 0;
static const NSInteger MDL_GET_URLS = 1;

@interface TTVideoEngineMDLFetcher : NSObject<AVMDLiOSURLFetcherInterface, TTVideoInfoFetcherDelegate>

@property(nonatomic, copy) NSString * videoID;
@property(nonatomic, copy) NSString * fileHash;
@property(nonatomic, copy) NSString * oldUrl;
@property(nonatomic, copy) NSArray<NSString *> *urls;
@property(nonatomic, strong) TTVideoEngineModel *videomodel;

@property(nonatomic, nullable, strong) TTVideoEngineInfoFetcher *infoFetcher;
@property(nonatomic, nullable, weak) id<AVMDLiOSURLFetcherListener> listener;
@property(nonatomic, nullable, weak) id<TTVideoEngineMDLFetcherDelegate> mdlFetcherDelegate;

- (instancetype)initWithMDLFetcherDelegate:(id<TTVideoEngineMDLFetcherDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
