/*
 * Copyright 2022 Bytedance Inc.
 * SPDX license identifier: LGPL-2.1-or-later
 *
 *
 * Export private or deprecated symbols
 */

 #include "avcodec.h"


/**
 * Register the codec codec to libavcodec.
 *
 */
int tt_register_avcodec(AVCodec *codec, int codec_size);

