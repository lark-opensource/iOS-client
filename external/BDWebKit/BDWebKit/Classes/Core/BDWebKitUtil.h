//
//  BDWebKitUtil.h
//  BDWebKit
//
//  Created by wealong on 2020/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebKitUtil : NSObject

// https://stackoverflow.com/questions/8801377/getting-the-default-file-extension-for-a-content-type-in-javascript
+ (NSString *)contentTypeOfExtension:(NSString *)extension;

// process mp4-range-data for offline
+ (NSData *)rangeDataForVideo:(NSData *)fileData withRequest:(NSURLRequest *)request withResponseHeaders:(NSMutableDictionary *)responseHeaders;

/**
 Returns the matched string if a given regular expression matches the beginning characters of the receiver.

 @param string The string to be matched
 @param pattern A regular expression

 @return The matched string
 */
+ (NSString *)prefixMatchesInString:(NSString *)string withPattern:(NSString *) pattern;

@end

BOOL BDWK_isEmptyString(id param);

NS_ASSUME_NONNULL_END
