#ifndef BVCPARSER_GET_BITS_H
#define BVCPARSER_GET_BITS_H

#include <libavcodec/avcodec.h>
#include <libavutil/avassert.h>
#include <libavutil/intreadwrite.h>


typedef struct BvcGetBitContext {
    const uint8_t *buffer, *buffer_end;
    int index;
    int size_in_bits;
    int size_in_bits_plus8;
} BvcGetBitContext;



/**
 * Initialize BvcGetBitContext.
 * @param buffer bitstream buffer, must be AV_INPUT_BUFFER_PADDING_SIZE bytes
 *        larger than the actual read bits because some optimized bitstream
 *        readers read 32 or 64 bit at once and could read over the end
 * @param bit_size the size of the buffer in bits
 * @return 0 on success, AVERROR_INVALIDDATA if the buffer_size would overflow.
 */
static inline int init_get_bits(BvcGetBitContext *s, const uint8_t *buffer,
                                int bit_size)
{
    int buffer_size;
    int ret = 0;

    if (bit_size >= INT_MAX - FFMAX(7, AV_INPUT_BUFFER_PADDING_SIZE*8) || bit_size < 0 || !buffer) {
        bit_size    = 0;
        buffer      = NULL;
        ret         = AVERROR_INVALIDDATA;
    }

    buffer_size = (bit_size + 7) >> 3;

    s->buffer             = buffer;
    s->size_in_bits       = bit_size;
    s->size_in_bits_plus8 = bit_size + 8;
    s->buffer_end         = buffer + buffer_size;
    s->index              = 0;

    return ret;
}

/**
 * Initialize GetBitContext.
 * @param buffer bitstream buffer, must be AV_INPUT_BUFFER_PADDING_SIZE bytes
 *        larger than the actual read bits because some optimized bitstream
 *        readers read 32 or 64 bit at once and could read over the end
 * @param byte_size the size of the buffer in bytes
 * @return 0 on success, AVERROR_INVALIDDATA if the buffer_size would overflow.
 */
static inline int init_get_bits8(BvcGetBitContext *s, const uint8_t *buffer,
                                 int byte_size)
{
    if (byte_size > INT_MAX / 8 || byte_size < 0)
        byte_size = -1;
    return init_get_bits(s, buffer, byte_size * 8);
}

#define MIN_CACHE_BITS 25

#define OPEN_READER_NOSIZE(name, gb)            \
    unsigned int name ## _index = (gb)->index;  \
    unsigned int av_unused name ## _cache

#define OPEN_READER(name, gb)                   \
    OPEN_READER_NOSIZE(name, gb);               \
    unsigned int name ## _size_plus8 = (gb)->size_in_bits_plus8

#define SKIP_COUNTER(name, gb, num) \
    name ## _index = FFMIN(name ## _size_plus8, name ## _index + (num))

#define LAST_SKIP_BITS(name, gb, num) SKIP_COUNTER(name, gb, num)

#define CLOSE_READER(name, gb) (gb)->index = name ## _index

#define UPDATE_CACHE_BE(name, gb) name ## _cache = \
      AV_RB32((gb)->buffer + (name ## _index >> 3)) << (name ## _index & 7)

#define GET_CACHE(name, gb) ((uint32_t) name ## _cache)

#define UPDATE_CACHE(name, gb) UPDATE_CACHE_BE(name, gb)

#define NEG_USR32(a,s) (((uint32_t)(a))>>(32-(s)))

#define SHOW_UBITS_BE(name, gb, num) NEG_USR32(name ## _cache, num)

#define SHOW_UBITS(name, gb, num) SHOW_UBITS_BE(name, gb, num)

/**
 * Show 1-25 bits.
 */
static inline unsigned int show_bits(BvcGetBitContext *s, int n)
{
    register int tmp;
    OPEN_READER_NOSIZE(re, s);
    av_assert2(n>0 && n<=25);
    UPDATE_CACHE(re, s);
    tmp = SHOW_UBITS(re, s, n);
    return tmp;
}


static inline void skip_bits(BvcGetBitContext *s, int n)
{
    OPEN_READER(re, s);
    LAST_SKIP_BITS(re, s, n);
    CLOSE_READER(re, s);
}

static inline void skip_bits1(BvcGetBitContext *s)
{
    skip_bits(s, 1);
}

/**
 * Read 1-25 bits.
 */
static inline unsigned int get_bits(BvcGetBitContext *s, int n)
{
    register int tmp;
    OPEN_READER(re, s);
    av_assert2(n>0 && n<=25);
    UPDATE_CACHE(re, s);
    tmp = SHOW_UBITS(re, s, n);
    LAST_SKIP_BITS(re, s, n);
    CLOSE_READER(re, s);
    return tmp;
}

static inline unsigned int get_bits1(BvcGetBitContext *s)
{
    unsigned int index = s->index;
    uint8_t result     = s->buffer[index >> 3];

    result <<= index & 7;
    result >>= 8 - 1;
    if (s->index < s->size_in_bits_plus8)
        index++;
    s->index = index;

    return result;
}

/**
 * Read 0-32 bits.
 */
static inline unsigned int get_bits_long(BvcGetBitContext *s, int n)
{
    av_assert2(n>=0 && n<=32);
    if (!n) {
        return 0;
    } else if (n <= MIN_CACHE_BITS) {
        return get_bits(s, n);
    } else {
        unsigned ret = get_bits(s, 16) << (n - 16);
        return ret | get_bits(s, n - 16);
    }
}

static inline int get_bits_count(const BvcGetBitContext *s)
{
    return s->index;
}

static inline int get_bits_left(BvcGetBitContext *gb)
{
    return gb->size_in_bits - get_bits_count(gb);
}

/**
 * Read 0-25 bits.
 */
static av_always_inline int get_bitsz(BvcGetBitContext *s, int n)
{
    return n ? get_bits(s, n) : 0;
}

/**
 * Show 0-32 bits.
 */
static inline unsigned int show_bits_long(BvcGetBitContext *s, int n)
{
    if (n <= MIN_CACHE_BITS) {
        return show_bits(s, n);
    } else {
        BvcGetBitContext gb = *s;
        return get_bits_long(&gb, n);
    }
}


static inline void skip_bits_long(BvcGetBitContext *s, int n)
{
    s->index += av_clip(n, -s->index, s->size_in_bits_plus8 - s->index);
}

/**
 * Read an unsigned Exp-Golomb code in the range 0 to UINT32_MAX-1.
 */
static inline unsigned get_ue_golomb_long(BvcGetBitContext *gb)
{
    unsigned buf, log;

    buf = show_bits_long(gb, 32);
    log = 31 - av_log2(buf);
    skip_bits_long(gb, log);

    return get_bits_long(gb, log + 1) - 1;
}

static inline int get_se_golomb_long(BvcGetBitContext *gb)
{
    unsigned int buf = get_ue_golomb_long(gb);
    int sign = (buf & 1) - 1;
    return ((buf >> 1) ^ sign) + 1;
}


#endif //BVCPARSER_GET_BITS_H