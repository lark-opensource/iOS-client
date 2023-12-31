//
//  EMALocationTool.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/18.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface EMALocationTool : NSObject

+ (void)getLocationWithParams:(NSDictionary *)params completion:(void (^)(CLLocation * _Nullable location))completion;

@end
