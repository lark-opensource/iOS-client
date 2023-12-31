/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Filter Library */
#pragma once

#include "eq.h"

#define NUM_PRESETS     14
#define PRESET_NAME_LEN 64
/* Eqed frequency table */
static const float freq_table_10b[EQ_BANDS_MAX] = {
    31.25, 62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
};
