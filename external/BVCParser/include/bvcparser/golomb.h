/*
 * Byte VC1 VC2 parser
 */

#ifndef BVCPARSER_GOLOMB_H
#define BVCPARSER_GOLOMB_H


struct BvcGetBitContext;

__attribute__((visibility("default")))
int bvc_get_se_golomb(struct BvcGetBitContext *gb);

__attribute__((visibility("default")))
int bvc_get_ue_golomb(struct BvcGetBitContext *gb);

#endif //BVCPARSER_GOLOMB_H
