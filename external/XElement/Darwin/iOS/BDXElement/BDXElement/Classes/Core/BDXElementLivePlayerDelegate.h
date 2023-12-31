//
//  BDXElementLivePlayerDelegate.h
//  BDXElement
//
//  Created by chenweiwei.luna on 2020/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXElementLivePlayerDelegate <NSObject>

- (NSDictionary *)tvlSetting;

@optional
/**
 Enter live room from x-live-ng smoothly
 @param params raw live data
 @param wrapperView LivePlayerView in x-live-ng, for animation
 */
- (void)xliveEnterRoom:(NSDictionary *)params
           wrapperView:(UIView *)wrapperView;
/**
 x-live-ng invoke play method
 @param xliveID unique x-live-ng identifier
 @param logExtra logExtra
 */
- (void)xlive:(NSString *)xliveID didPlay:(nullable NSDictionary *)logExtra;
/**
 x-live-ng invoke stop method
 @param xliveID unique x-live-ng identifier
 @param logExtra logExtra
 */
- (void)xlive:(NSString *)xliveID didStop:(nullable NSDictionary *)logExtra;
/**
 x-live-ng destroyed
 @param xliveID unique x-live-ng identifier
 @param logExtra logExtra
 */
- (void)xlive:(NSString *)xliveID didDestroy:(nullable NSDictionary *)logExtra;
/**
 x-live-ng did receive load state change from IESLivePlayer
 @param xliveID unique x-live-ng identifier
 @param loadState IESLivePlayerLoadState
 @param logExtra logExtra
 */
- (void)xlive:(NSString *)xliveID loadStateDidChange:(NSUInteger)loadState logExtra:(nullable NSDictionary *)logExtra;

/**
 x-live-ng report runtime log
 @param xliveID unique x-live-ng identifier
 @param url report url
 @param params params
 @param logExtra logExtra
 */
- (void)xlive:(NSString *)xliveID reportWithUrl:(nullable NSString *)url params:(nullable NSDictionary *)params logExtra:(nullable NSDictionary *)logExtra;


/**
 app info required by x-live-ng for statistics
 @param logExtra logExtra
 */
- (NSDictionary *)appInfoWithLogExtra:(nullable NSDictionary *)logExtra;
@end

NS_ASSUME_NONNULL_END
