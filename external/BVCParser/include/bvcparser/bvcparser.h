/*
 * Byte VC1 VC2 parser
 */

#ifndef BYTEVC_PARSER_HEADER
#define BYTEVC_PARSER_HEADER

#define FF_PROFILE_BYTEVC1_MAIN                    1
#define FF_PROFILE_BYTEVC1_MAIN_10                 2
#define FF_PROFILE_BYTEVC1_MAIN_STILL_PICTURE      3
#define FF_PROFILE_BYTEVC1_REXT                    4


__attribute__((visibility("default")))
void register_bvcparser();

#endif //BYTEVC_PARSER_HEADER
