//
//  JPEG.c
//  EEImageMagick
//
//  Created by qihongye on 2019/12/5.
//

#include <JPEG.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#ifdef HAVE_UNSIGNED_SHORT
typedef unsigned short UINT16;
#else /* not HAVE_UNSIGNED_SHORT */
typedef unsigned int UINT16;
#endif /* HAVE_UNSIGNED_SHORT */

#define False               0
#define True                (!0)
#define UNDEFINED_QUALITY   (-1)
#define CANNOT_READ_FILE   (-2)
#define NUM_QUANT_TBLS      4 /* Quantization tables are numbered 0..3 */
#define DCTSIZE2            64 /* DCTSIZE squared; # of elements in a block */

#ifdef MIN
#undef MIN
#define MIN(a,b)            (((a) < (b)) ? (a) : (b))
#else
#define MIN(a,b)            (((a) < (b)) ? (a) : (b))
#endif

typedef struct {
    /* This array gives the coefficient quantizers in natural array order
     * (not the zigzag order in which they are stored in a JPEG DQT marker).
     * CAUTION: IJG versions prior to v6a kept this array in zigzag order.
     */
    UINT16 quantval[DCTSIZE2];
    size_t length;
    size_t index;
} JQUANT_TBL;

typedef JQUANT_TBL* JQUANT_TBL_PTRS[NUM_QUANT_TBLS];

BOOL is_jpeg(const unsigned char* data, const size_t length) {
    if (length < 3) {
        return False;
    }
    // Start of jpeg {0xff, 0xd8, 0xff}
    if (memcmp(data, "\377\330\377", 3) == 0) {
        return True;
    }
    return False;
}

static inline
size_t get_jpeg_marker_length(const unsigned char* bytes, const size_t length, BOOL *result) {
    if (length < 1) {
        *result = False;
        return 0;
    }
    *result = True;
    return (((size_t)bytes[0]) << 8) + ((size_t)bytes[1]);
}

static inline
JQUANT_TBL* malloc_quant_tbl(const unsigned char* data, const size_t data_length) {
    if (data_length < 2) {
        return NULL;
    }
    if (data[0] != 0xff || data[1] != 0xdb) {
        return NULL;
    }
    size_t length, index;
    BOOL result;

    length = get_jpeg_marker_length(data + 2, data_length - 2, &result);
    if (!result) {
        return NULL;
    }
    /**
     * Quantization table element precision – Specifies the precision of the Qk values. Value 0 indicates 8-bit Qk
     * values; value 1 indicates 16-bit Qk values. Pq shall be zero for 8 bit sample precision P
     */
    /**
     * Quantization table destination identifier – Specifies one of four possible destinations at the decoder into which
     * the quantization table shall be installed.
     */
    index = (data+4)[0] & 0x0f;

    JQUANT_TBL* tbl = (JQUANT_TBL*)malloc(sizeof(JQUANT_TBL));
    tbl->length = length;
    tbl->index = index;
    length = MIN(DCTSIZE2, length - 3);
    for (index = 0; index < length; index++) {
        if (data_length < index + 5) {
            free(tbl);
            return NULL;
        }
        tbl->quantval[index] = (data+5)[index];
    }
    if (length < DCTSIZE2) {
        memset(tbl->quantval, 0, (DCTSIZE2 - length) * sizeof(UINT16));
    }
    return tbl;
}

static inline
void free_quant_tbl_ptrs(JQUANT_TBL_PTRS jquant_tpl_ptrs) {
    for (ssize_t i = 0; i < NUM_QUANT_TBLS; i++) {
        free(jquant_tpl_ptrs[i]);
    }
}

/// Get quant table ptrs.
/// @param data image data
/// @param length image data length
/// @param jquant_tbl_ptrs quant table ptrs of image
/// @return BOOL is quant table read success.
BOOL get_quant_tbl_ptrs(const unsigned char* data, const size_t length, JQUANT_TBL_PTRS jquant_tbl_ptrs) {
    if (length < 5) {
        return False;
    }
    // Start of jpeg always be 0xff0xd80xff0xe{0..f}, so begin with 4.
    size_t i, app_length;
    JQUANT_TBL* quant_tbl_ptr;

    const unsigned char* jpeg_data = data + 4;
    BOOL app_length_result;

    for (i = 4; i < length; jpeg_data += 2, i += 2) {
        if (jpeg_data[0] != 0xff)
            continue;
        switch (jpeg_data[1]) {
        case 0xc4:  // Start of huffman table {0xff, 0xc4}
        case 0xcc:  // Define arithemtic coding conditioning {0xff, 0xcc}
        case 0xda:  // Start of scans {0xff, 0xda}
        case 0xdc:  // Define number of lines {0xff, 0xdc}
        case 0xdd:  // Define restart interval {0xff, 0xdd}
        case 0xde:  // Define hierarchical progression {0xff, 0xde}
        case 0xdf:  // Expand reference components {0xff, 0xdf}
        case 0xfe:  // Comment
            app_length = get_jpeg_marker_length(jpeg_data + 2, length - 2, &app_length_result);
            if (!app_length_result)
                return False;
            i += app_length;
            jpeg_data += app_length;
            continue;
        case 0xd9:  // End of jpeg {0xff, 0xd9}
            break;
        }
        // default
        if ((jpeg_data[1] >= 0xe0 && jpeg_data[1] <= 0xef)  // APPn ffe0~ffef
            || (jpeg_data[1] >= 0xf0 && jpeg_data[1] <= 0xfd)  // JPGn
            || (jpeg_data[1] >= 0xc0 && jpeg_data[1] <= 0xcf))  // SOFn (Start of frame) {0xff, 0xc0}
        {
            app_length = get_jpeg_marker_length(jpeg_data + 2, length - 2, &app_length_result);
            if (!app_length_result)
                return False;
            i += app_length;
            jpeg_data += app_length;
            continue;
        }
        // quant table
        if (jpeg_data[1] == 0xdb) {
            quant_tbl_ptr = malloc_quant_tbl(jpeg_data, length - i);
            if (quant_tbl_ptr == NULL)
                return False;
            i += quant_tbl_ptr->length;
            jpeg_data += quant_tbl_ptr->length;
            if (quant_tbl_ptr->index <= NUM_QUANT_TBLS) {
                jquant_tbl_ptrs[quant_tbl_ptr->index] = quant_tbl_ptr;
            } else {
                free(quant_tbl_ptr);
            }
        }
    }

    return False;
}

size_t caculate_quality(JQUANT_TBL_PTRS quant_tbl_ptrs) {
    ssize_t j, qvalue, sum, quality;

    register ssize_t i;
    /*
      Determine the JPEG compression quality from the quantization tables.
    */
    quality = UNDEFINED_QUALITY;
    sum = 0;
    for (i = 0; i < NUM_QUANT_TBLS; i++) {
        if (quant_tbl_ptrs[i] != NULL) {
            for (j = 0; j < DCTSIZE2; j++) {
                sum += quant_tbl_ptrs[i]->quantval[j];
            }
        }
    }
    if ((quant_tbl_ptrs[0] != NULL)
        && (quant_tbl_ptrs[1] != NULL)) {
        ssize_t hash[101] = {
            1020, 1015,  932,  848,  780,  735,  702,  679,  660,  645,
            632,  623,  613,  607,  600,  594,  589,  585,  581,  571,
            555,  542,  529,  514,  494,  474,  457,  439,  424,  410,
            397,  386,  373,  364,  351,  341,  334,  324,  317,  309,
            299,  294,  287,  279,  274,  267,  262,  257,  251,  247,
            243,  237,  232,  227,  222,  217,  213,  207,  202,  198,
            192,  188,  183,  177,  173,  168,  163,  157,  153,  148,
            143,  139,  132,  128,  125,  119,  115,  108,  104,   99,
            94,   90,   84,   79,   74,   70,   64,   59,   55,   49,
            45,   40,   34,   30,   25,   20,   15,   11,    6,    4,
            0
        },
            sums[101] = {
            32640, 32635, 32266, 31495, 30665, 29804, 29146, 28599, 28104,
            27670, 27225, 26725, 26210, 25716, 25240, 24789, 24373, 23946,
            23572, 22846, 21801, 20842, 19949, 19121, 18386, 17651, 16998,
            16349, 15800, 15247, 14783, 14321, 13859, 13535, 13081, 12702,
            12423, 12056, 11779, 11513, 11135, 10955, 10676, 10392, 10208,
            9928,  9747,  9564,  9369,  9193,  9017,  8822,  8639,  8458,
            8270,  8084,  7896,  7710,  7527,  7347,  7156,  6977,  6788,
            6607,  6422,  6236,  6054,  5867,  5684,  5495,  5305,  5128,
            4945,  4751,  4638,  4442,  4248,  4065,  3888,  3698,  3509,
            3326,  3139,  2957,  2775,  2586,  2405,  2216,  2037,  1846,
            1666,  1483,  1297,  1109,   927,   735,   554,   375,   201,
            128,     0
        };

        qvalue = (ssize_t)
            (quant_tbl_ptrs[0]->quantval[2]
             + quant_tbl_ptrs[0]->quantval[53]
             + quant_tbl_ptrs[1]->quantval[0]
             + quant_tbl_ptrs[1]->quantval[DCTSIZE2-1]);
        for (i = 0; i < 100; i++) {
            if ((qvalue < hash[i]) && (sum < sums[i]))
                continue;
            if (((qvalue <= hash[i]) && (sum <= sums[i])) || (i >= 50))
                quality = (size_t) i + 1;
            break;
        }
    }
    else if (quant_tbl_ptrs[0] != NULL) {
        ssize_t hash[101] = {
            510,  505,  422,  380,  355,  338,  326,  318,  311,  305,
            300,  297,  293,  291,  288,  286,  284,  283,  281,  280,
            279,  278,  277,  273,  262,  251,  243,  233,  225,  218,
            211,  205,  198,  193,  186,  181,  177,  172,  168,  164,
            158,  156,  152,  148,  145,  142,  139,  136,  133,  131,
            129,  126,  123,  120,  118,  115,  113,  110,  107,  105,
            102,  100,   97,   94,   92,   89,   87,   83,   81,   79,
            76,   74,   70,   68,   66,   63,   61,   57,   55,   52,
            50,   48,   44,   42,   39,   37,   34,   31,   29,   26,
            24,   21,   18,   16,   13,   11,    8,    6,    3,    2,
            0
        },
            sums[101] = {
            16320, 16315, 15946, 15277, 14655, 14073, 13623, 13230, 12859,
            12560, 12240, 11861, 11456, 11081, 10714, 10360, 10027,  9679,
            9368,  9056,  8680,  8331,  7995,  7668,  7376,  7084,  6823,
            6562,  6345,  6125,  5939,  5756,  5571,  5421,  5240,  5086,
            4976,  4829,  4719,  4616,  4463,  4393,  4280,  4166,  4092,
            3980,  3909,  3835,  3755,  3688,  3621,  3541,  3467,  3396,
            3323,  3247,  3170,  3096,  3021,  2952,  2874,  2804,  2727,
            2657,  2583,  2509,  2437,  2362,  2290,  2211,  2136,  2068,
            1996,  1915,  1858,  1773,  1692,  1620,  1552,  1477,  1398,
            1326,  1251,  1179,  1109,  1031,   961,   884,   814,   736,
            667,   592,   518,   441,   369,   292,   221,   151,    86,
            64,     0
        };

        qvalue = (ssize_t)
            (quant_tbl_ptrs[0]->quantval[2]
             + quant_tbl_ptrs[0]->quantval[53]);
        for (i = 0; i < 100; i++) {
            if ((qvalue < hash[i]) && (sum < sums[i]))
                continue;
            if (((qvalue <= hash[i]) && (sum <= sums[i])) || (i >= 50))
                quality = (size_t)i + 1;
            break;
        }
    }
    free_quant_tbl_ptrs(quant_tbl_ptrs);
    return quality;
}

size_t jpeg_get_quality(const unsigned char* data, const size_t length) {
    JQUANT_TBL_PTRS quant_tbl_ptrs = {NULL};
    if (get_quant_tbl_ptrs(data, length, quant_tbl_ptrs))
        return UNDEFINED_QUALITY;
    return caculate_quality(quant_tbl_ptrs);
}

size_t jpeg_get_quality_by_path(const char* path) {
    int fd = open(path, O_RDONLY|O_CREAT, S_IROTH);
    if (fd == -1)
        return CANNOT_READ_FILE;
    int data_len = (int)lseek(fd, 0, SEEK_END);
    const unsigned char *data;
    data = (const unsigned char *) mmap(NULL, data_len, PROT_READ, MAP_PRIVATE, fd, 0);
    if (is_jpeg(data, data_len) != 1) {
        return UNDEFINED_QUALITY;
    }
    JQUANT_TBL_PTRS quant_tbl_ptrs = {NULL};
    close(fd);
    if (get_quant_tbl_ptrs(data, data_len, quant_tbl_ptrs))
        return UNDEFINED_QUALITY;
    return caculate_quality(quant_tbl_ptrs);
}
