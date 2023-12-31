/**
 * @file AMGDynamicBitset.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Dynamic bitset.
 * @version 0.1
 * @date 2019-12-13
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#pragma once

#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Base class for dynamic bitset.
 * 
 */
class GAIA_LIB_EXPORT DynamicBitsetBase
{
    //typedef std::size_t int32_t; // unsigned int
public:
    /**
     * @brief Alias of uint32_t.
     * 
     */
    typedef uint32_t Block;
    /**
     * @brief The count of bits per block.
     * 
     */
    enum
    {
        /**
         * @brief The count of bits per block.
         * 
         */
        BitsPerBlock = 8 * sizeof(Block)
    };

    /**
     * @brief Construct a new Base Dynamic Bitset.
     * 
     */
    DynamicBitsetBase()
        : m_Bits(0)
        , m_NumBits(0)
        , m_NumBlocks(0)
    {
    }

    /**
     * @brief Construct a new Base Dynamic bitset.
     * 
     * @param numBits The number of bits.
     */
    DynamicBitsetBase(int32_t numBits)
        : m_NumBits(numBits)
        , m_NumBlocks(calcNumBlocks(numBits))
    {
        if (m_NumBlocks != 0)
        {
            m_Bits = new Block[m_NumBlocks];
            memset(m_Bits, 0, m_NumBlocks * sizeof(Block)); // G.P.S
        }
        else
            m_Bits = 0;
    }

    /**
     * @brief Destroy the Base Dynamic Bitset.
     * 
     */
    ~DynamicBitsetBase()
    {
        delete[] m_Bits;
    }

    /**
     * @brief The block array to store all bits data.
     * 
     */
    Block* m_Bits = nullptr;

    /**
     * @brief The number of bits in current bitset.
     * 
     */
    int32_t m_NumBits = 0;

    /**
     * @brief The number of blocks in current bitset.
     * 
     */
    int32_t m_NumBlocks = 0;

    /**
     * @brief The index of block for target bit index.
     * 
     * @param bit Bit index.
     * @return int32_t The index of block.
     */
    static int32_t word(int32_t bit) { return bit / BitsPerBlock; }

    /**
     * @brief The index of offset in block for target bit index.
     * 
     * @param bit Bit index.
     * @return int32_t The index of offset in block.
     */
    static int32_t offset(int32_t bit) { return bit % BitsPerBlock; }

    /**
     * @brief Get a block mask with bit index.
     * 
     * @param bit Bit index.
     * @return Block The block mask.
     */
    static Block mask1(int32_t bit) { return Block(1) << offset(bit); }

    /**
     * @brief Get an inverse block mask with bit index.
     * 
     * @param bit Bit index.
     * @return Block The inverse block mask.
     */
    static Block mask0(int32_t bit) { return ~(Block(1) << offset(bit)); }

    /**
     * @brief Calculate the number of block needed for bits of number numBits.
     * 
     * @param numBits The number of bits.
     * @return int32_t The number of block needed.
     */
    static int32_t calcNumBlocks(int32_t numBits)
    {
        return (numBits + BitsPerBlock - 1) / BitsPerBlock;
    }
};

/**
 * @brief Dynamic biteset.
 * 
 */
class GAIA_LIB_EXPORT DynamicBitset : public DynamicBitsetBase
{
public:
    /**
     * @brief The count of bits per block.
     * 
     */
    enum
    {
        /**
         * @brief The count of bits per block.
         * 
         */
        BitsPerBlock = 8 * sizeof(Block)
    };

    /**
     * @brief Reference to a bit.
     * 
     */
    class Reference
    {
        friend class DynamicBitSet;
        /**
         * @brief The address of bitset include current bit.
         * 
         */
        DynamicBitset* bs;

        /**
         * @brief The index of bit in bitset.
         * 
         */
        int32_t bit;

    public:
        /**
         * @brief Construct a new Bit Reference.
         * 
         */
        Reference(); // intentionally not implemented
        /**
         * @brief Construct a new Reference object.
         * 
         * @param bs_ The reference of bitset.
         * @param bit_ The number of bits.
         */
        Reference(DynamicBitset& bs_, int32_t bit_)
            : bs(&bs_)
            , bit(bit_)
        {
        }

        /**
         * @brief Overload operator=. For b[i] = value.
         * 
         * @param value The value to calculate.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator=(bool value)
        {
            if (value)
                bs->set(bit);
            else
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator|=. For bit[i] |= value.
         * 
         * @param value The value to calculate.
         * @return Reference& Reference of slef, *this.
         */
        Reference& operator|=(bool value)
        {
            if (value)
                bs->set(bit);
            return *this;
        }

        /**
         * @brief Overload operator&=. For bit[i] &= value.
         * 
         * @param value The value to calculate.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator&=(bool value)
        {
            if (!(value && bs->test(bit)))
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator^=. For b[i] ^= x.
         * 
         * @param value The value to calculate.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator^=(bool value)
        {
            bs->set(bit, bs->test(bit) ^ value);
            return *this;
        }

        /**
         * @brief Overload operator-=. For b[i] -= value.
         * 
         * @param value The value to calculate.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator-=(bool value)
        {
            if (!value)
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator=. For b[i] = b[j].
         * 
         * @param j The reference of other bit.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator=(const Reference& j)
        {
            if (j.bs->test(j.bit))
                bs->set(bit);
            else
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator|=. For b[i] |= b[j].
         * 
         * @param j The reference of other bit.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator|=(const Reference& j)
        {
            if (j.bs->test(j.bit))
                bs->set(bit);
            return *this;
        }

        /**
         * @brief Overload operator&=. For b[i] &= b[j].
         * 
         * @param j The reference of other bit.
         * @return Reference& Reference of self, *this.
         */
        Reference& operator&=(const Reference& j)
        {
            if (!(j.bs->test(j.bit) && bs->test(bit)))
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator^=. For b[i] ^= b[j].
         * 
         * @param j The reference of other bit.
         * @return Reference& The reference of self, *this.
         */
        Reference& operator^=(const Reference& j)
        {
            bs->set(bit, bs->test(bit) ^ j.bs->test(j.bit));
            return *this;
        }

        /**
         * @brief Overload operator-=. For b[i] -= b[j].
         * 
         * @param j The reference of other bit.
         * @return Reference& The reference of self, *this.
         */
        Reference& operator-=(const Reference& j)
        {
            if (!j.bs->test(j.bit))
                bs->reset(bit);
            return *this;
        }

        /**
         * @brief Overload operator~. Return the flip of current bit.
         * 
         * @return true Current bit is false.
         * @return false Current bit is true.
         */
        bool operator~() const
        {
            return !bs->test(bit);
        }

        /**
         * @brief Overload operator bool. Return the value of current bit.
         * 
         * @return true Current bit is true.
         * @return false Current bit is false.
         */
        operator bool() const
        {
            return bs->test(bit);
        }

        /**
         * @brief For b[i].flip().
         * 
         * @return Reference& The reference of self, *this.
         */
        Reference& flip()
        {
            bs->flip(bit);
            return *this;
        }
        // ignore next comment
        /**
     * @brief 
     * 
     */
    };

    /**
     * @brief Alias of bool.
     * 
     */
    typedef bool const_reference;

    /**
     * @brief Construct a new Dynamic Bitset.
     * 
     */
    DynamicBitset();

    /**
     * @brief Construct a new Dynamic Bitset.
     * 
     * @param num_Bits The number of bits in current bitset.
     * @param value The init value of current bitset.
     */
    explicit DynamicBitset(int32_t num_Bits, int64_t value = 0);

    /**
     * @brief Construct a new Dynamic Bitset from string.
     * 
     * @tparam String Type of string.
     * @param s The string contains the value fo bitset.
     * @param pos The start index of char in string.
     * @param n The length of string.
     */
    template <typename String>
    explicit DynamicBitset(const String& s, typename String::size_type pos = 0,
                           typename String::size_type n = (String::npos))
        : DynamicBitsetBase(std::min(n, s.size() - pos))
    {
        // Locate sub string
        if (pos > s.size())
        {
            AELOGE(AE_GAME_TAG, "Input pos is Larger than string length!");
            return;
        }
        fromString(s, pos, std::min(n, s.size() - pos));
    }

    /**
     * @brief Construct a new Dynamic Bitset.
     * 
     * @param b Other dynamic bitset.
     */
    DynamicBitset(const DynamicBitset& b);

    /**
     * @brief Swap data of current bitset with b.
     * 
     * @param b The input bitset to swap data.
     */
    void swap(DynamicBitset& b);

    /**
     * @brief Overload operator=. Set data of current bitset with b.
     * 
     * @param b Other bitset to set the data of current bitset.
     * @return DynamicBitset& Reference of self, *this.
     */
    DynamicBitset& operator=(const DynamicBitset& b);

    /**
     * @brief Resize the number of bits in current bitset to num_Bits.
     * 
     * @param num_Bits The number of bits to resize.
     * @param value The value of new bits.
     */
    void resize(int32_t num_Bits, bool value = false);

    /**
     * @brief Clear the data in current bitset.
     * 
     */
    void clear();

    /**
     * @brief Add one bit in the back of current bitset.
     * 
     * @param bit The value of new bit.
     */
    void push_back(bool bit);

    /**
     * @brief Add one block in the back of current bitset.
     * 
     * @param block New added block.
     */
    void append(Block block);

    /**
     * @brief Overload operator&=. For each bit in current bitset a, a[i] &= b[i].
     * 
     * @param b Other bitset.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& operator&=(const DynamicBitset& b);

    /**
     * @brief Overload operator|=. For each bit in current bitset a, a[i] |= b[i].
     * 
     * @param b Other bitset.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& operator|=(const DynamicBitset& b);

    /**
     * @brief Overload operator^=. For each bit in current bitset a, a[i] ^= b[i].
     * 
     * @param b Other bitset.
     * @return DynamicBitset& Refernece of current bitset, *this.
     */
    DynamicBitset& operator^=(const DynamicBitset& b);

    /**
     * @brief Overload operator-=. For each bit in current bitset a, a[i] -= b[i].
     * 
     * @param b Other bitset.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& operator-=(const DynamicBitset& b);

    /**
     * @brief Overload operator<<=. For each bit in current bitset a, a[i] <<= b[i].
     * 
     * @param n The number of <<.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& operator<<=(int32_t n);

    /**
     * @brief Overload operator>>=. For each bit in current bitset a, a[i] >>= b[i].
     * 
     * @param n The number of >>.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& operator>>=(int32_t n);

    /**
     * @brief Overload operator<<. For each bit in current bitset a, a[i] = a[i] << n.
     * 
     * @param n Number of <<.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset operator<<(int32_t n) const;

    /**
     * @brief Overload operator>>. For each bit in current bitset a, a[i] = a[i] >> n.
     * 
     * @param n Number of >>.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset operator>>(int32_t n) const;

    /**
     * @brief Set the value of bit with index n to val.
     * 
     * @param n The index of target bit.
     * @param val Value to set.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& set(int32_t n, bool val = true);

    /**
     * @brief Set all bits in current bitset to true.
     * 
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& set();

    /**
     * @brief Set the value of bit with index n to false.
     * 
     * @param n The index of target bit.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& reset(int32_t n);

    /**
     * @brief Set all bits in current bitset to false.
     * 
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& reset();

    /**
     * @brief Flip the value of bit with index n.
     * 
     * @param n The index of target bit.
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& flip(int32_t n);

    /**
     * @brief Flip the value of all bits in current bitset.
     * 
     * @return DynamicBitset& Reference of current bitset, *this.
     */
    DynamicBitset& flip();

    /**
     * @brief Return the value of bit with index n.
     * 
     * @param n The index of target bit.
     * @return true The value of target bit is true.
     * @return false The value of target bit is false.
     */
    bool test(int32_t n) const;

    /**
     * @brief Return true if value of any bit in current bitset is true.
     * 
     * @return true There exists at least one bit whose value is true in current bitset.
     * @return false There is not bit whose value is true in current bitset.
     */
    bool any() const;

    /**
     * @brief Return true if there is no bit in current bitset whose value is true.
     * 
     * @return true There is no bit in current bitset whose value is true.
     * @return false There exists at least one bit whose value is true in current bitset.
     */
    bool none() const;

    /**
     * @brief Overload operator~. For each bit in current bitset a, a[i] = ~a[i].
     * 
     * @return DynamicBitset 
     */
    DynamicBitset operator~() const;

    /**
     * @brief Overload operator[]. Return the reference of bit with index pos.
     * 
     * @param pos The index of target bit.
     * @return Reference The reference object of target bit.
     */
    Reference operator[](int32_t pos) { return Reference(*this, pos); }

    /**
     * @brief Overload operator[]. Return the value of bit with index pos.
     * 
     * @param pos The index of target bit.
     * @return true The value of target bit is true.
     * @return false The value of target bit is false.
     */
    bool operator[](int32_t pos) const
    {
        if (std::abs(pos) > this->m_NumBits)
        {
            AELOGE(AE_GAME_TAG, "Input pos is Larger than current total bit num!");
            return false;
        }
        return test_(pos);
    }

    /**
     * @brief Return the number of bits in current bitset.
     * 
     * @return int32_t The number of bits in current bitset.
     */
    int32_t size() const;

    /**
     * @brief Return the number of blocks in current bitset.
     * 
     * @return int32_t The number of blocks in current bitset.
     */
    int32_t numBlocks() const;

    /**
     * @brief Return the number of bits in current bitset.
     * 
     * @return int32_t The number of bits in current bitset.
     */
    int32_t numBits() const;

    /**
     * @brief Judge if true value bits in current bitset is subset of other bitset a.
     * 
     * @param a Other bitset.
     * @return true True value bits in current bitset is subset of other bitset a.
     * @return false True value bits in current bitset is not subset of other bitset a.
     */
    bool isSubsetOf(const DynamicBitset& a) const;

    /**
     * @brief Judge if true value bits in current bitset is subset of other bitset a.
     * At least one bit in current bitset is true.
     * @param a Other bitset.
     * @return true True value bits in current bitset is subset of other bitset a.
     * @return false True value bits in current bitset is not subset of other bitset a.
     */
    bool isProperSubsetOf(const DynamicBitset& a) const;

    /**
     * @brief Set the value of unused bits in current bitset to false.
     * 
     */
    void zeroUnusedBits();

    /**
     * @brief Set the value of block with index blocknum to b.
     * 
     * @param blocknum The index of target block.
     * @param b The value of target block to set.
     */
    void setBlock(int32_t blocknum, Block b);

    /**
     * @brief Get the value of block with index blocknum.
     * 
     * @param blocknum The index of target block.
     * @return Block The value of target block.
     */
    Block getBlock(int32_t blocknum) const;

    /**
     * @brief Get the address of blocks array in current bitset.
     * 
     * @return Block* The address of blocks array in current bitset.
     */
    Block* getBuffer() const;

    /**
     * @brief Get memory size of blocks in current bitset.
     * 
     * @return int32_t The memory size of blocks in current bitset.
     */
    int32_t getBufferSize() const;

private:
    void set_(int32_t bit);
    bool set_(int32_t bit, bool val);
    void reset_(int32_t bit);
    bool test_(int32_t bit) const;
    void set_block_(int32_t blocknum, Block b);

public:
    /**
     * @brief Set value of bits in current bitset with string.
     * 
     * @tparam String String type.
     * @param s Input string to set value of current bitset.
     * @param pos The start position of string to set value.
     * @param rlen The length of string to set value.
     */
    template <typename String>
    void fromString(const String& s, typename String::size_type pos,
                    typename String::size_type rlen)
    {
        reset();                                        // bugfix
        int32_t const tot = std::min(rlen, s.length()); // bugfix

        // Assumes string contains only 0's and 1's
        for (int32_t i = 0; i < tot; ++i)
        {
            if (s[pos + tot - i - 1] == '1')
            {
                set_(i);
            }
            else
            {
                if (s[pos + tot - i - 1] != '0')
                {
                    AELOGE(AE_GAME_TAG, "Invald Char %c for Input!", s[pos + tot - i - 1]);
                    return;
                }
            }
        }
    }
};

/**
 * @brief Construct a new Dynamic Bitset.
 * 
 */
inline DynamicBitset::DynamicBitset()
    : DynamicBitsetBase(0)
{
}

/**
 * @brief Construct a new Dynamic Bitset.
 * 
 * @param num_Bits The number of bits.
 * @param value The value of bits.
 */
inline DynamicBitset::DynamicBitset(int32_t num_Bits, int64_t value)
    : DynamicBitsetBase(num_Bits)
{
    const int32_t M = std::min((int32_t)sizeof(int64_t) * 8, num_Bits);
    for (int32_t i = 0; i < M; ++i, value >>= 1) // [G.P.S.] to be optimized
        if (value & 0x1)
            set_(i);
}

/**
 * @brief Copy constructor. Construct a new dynamic bitset.
 * 
 * @param b Other bitset to copy value from.
 */
inline DynamicBitset::DynamicBitset(const DynamicBitset& b)
    : DynamicBitsetBase(b.size())
{
    memcpy(this->m_Bits, b.m_Bits, this->m_NumBlocks * sizeof(Block));
}

/**
 * @brief Swap data of current bitset with b.
 * 
 * @param b The input bitset to swap data.
 */
inline void DynamicBitset::swap(DynamicBitset& b)
{
    std::swap(this->m_Bits, b.m_Bits);
    std::swap(this->m_NumBits, b.m_NumBits);
    std::swap(this->m_NumBlocks, b.m_NumBlocks);
}

/**
 * @brief Overload operator=. Set data of current bitset with b.
 * 
 * @param b Other bitset to set the data of current bitset.
 * @return DynamicBitset& Reference of self, *this.
 */
inline DynamicBitset& DynamicBitset::operator=(const DynamicBitset& b)
{
    DynamicBitset tmp(b);
    this->swap(tmp);
    return *this;
}

/**
 * @brief Resize the number of bits in current bitset to num_Bits.
 * 
 * @param num_Bits The number of bits to resize.
 * @param value The value of new bits.
 */
inline void DynamicBitset::resize(int32_t num_Bits, bool value)
{
    if (num_Bits == size())
        return;
    if (num_Bits == 0)
    {
        this->m_NumBits = 0;
        this->m_NumBlocks = 0;
        delete this->m_Bits;
        this->m_Bits = 0;
        return;
    }
    int32_t new_nblocks = this->calcNumBlocks(num_Bits);
    Block* d = new Block[new_nblocks];
    if (num_Bits < size())
    { // shrink
        std::copy(this->m_Bits, this->m_Bits + new_nblocks, d);
        std::swap(d, this->m_Bits);
        delete[] d;
    }
    else
    { // grow
        std::copy(this->m_Bits, this->m_Bits + this->m_NumBlocks, d);
        Block val = value ? ~static_cast<Block>(0) : static_cast<Block>(0);
        std::fill(d + this->m_NumBlocks, d + new_nblocks, val);
        std::swap(d, this->m_Bits);
        for (int32_t i = this->m_NumBits;
             i < this->m_NumBlocks * BitsPerBlock; ++i)
            set_(i, value);
        if (d != 0)
            delete[] d;
    }
    this->m_NumBits = num_Bits;
    this->m_NumBlocks = this->calcNumBlocks(num_Bits);
    zeroUnusedBits();
}

/**
 * @brief Clear the data in current bitset.
 * 
 */
inline void DynamicBitset::clear()
{
    if (this->m_Bits != 0)
    {
        delete this->m_Bits;
        this->m_Bits = 0;
        this->m_NumBits = 0;
        this->m_NumBlocks = 0;
    }
}

/**
 * @brief Add one bit in the back of current bitset.
 * 
 * @param bit The value of new bit.
 */
inline void DynamicBitset::push_back(bool bit)
{
    this->resize(this->size() + 1);
    set_(this->size() - 1, bit);
}

/**
 * @brief Add one block in the back of current bitset.
 * 
 * @param value New added block.
 */
inline void DynamicBitset::append(Block value)
{
    int32_t old_size = size();
    resize(old_size + BitsPerBlock);
    if (size() % BitsPerBlock == 0)
        set_block_(this->m_NumBlocks - 1, value);
    else
    {
        // G.P.S. to be optimized
        for (int32_t i = old_size; i < size(); ++i, value >>= 1)
            set_(i, value & 1);
    }
}

/**
 * @brief Overload operator&=. For each bit in current bitset a, a[i] &= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator&=(const DynamicBitset& rhs)
{
    if (size() != rhs.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return *this;
    }
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        this->m_Bits[i] &= rhs.m_Bits[i];
    return *this;
}

/**
 * @brief Overload operator|=. For each bit in current bitset a, a[i] |= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator|=(const DynamicBitset& rhs)
{
    if (size() != rhs.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return *this;
    }
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        this->m_Bits[i] |= rhs.m_Bits[i];
    zeroUnusedBits();
    return *this;
}

/**
 * @brief Overload operator^=. For each bit in current bitset a, a[i] ^= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Refernece of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator^=(const DynamicBitset& rhs)
{
    if (size() != rhs.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return *this;
    }
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        this->m_Bits[i] ^= rhs.m_Bits[i];
    zeroUnusedBits();
    return *this;
}

/**
 * @brief Overload operator-=. For each bit in current bitset a, a[i] -= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator-=(const DynamicBitset& rhs)
{
    if (size() != rhs.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return *this;
    }
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        this->m_Bits[i] = this->m_Bits[i] & ~rhs.m_Bits[i];
    zeroUnusedBits();
    return *this;
}

/**
 * @brief Overload operator<<=. For each bit in current bitset a, a[i] <<= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator<<=(int32_t n)
{
    if (n >= this->m_NumBits)
        return reset();
    //else
    if (n > 0)
    {
        int32_t const last = this->m_NumBlocks - 1; // m_NumBlocks is >= 1
        int32_t const div = n / BitsPerBlock;       // div is <= last
        int32_t const r = n % BitsPerBlock;

        // PRE: div != 0  or  r != 0

        if (r != 0)
        {

            Block const rs = BitsPerBlock - r;

            for (int32_t i = last - div; i > 0; --i)
            {
                this->m_Bits[i + div] = (this->m_Bits[i] << r) | (this->m_Bits[i - 1] >> rs);
            }
            this->m_Bits[div] = this->m_Bits[0] << r;
        }
        else
        {
            for (int32_t i = last - div; i > 0; --i)
            {
                this->m_Bits[i + div] = this->m_Bits[i];
            }
            this->m_Bits[div] = this->m_Bits[0];
        }

        // div blocks are zero filled at the less significant end
        std::fill(this->m_Bits, this->m_Bits + div, static_cast<Block>(0));
    }

    return *this;
}

/**
 * @brief Overload operator>>=. For each bit in current bitset a, a[i] >>= b[i].
 * 
 * @param b Other bitset.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::operator>>=(int32_t n)
{
    if (n >= this->m_NumBits)
    {
        return reset();
    }
    //else
    if (n > 0)
    {

        int32_t const last = this->m_NumBlocks - 1; // m_NumBlocks is >= 1
        int32_t const div = n / BitsPerBlock;       // div is <= last
        int32_t const r = n % BitsPerBlock;

        // PRE: div != 0  or  r != 0

        if (r != 0)
        {

            Block const ls = BitsPerBlock - r;

            for (int32_t i = div; i < last; ++i)
            {
                this->m_Bits[i - div] = (this->m_Bits[i] >> r) | (this->m_Bits[i + 1] << ls);
            }
            // r bits go to zero
            this->m_Bits[last - div] = this->m_Bits[last] >> r;
        }

        else
        {
            for (int32_t i = div; i <= last; ++i)
            {
                this->m_Bits[i - div] = this->m_Bits[i];
            }
            // note the '<=': the last iteration 'absorbs'
            // this->m_Bits[last-div] = this->m_Bits[last] >> 0;
        }

        // div blocks are zero filled at the most significant end
        std::fill(this->m_Bits + (this->m_NumBlocks - div), this->m_Bits + this->m_NumBlocks, static_cast<Block>(0));
    }

    return *this;
}

/**
 * @brief Overload operator<<. For each bit in current bitset a, a[i] = a[i] << n.
 * 
 * @param b Number of <<.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset DynamicBitset::operator<<(int32_t n) const
{
    DynamicBitset r(*this);
    return r <<= n;
}

/**
 * @brief Overload operator>>. For each bit in current bitset a, a[i] = a[i] >> n.
 * 
 * @param b Number of >>.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset DynamicBitset::operator>>(int32_t n) const
{
    DynamicBitset r(*this);
    return r >>= n;
}

/**
 * @brief Set the value of bit with index n to val.
 * 
 * @param pos The index of target bit.
 * @param val Value to set.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::set(int32_t pos, bool val)
{
    if (std::abs(pos) >= this->m_NumBits)
    {
        AELOGE(AE_GAME_TAG, "Input pos is Larger than current total bit num!  %d, %d", pos, val);
        return *this;
    }
    set_(pos, val);
    return *this;
}

/**
 * @brief Set all bits in current bitset to true.
 * 
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::set()
{
    if (this->m_NumBits > 0)
    {
        using namespace std;
        memset(this->m_Bits, ~0u, this->m_NumBlocks * sizeof(this->m_Bits[0]));
        zeroUnusedBits();
    }
    return *this;
}

/**
 * @brief Set the value of bit with index n to false.
 * 
 * @param pos The index of target bit.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::reset(int32_t pos)
{
    if (std::abs(pos) >= this->m_NumBits)
    {
        AELOGE(AE_GAME_TAG, "Input pos is Larger than current total bit num!");
        return *this;
    }
    reset_(pos);
    return *this;
}

/**
 * @brief Set all bits in current bitset to false.
 * 
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::reset()
{
    if (this->m_NumBits > 0)
    {
        using namespace std;
        memset(this->m_Bits, 0, this->m_NumBlocks * sizeof(this->m_Bits[0]));
    }
    return *this;
}

/**
 * @brief Flip the value of bit with index n.
 * 
 * @param pos The index of target bit.
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::flip(int32_t pos)
{
    if (std::abs(pos) >= this->m_NumBits)
    {
        AELOGE(AE_GAME_TAG, "Input pos is Larger than current total bit num!");
        return *this;
    }
    // pos = (this->m_NumBits + pos) % this->m_NumBits;
    this->m_Bits[this->word(pos)] ^= this->mask1(pos);
    return *this;
}

/**
 * @brief Flip the value of all bits in current bitset.
 * 
 * @return DynamicBitset& Reference of current bitset, *this.
 */
inline DynamicBitset& DynamicBitset::flip()
{
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        this->m_Bits[i] = ~this->m_Bits[i];
    zeroUnusedBits();
    return *this;
}

/**
 * @brief Return the value of bit with index n.
 * 
 * @param pos The index of target bit.
 * @return true The value of target bit is true.
 * @return false The value of target bit is false.
 */
inline bool DynamicBitset::test(int32_t pos) const
{
    if (std::abs(pos) >= this->m_NumBits)
    {
        // support out of range bit test
        return false;
    }
    return test_(pos);
}

/**
 * @brief Return true if value of any bit in current bitset is true.
 * 
 * @return true There exists at least one bit whose value is true in current bitset.
 * @return false There is not bit whose value is true in current bitset.
 */
inline bool DynamicBitset::any() const
{
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        if (this->m_Bits[i])
            return 1;
    return 0;
}

/**
 * @brief Return true if there is no bit in current bitset whose value is true.
 * 
 * @return true There is no bit in current bitset whose value is true.
 * @return false There exists at least one bit whose value is true in current bitset.
 */
inline bool DynamicBitset::none() const
{
    return !any();
}

/**
 * @brief Overload operator~. For each bit in current bitset a, a[i] = ~a[i].
 * 
 * @return DynamicBitset 
 */
inline DynamicBitset DynamicBitset::operator~() const
{
    DynamicBitset b(*this);
    b.flip();
    return b;
}

/**
 * @brief Return the number of bits in current bitset.
 * 
 * @return int32_t The number of bits in current bitset.
 */
inline int32_t DynamicBitset::size() const
{
    return this->m_NumBits;
}

/**
 * @brief Return the number of blocks in current bitset.
 * 
 * @return int32_t The number of blocks in current bitset.
 */
inline int32_t DynamicBitset::numBlocks() const
{
    return this->m_NumBlocks;
}

/**
 * @brief Return the number of blocks in current bitset.
 * 
 * @return int32_t The number of blocks in current bitset.
 */
inline int32_t DynamicBitset::numBits() const
{
    return this->m_NumBits;
}

/**
 * @brief Judge if true value bits in current bitset is subset of other bitset a.
 * 
 * @param a Other bitset.
 * @return true True value bits in current bitset is subset of other bitset a.
 * @return false True value bits in current bitset is not subset of other bitset a.
 */
inline bool DynamicBitset::isSubsetOf(const DynamicBitset& a) const
{
    if (size() != a.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return false;
    }
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
        if (this->m_Bits[i] & ~a.m_Bits[i])
            return false;
    return true;
}

/**
 * @brief Judge if true value bits in current bitset is subset of other bitset a.
 * At least one bit in current bitset is true.
 * @param a Other bitset.
 * @return true True value bits in current bitset is subset of other bitset a.
 * @return false True value bits in current bitset is not subset of other bitset a.
 */
inline bool DynamicBitset::isProperSubsetOf(const DynamicBitset& a) const
{
    if (size() != a.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return false;
    }
    bool proper = false;
    for (int32_t i = 0; i < this->m_NumBlocks; ++i)
    {
        Block bt = this->m_Bits[i], ba = a.m_Bits[i];
        if (ba & ~bt)
            proper = true;
        if (bt & ~ba)
            return false;
    }
    return proper;
}

/**
 * @brief Overload operator==. Compare the value of bits in a and bits in b.
 * 
 * @param a Compare bitset a.
 * @param b Compare bitset b.
 * @return true The value of bits in bitset a is equal to b.
 * @return false The value of bits in bitset in a is not equal to b.
 */
inline bool operator==(const DynamicBitset& a,
                       const DynamicBitset& b)
{
    using namespace std;
    return (a.m_NumBits == b.m_NumBits) &&
           ((a.m_NumBits == 0) ||
            !memcmp(a.m_Bits, b.m_Bits, a.m_NumBlocks * sizeof(a.m_Bits[0])));
}

/**
 * @brief Overload operator==. Compare the value of bits in a and bits in b.
 * 
 * @param a Compare bitset a.
 * @param b Compare bitset b.
 * @return true The value of bits in bitset a is not equal to b.
 * @return false The value of bits in bitset in a is equal to b.
 */
inline bool operator!=(const DynamicBitset& a,
                       const DynamicBitset& b)
{
    return !(a == b);
}

/**
 * @brief Compare whether the value of bits in a is smaller than b.
 * The value of false is smaller than true.
 * @param a Bitset a.
 * @param b Bitset b.
 * @return true The value of bits in a is smaller than b
 * @return false The value of bits in a is not smaller than b
 */
inline bool operator<(const DynamicBitset& a,
                      const DynamicBitset& b)
{
    if (a.size() != b.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return false;
    }
    //typedef DynamicBitset::int32_t int32_t;

    if (a.size() == 0)
        return false;

    // Since we are storing the most significant bit
    // at pos == size() - 1, we need to do the memcmp in reverse.

    // Compare a block at a time
    for (int32_t i = a.m_NumBlocks - 1; i > 0; --i)
        if (a.m_Bits[i] < b.m_Bits[i])
            return true;
        else if (a.m_Bits[i] > b.m_Bits[i])
            return false;

    if (a.m_Bits[0] < b.m_Bits[0])
        return true;
    else
        return false;
}

/**
 * @brief Compare whether the value of bits in a is larger than b.
 * The value of true is larger than false.
 * @param a Bitset a.
 * @param b Bitset b.
 * @return true The value of bits in a is larger than b
 * @return false The value of bits in a is not larger than b
 */
inline bool operator>(const DynamicBitset& a,
                      const DynamicBitset& b)
{
    if (a.size() != b.size())
    {
        AELOGE(AE_GAME_TAG, "Input bitset size is not equal to target!");
        return false;
    }
    //typedef DynamicBitset::int32_t int32_t;

    if (a.size() == 0)
        return false;

    // Since we are storing the most significant bit
    // at pos == size() - 1, we need to do the memcmp in reverse.

    // Compare a block at a time
    for (int32_t i = a.m_NumBlocks - 1; i > 0; --i)
        if (a.m_Bits[i] < b.m_Bits[i])
            return false;
        else if (a.m_Bits[i] > b.m_Bits[i])
            return true;

    if (a.m_Bits[0] > b.m_Bits[0])
        return true;
    else
        return false;
}

/**
 * @brief For bitset a and b. !(a > b).
 * 
 * @param a Bitset a.
 * @param b Bitset b
 * @return true a <= b
 * @return false a > b
 */
inline bool operator<=(const DynamicBitset& a,
                       const DynamicBitset& b)
{
    return !(a > b);
}

/**
 * @brief For bitset a and b. !(a < b).
 * 
 * @param a Bitset a.
 * @param b Bitset b
 * @return true a >= b
 * @return false a < b
 */
inline bool operator>=(const DynamicBitset& a,
                       const DynamicBitset& b)
{
    return !(a < b);
}

/**
 * @brief Overload operator&. For each bit in bitset x and y, b[i] = x[i] & y[i].
 * 
 * @param x Bitset x.
 * @param y Bitset y.
 * @return DynamicBitset& Result bitset.
 */
inline DynamicBitset operator&(const DynamicBitset& x,
                               const DynamicBitset& y)
{
    DynamicBitset b(x);
    return b &= y;
}

/**
 * @brief Overload operator|. For each bit in bitset x and y, b[i] = x[i] | y[i].
 * 
 * @param x Bitset x.
 * @param y Bitset y.
 * @return DynamicBitset& Result bitset.
 */
inline DynamicBitset operator|(const DynamicBitset& x,
                               const DynamicBitset& y)
{
    DynamicBitset b(x);
    return b |= y;
}

/**
 * @brief Overload operator^. For each bit in bitset x and y, b[i] = x[i] ^ y[i].
 * 
 * @param x Bitset x.
 * @param y Bitset y.
 * @return DynamicBitset& Result bitset.
 */
inline DynamicBitset operator^(const DynamicBitset& x,
                               const DynamicBitset& y)
{
    DynamicBitset b(x);
    return b ^= y;
}

/**
 * @brief Overload operator-. For each bit in bitset x and y, b[i] = x[i] - y[i].
 * 
 * @param x Bitset x.
 * @param y Bitset y.
 * @return DynamicBitset& Result bitset.
 */
inline DynamicBitset operator-(const DynamicBitset& x,
                               const DynamicBitset& y)
{
    DynamicBitset b(x);
    return b -= y;
}

/**
 * @brief Set value of block array with a bitset.
 * 
 * @tparam BlockOutputIterator The iterator of block array.
 * @param b The bitset to get value.
 * @param result The start iterator.
 */
template <typename BlockOutputIterator>
void toBlockRange(const DynamicBitset& b,
                  BlockOutputIterator result)
{
    std::copy(b.m_Bits, b.m_Bits + b.m_NumBlocks, result);
}

/**
 * @brief Set value of bitset with value of block array.
 * 
 * @tparam BlockIterator The iterator of block array.
 * @param first The start of iterator.
 * @param last The end of iterator.
 * @param result The bitset to set value.
 */
template <typename BlockIterator>
inline void fromBlockRange(BlockIterator first, BlockIterator last,
                           DynamicBitset& result)
{
    std::copy(first, last, result.m_Bits);
    result.zeroUnusedBits();
}

/**
 * @brief Set the value of bit with index bit to true.
 * 
 * @param bit The index of target bit.
 */
inline void DynamicBitset::set_(int32_t bit)
{
    //bit = (this->m_NumBits + bit) % this->m_NumBits;
    this->m_Bits[this->word(bit)] |= this->mask1(bit);
}

/**
 * @brief Set the value of block with index blocknum.
 * 
 * @param blocknum The index of target block.
 * @param value The value to set.
 */
inline void DynamicBitset::set_block_(int32_t blocknum, Block value)
{
    this->m_Bits[blocknum] = value;
}

/**
 * @brief Set the value of bit with index b to false.
 * 
 * @param b The index of target bit.
 */
inline void DynamicBitset::reset_(int32_t b)
{
    //b = (this->m_NumBits + b) % this->m_NumBits;
    this->m_Bits[this->word(b)] &= this->mask0(b);
}

/**
 * @brief Return the value of bit with index b.
 * 
 * @param b The index of target bit.
 * @return true The value of target bit is true.
 * @return false The value of target bit is false.
 */
inline bool DynamicBitset::test_(int32_t b) const
{
    //b = (this->m_NumBits + b) % this->m_NumBits;
    return (this->m_Bits[this->word(b)] & this->mask1(b)) != static_cast<Block>(0);
}

/**
 * @brief Set the value of bit with index n in current bitset.
 * 
 * @param n The index of target bitset.
 * @param value The value to set.
 * @return true Value is true.
 * @return false Value is false.
 */
inline bool DynamicBitset::set_(int32_t n, bool value)
{
    if (value)
        set_(n);
    else
        reset_(n);
    return value != static_cast<Block>(0);
}

/**
 * @brief Set the value of unused bits in current bitset to false.
 * 
 */
inline void DynamicBitset::zeroUnusedBits()
{

    // if != 0 this is the number of bits used in the last block
    const int32_t usedBits = this->m_NumBits % BitsPerBlock;

    if (usedBits != 0)
        this->m_Bits[this->m_NumBlocks - 1] &= ~(~static_cast<Block>(0) << usedBits);
}

/**
 * @brief Set the value of block with index blocknum to b.
 * 
 * @param blocknum The index of target block.
 * @param b The value of target block to set.
 */
inline void DynamicBitset::setBlock(int32_t blocknum, Block value)
{
    if (blocknum >= m_NumBlocks)
    {
        AELOGE(AE_GAME_TAG, "Input blocknum is larger than current block num!");
        return;
    }
    m_Bits[blocknum] = value;
}

/**
 * @brief Get the value of block with index blocknum.
 * 
 * @param blocknum The index of target block.
 * @return Block The value of target block.
 */
inline DynamicBitset::Block DynamicBitset::getBlock(int32_t blocknum) const
{
    if (blocknum >= m_NumBlocks)
    {
        AELOGE(AE_GAME_TAG, "Input blocknum is larger than current block num!");
        return 0;
    }
    return m_Bits[blocknum];
}

/**
 * @brief Get the address of blocks array in current bitset.
 * 
 * @return Block* The address of blocks array in current bitset.
 */
inline DynamicBitset::Block* DynamicBitset::getBuffer() const
{
    return m_Bits;
}

/**
 * @brief Get memory size of blocks in current bitset.
 * 
 * @return int32_t The memory size of blocks in current bitset.
 */
inline int32_t DynamicBitset::getBufferSize() const
{
    return m_NumBlocks * sizeof(Block);
}

NAMESPACE_AMAZING_ENGINE_END
