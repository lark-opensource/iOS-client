#ifndef __SMESH_RESOURCES_PARSER__
#define __SMESH_RESOURCES_PARSER__
/** @brief
 *  Resparser is used to parse merged resources.
 *  Resources (cnn weights or other data files) of a unique sdk should be merged
 * into a single file with explicit version element. A merged resource should be
 * write into file according to the following pattern:
 *  type(int)version(char[less than 255])len1(unsinged
 * int)data(array[len1])len2(unsinged int)data(array[len2]) ... 2018.05.15
 * liuyang.10
 */

#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>

namespace smash {

typedef enum {
  NetResourceType_Base = 0,
  NetResourceType_MultiNet = 1,
  NetResourceType_Face3DMM = 11,
} NetResType;

class BaseNetRes {
  // base class for resource
 public:
  BaseNetRes(){};
  ~BaseNetRes(){};

  int do_parse(const char *res_path, std::string version_string);
  int do_parse_from_bytes(const unsigned char *res_bytes,
                          unsigned int len,
                          std::string version_string);
  int merge_files(const char *res_path, std::string version_string);
  std::string check_type(int type);

 protected:
  int read_data_block(FILE *fp,
                      void **param,
                      unsigned int &len,
                      unsigned int item_size);

  int read_data_block_from_bytes(const unsigned char *res_bytes,
                                 void **param,
                                 unsigned int &len,
                                 unsigned int item_size);

  int write_data_block(FILE *fp,
                       void *param,
                       unsigned int len,
                       unsigned int item_size);

 private:
  ////////////////////////////////////////
  virtual int get_res_type() = 0;
  virtual int init_data_buff(FILE *fp) = 0;
  virtual int init_data_buff_from_bytes(const unsigned char *res_bytes,
                                        unsigned int len) = 0;
  virtual int merge_file(FILE *fp_out) = 0;  // tools to merge files
  //////////////////////////////////////////////////////////////////

 public:
  static const int type = NetResourceType_Base;

 private:
  char version_buff[255];
};

class MultiNetRes : public BaseNetRes {
  // MultiNetRes
 public:
  MultiNetRes(){};
  virtual ~MultiNetRes();

  int set_param_array(int param_block_num);
  unsigned char **get_params_array() { return params_array; }
  unsigned int *get_param_len_array() { return param_len_array; }
  int get_param_block_num() { return param_block_num; }

  int release();

 public:
  static const int type = NetResourceType_MultiNet;

 private:
  int param_block_num = 0;
  unsigned char **params_array = nullptr;
  unsigned int *param_len_array = nullptr;
  ////////////////////////////////
  // virtual functions
  int get_res_type() { return this->type; };
  int init_data_buff(FILE *fp);
  // Cautions: The real length of res_bytes must be carefully checked before
  // send to init_data_buff_from_bytes
  int init_data_buff_from_bytes(const unsigned char *res_bytes,
                                unsigned int len);
  int merge_file(FILE *fp_out);  // temp tools to merge files
  //////////////////////////////////////////////////////////////////
};

}  // namespace smash

#endif
