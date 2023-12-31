//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_AMAZING_HOOKS_H_
#define KRYPTON_AMAZING_HOOKS_H_

#include "krypton_effect_hooks.h"
#include "krypton_effect_pfunc.h"

namespace lynx {
namespace canvas {
namespace effect {

void DownloadModel(void*, const char*[], int, const char*,
                   bef_download_model_callback, void*);

void DownloadSticker(void*, const char*, bef_download_sticker_callback, void*);

bef_resource_finder GetResourceFinder(void*);

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_AMAZING_HOOKS_H_ */
