//
// Created by teddy on 11/30/20.
//

#pragma once
#include <stdint.h>
#include <stdlib.h>

#define PEV_NAMESPACE_BEGIN \
    namespace com {         \
    namespace ss {          \
    namespace ttm {         \
    namespace player {

#define PEV_NAMESPACE_END \
    }                     \
    }                     \
    }                     \
    }

#define USE_PEV_NAMESPACE using namespace com::ss::ttm::player;

#define PEV_IPLAYER_VERSION 4
