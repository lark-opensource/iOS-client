//
//  IESJSBridgeCore_Rename.h
//  IESJSBridgeCore-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/2/18.
//

#ifndef IESJSBridgeCore_Rename_h
#define IESJSBridgeCore_Rename_h

#if __has_include(<BDJSBridgeAuthManager/BDJSBridgeAuthManager_Rename.h>)
#import <BDJSBridgeAuthManager/BDJSBridgeAuthManager_Rename.h>
#endif

#define IESJSBridgeStatusCode               IESPiperStatusCode
#define IESJSBridgeStatusCodeUnknownError   IESPiperStatusCodeUnknownError
#define IESJSBridgeStatusCodeManualCallback IESPiperStatusCodeManualCallback
#define IESJSBridgeStatusCodeUndefined      IESPiperStatusCodeUndefined
#define IESJSBridgeStatusCode404            IESPiperStatusCode404
#define IESJSBridgeStatusCodeNamespaceError IESPiperStatusCodeNamespaceError
#define IESJSBridgeStatusCodeParameterError IESPiperStatusCodeParameterError
#define IESJSBridgeStatusCodeNoHandler      IESPiperStatusCodeNoHandler
#define IESJSBridgeStatusCodeNotAuthroized  IESPiperStatusCodeNotAuthroized
#define IESJSBridgeStatusCodeFail           IESPiperStatusCodeFail
#define IESJSBridgeStatusCodeSucceed        IESPiperStatusCodeSucceed

#define IESJSBridge IESPiper
#define IESJSBridgeCoreABTestManager IESPiperCoreABTestManager
#define IWKJSBridgePluginObject IWKPiperPluginObject

#endif /* IESJSBridgeCore_Rename_h */
