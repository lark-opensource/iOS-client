//
//  ACCI18NConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by wishes on 2019/12/29.
//

#import <CreativeKit/ACCServiceLocator.h>
#import <Foundation/Foundation.h>

@protocol ACCI18NConfigProtocol <NSObject>

/*
* Current language, change this property when switching languages
*/
@property(nonatomic, copy) NSString *currentLanguage;

/*
* Current region
*/
@property(nonatomic, copy) NSString *currentRegion;


@optional
/*
 If BP implements ACCLanguageProtocol, it may not implement the following methods

* Default priming language languageCode
*/
@property(nonatomic, copy) NSString *defaultLanguage;

/*
* Returns a bundle that overrides the default multilingual resources
*/
@property(nonatomic, strong) NSBundle *languageBundle;

@end

FOUNDATION_STATIC_INLINE id<ACCI18NConfigProtocol> ACCI18NConfig() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCI18NConfigProtocol)];
}
