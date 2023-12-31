//
//  BDXVideoPlayerVideoModel.h
//  BDXElement
//
//  Created by bill on 2020/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXVideoPlayerAPIVersion) {
    BDXVideoPlayerAPIVersion1,
    BDXVideoPlayerAPIVersion2,
};

@interface BDXVideoPlayerVideoModel : NSObject

@property (nonatomic, assign) BOOL isCanPlay; // allow to play
@property (nonatomic, copy)   NSString *itemID;
@property (nonatomic, copy)   NSString *playUrlString;
@property (nonatomic, assign) BOOL repeated; // default NO
@property (nonatomic, copy)   NSString *customhost;
@property (nonatomic, copy)   NSString *playAutoToken;
@property (nonatomic, copy)   NSString *playerVersion;
@property (nonatomic, copy)   NSString *protocolVer;
@property (nonatomic, strong) NSArray<NSString *> *hosts;

@property (nonatomic, assign) BDXVideoPlayerAPIVersion apiVersion;

@end

NS_ASSUME_NONNULL_END
