#import <Foundation/Foundation.h>


typedef NSDictionary<NSString*, NSString*>* (^bef_get_general_param_callback)(NSString* URL);
typedef NSDictionary<NSString*, NSString*>* (^bef_get_header_info_callback)(NSString* URL);
typedef int (^bef_effect_checking_url_callback)(NSString* URL);

enum BEFNetworkUrlType
{
    BEFNetworkUrlIllegal = 0,
    BEFNetworkUrlValid,
    BEFNetworkUrlUndefined
};

@interface BEFGeneralParam : NSObject

+ (void)setParams:(NSDictionary<NSString*, NSString*>*) params;

+ (void)setParam:(NSString*)value withKey:(NSString*)key;

+ (NSString*)getParamByKey:(NSString*)key;

+ (void)setParamCallback:(bef_get_general_param_callback)getParamsFunc;

+ (void)setHeaderCallback:(bef_get_header_info_callback)getHeadersFunc;

+ (void)setCheckUrlCallback:(bef_effect_checking_url_callback)checkUrlFunc;

@end