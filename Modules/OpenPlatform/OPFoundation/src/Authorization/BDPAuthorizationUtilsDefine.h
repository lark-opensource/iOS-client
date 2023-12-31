//
//  BDPAuthorizationUtilsDefine.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#ifndef BDPAuthorizationUtilsDefine_h
#define BDPAuthorizationUtilsDefine_h

#define STRINGFY(arg) #arg
#define _BDPScopePrefix_ scope
#define BDPScopePrefix_(arg) @STRINGFY(arg.)
#define BDPScopePrefix BDPScopePrefix_(_BDPScopePrefix_)
#define BDPScope_(PREFIX, SCOPE) @STRINGFY(PREFIX.SCOPE)
#define BDPScope(SCOPE) BDPScope_(_BDPScopePrefix_, SCOPE)

#define AUTH_COMPLETE(...) \
if (completion) {\
    completion(__VA_ARGS__);\
}\

FOUNDATION_EXPORT NSString *const kBDPAuthFailedScopeStorageKey;

#endif /* BDPAuthorizationUtilsDefine_h */
