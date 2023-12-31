//
// Created by william on 2019-04-14.
//

#pragma once
#include <string>
#include <vector>
#include "ae_defs.h"

namespace mammon {

    class MAMMON_EXPORT Parameter {
    public:
        using ParameterList = std::vector<Parameter*>;

        Parameter() = default;
        Parameter(const std::string& key);
        Parameter(const std::string& key, float value);
        Parameter(const std::string& key, float value, float range_min, float range_max);

        Parameter(ParameterList& params, const std::string& key);
        Parameter(ParameterList& params, const std::string& key, float value);
        Parameter(ParameterList& params, const std::string& key, float value, float range_min, float range_max);

        Parameter(const Parameter&) = default;
        Parameter& operator=(const Parameter&) = default;
        Parameter& operator=(float val) {
            value_ = val;
            return *this;
        }
        Parameter& operator=(int val) {
            value_ = static_cast<float>(val);
            return *this;
        }

        float getValue() const;

        void setValue(float v);

        std::string getName() const;

        void getRange(float& min, float& max) const;
        operator float() const {
            return value_;
        }
        bool operator==(const Parameter& p) const;
        bool operator!=(const Parameter& p) const;
        Parameter& operator+=(const Parameter& rhs);
        Parameter& operator-=(const Parameter& rhs);
        Parameter& operator*=(const Parameter& rhs);
        Parameter& operator/=(const Parameter& rhs);
        Parameter& operator+=(float rhs);
        Parameter& operator-=(float rhs);
        Parameter& operator*=(float rhs);
        Parameter& operator/=(float rhs);
        friend float operator+(const Parameter& lhs, const Parameter& rhs) {
            return lhs.getValue() + rhs.getValue();
        }
        friend float operator-(const Parameter& lhs, const Parameter& rhs) {
            return lhs.getValue() - rhs.getValue();
        }
        friend float operator*(const Parameter& lhs, const Parameter& rhs) {
            return lhs.getValue() * rhs.getValue();
        }
        friend float operator/(const Parameter& lhs, const Parameter& rhs) {
            return lhs.getValue() / rhs.getValue();
        }

    private:
        float value_;
        std::string key_;
        float range_min_;
        float range_max_;
    };

    struct ParameterDescriptor {
        enum ParameterType { kFloat, kInt, kString };

        const std::string name;
        ParameterType type;

        const std::string defaultValue;
        const std::string minValue;
        const std::string maxValue;

        const std::string description;
        const std::string unit;

        ParameterDescriptor(std::string n, ParameterType t, std::string defVal, std::string minVal = "0",
                            std::string maxVal = "1", std::string dsc = "", std::string ut = "")
            : name(std::move(n)), type(t), defaultValue(std::move(defVal)), minValue(std::move(minVal)),
              maxValue(std::move(maxVal)), description(std::move(dsc)), unit(std::move(ut)) {
        }

        bool operator==(const ParameterDescriptor& other) const;
    };

#define DEFINE_PARAMETER(key, ...)        Parameter key##_ = {parameters_, #key, __VA_ARGS__};
#define DEF_PARAMETER(var_name, key, ...) Parameter var_name = {parameters_, key, __VA_ARGS__};

}  // namespace mammon
