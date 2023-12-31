#import <Foundation/Foundation.h>

/// hook -[WKProcessPool init] method to make it singleton. so all WKWebView share content.
/// below iOS 14, cookie may sync to wrong process. iOS 14 seems OK
void makeWKProcessPoolSingleton(void);
void resetSharedWKProcessPool(void);

// catch objc exception and return as NSError
NSError* _Nullable http_objc_catch(void(NS_NOESCAPE ^ _Nonnull action)(void));

