#pragma once

#include <string>
#include <vector>

namespace mammon
{
std::vector<unsigned char> readBinaryFromFile (std::string const & filename);

std::string normPath (std::string path);

}
