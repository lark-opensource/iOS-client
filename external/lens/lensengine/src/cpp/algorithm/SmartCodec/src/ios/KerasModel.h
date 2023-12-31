#ifndef KERAS_MODEL__H
#define KERAS_MODEL__H

#include <string>
#include <vector>
#include <fstream>
//#include <iostream>
#include <map>

#define LEN_TI 1
#define LEN_DIS 4
#define LEN_SI 1
#define LEN_GLCM 5
#define LEN_CODEC 3
#define LEN_BLUR 1
#define USE_CODEC_FEATURE 0
#define USE_DIS_FEATURE 0
#define USE_PREDICT_FRAME 1
#define TOTAL_FEATURE_LEN 4+ USE_CODEC_FEATURE*3*LEN_CODEC + (1 + USE_PREDICT_FRAME)*(LEN_TI+LEN_SI+LEN_BLUR+LEN_GLCM + USE_DIS_FEATURE*LEN_DIS)

using namespace std;

enum ResolutionType
{
    R_540P,
    R_720P,
    R_1080P,
    R_other
};

std::map <ResolutionType, std::string> GetTypeMap();

namespace keras
{
	std::vector<float> read_1d_array(std::ifstream &fin, int cols);
	void missing_activation_impl(const std::string &act);
	class DataChunk;
    class DataChunk1D;
	class DataChunk2D;
	class DataChunkFlat;

	class Layer;
	class LayerActivation;
	class LayerDense;

	class KerasModel;
  struct ModelData {
  ModelData(float mean, float std){
    this->mean = mean;
    this->std  = std;
  };
  float mean;
  float std;
  };
  ModelData compute_model_output(KerasModel & m, std::vector<float> data);
  ModelData compute_model_output(KerasModel & m, float* data, int lens);
  
}



class keras::DataChunk {
public:
  virtual ~DataChunk() {}
  virtual size_t get_data_dim(void) const { return 0; }
  virtual std::vector<float> const & get_1d() const { throw "not implemented"; };
  virtual std::vector<std::vector<std::vector<float> > > const & get_3d() const { throw "not implemented"; };
  virtual void set_data(std::vector<std::vector<std::vector<float> > > const &) {};
  virtual void set_data(std::vector<float> const &) {};
  //virtual unsigned int get_count();
  void read_from_file(const std::string &fname) {};
  void show_name();
  void show_values();
};


class keras::DataChunk1D : public keras::DataChunk {
public:
  DataChunk1D() {};
  DataChunk1D(std::vector<float>   const & d) { data = d; };
  std::vector<float>   const & get_1d() const { return data; };
  virtual void set_data(std::vector<float>   const & d) { data = d; };
  size_t get_data_dim(void) const { return 1; }

//  void show_name() {
//    std::cout << "DataChunk1D " << data.size()  << std::endl;
//  }
//
//  void show_values() {
//    std::cout << "DataChunk1D values:" << std::endl;
//    for(size_t i = 0; i < data.size(); ++i) {
//          std::cout << data[i] << " ";
//      std::cout << std::endl;
//      }
//    }
  void preprocess(float* mean,float* std);
  void read_from_file(const std::string &fname);
  std::vector<float>  data; // depth, rows, cols

  int m_cols;
};


class keras::DataChunk2D : public keras::DataChunk {
public:
  std::vector< std::vector< std::vector<float> > > const & get_3d() const { return data; };
  virtual void set_data(std::vector<std::vector<std::vector<float> > > const & d) { data = d; };
  size_t get_data_dim(void) const { return 3; }

//  void show_name() {
//    std::cout << "DataChunk2D " << data.size() << "x" << data[0].size() << "x" << data[0][0].size() << std::endl;
//  }
//
//  void show_values() {
//    std::cout << "DataChunk2D values:" << std::endl;
//    for(size_t i = 0; i < data.size(); ++i) {
//      std::cout << "Kernel " << i << std::endl;
//      for(size_t j = 0; j < data[0].size(); ++j) {
//        for(size_t k = 0; k < data[0][0].size(); ++k) {
//          std::cout << data[i][j][k] << " ";
//        }
//        std::cout << std::endl;
//      }
//    }
//  }
  void read_from_file(const std::string &fname);
  std::vector<std::vector<std::vector<float> > > data; // depth, rows, cols

  int m_depth;
  int m_rows;
  int m_cols;
};

class keras::DataChunkFlat : public keras::DataChunk {
public:
  DataChunkFlat(size_t size) : f(size) { }
  DataChunkFlat(size_t size, float init) : f(size, init) { }
  DataChunkFlat(void) { }

  std::vector<float> f;
  std::vector<float> & get_1d_rw() { return f; }
  std::vector<float> const & get_1d() const { return f; }
  void set_data(std::vector<float> const & d) { f = d; };
  size_t get_data_dim(void) const { return 1; }

//  void show_name() {
//    std::cout << "DataChunkFlat " << f.size() << std::endl;
//  }
//  void show_values() {
//    std::cout << "DataChunkFlat values:" << std::endl;
//    for(size_t i = 0; i < f.size(); ++i) std::cout << f[i] << " ";
//    std::cout << std::endl;
//  }
  void read_from_file(const std::string &fname) {};
  //unsigned int get_count() { return f.size(); }
};

class keras::Layer {
public:
  virtual void load_weights(std::ifstream &fin) = 0;
  virtual keras::DataChunk* compute_output(keras::DataChunk*) = 0;

  Layer(std::string name) : m_name(name) {}
  virtual ~Layer() {}

  virtual unsigned int get_input_rows() const = 0;
  virtual unsigned int get_input_cols() const = 0;
  virtual unsigned int get_output_units() const = 0;

  std::string get_name() { return m_name; }
  std::string m_name;
};


class keras::LayerActivation : public Layer {
public:
  LayerActivation() : Layer("Activation") {}
  void load_weights(std::ifstream &fin);
  keras::DataChunk* compute_output(keras::DataChunk*);

  virtual unsigned int get_input_rows() const { return 0; } // look for the value in the preceding layer
  virtual unsigned int get_input_cols() const { return 0; } // same as for rows
  virtual unsigned int get_output_units() const { return 0; }

  std::string m_activation_type;
};

class keras::LayerDense : public Layer {
public:
  LayerDense() : Layer("Dense") {}

  void load_weights(std::ifstream &fin);
  keras::DataChunk* compute_output(keras::DataChunk*);
  std::vector<std::vector<float> > m_weights; //input, neuron
  std::vector<float> m_bias; // neuron

  virtual unsigned int get_input_rows() const { return 1; } // flat, just one row
  virtual unsigned int get_input_cols() const { return m_input_cnt; }
  virtual unsigned int get_output_units() const { return m_neurons; }

  int m_input_cnt;
  int m_neurons;
};

class keras::KerasModel {
public:
  KerasModel();
  int init(const std::string &input_fname, ResolutionType modeltype, bool verbose);
  ~KerasModel();
  std::vector<float> compute_output(keras::DataChunk *dc);

  unsigned int get_input_rows() const { return m_layers.front()->get_input_rows(); }
  unsigned int get_input_cols() const { return m_layers.front()->get_input_cols(); }
  int get_output_length() const;
  float* get_mean() {return mean;}
  float* get_std()  {return std;}
  float get_thres()  {return thres;}
  void print_statics();
  std::vector<float> softmax(std::vector<float> coff);
  void compute_mean_std_gaussian(std::vector<float> pred, float &mean, float &std);
  float get_cq_for_target_vmaf(float* data, float target,int level);
  float get_default_cq_for_target_vmaf(float target);
  float get_bitrate_for_target_vmaf(float* data, float target, float originalbitrate);


private:
  float fit_curve(float* data, float target, 
  std::vector<float> &datax,std::vector<float> &datay,std::vector<float>& cqs,float &kf_ratio);
  void load_weights(std::ifstream &fin);
  void load_statics(std::ifstream &fin);
  int m_layers_cnt = 0; // number of layers
  std::vector<Layer *> m_layers; // container with layers
  std::map<int,float> threshold;
  std::vector<float> default_cq_parm;
  std::map<int,float> default_cq;
  std::map<char,float> default_cq_ladder; //level-cq
  std::map<char,float> default_bitrate_ladder ;//level-bitrate
  std::map<char,float> default_vmaf_ladder ;//level-vmaf
  std::vector<float> deafault_curve_param;//k,b,t

  bool m_verbose = false;
  int n_feature = 0;
  float * mean = nullptr;
  float * std = nullptr;
  float thres = 0;
  int n_gaussian = 0;
};

#endif
