#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Runtime/RenderLib/ComputerDevice.h"
#import "Runtime/RenderLib/FlipPatcher_texture_info.h"
#import "Runtime/RenderLib/GLES_API_Logger.h"
#import "Runtime/RenderLib/GLES_API_Player.h"
#import "Runtime/RenderLib/GPDevice.h"
#import "Runtime/RenderLib/GPDeviceType.h"
#import "Runtime/RenderLib/MaterialType.h"
#import "Runtime/RenderLib/PatcherUtils.h"
#import "Runtime/RenderLib/PipelineState.h"
#import "Runtime/RenderLib/PropertyBlock.h"
#import "Runtime/RenderLib/RendererDevice.h"
#import "Runtime/RenderLib/RendererDeviceTypes.h"
#import "Runtime/RenderLib/ShaderPatcher.h"
#import "Runtime/RenderLib/Utils.h"
#import "Runtime/RenderLib/VertexAttribDesc.h"
#import "Runtime/RenderLib/logger_player_env.h"

FOUNDATION_EXPORT double AGFX_pubVersionNumber;
FOUNDATION_EXPORT const unsigned char AGFX_pubVersionString[];