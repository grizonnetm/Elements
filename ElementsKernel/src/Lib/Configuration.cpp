/**
 * @file Configuration.cpp
 *
 * @date Feb 8, 2017
 * @author Hubert Degaudenzi
 *
 * @copyright 2012-2020 Euclid Science Ground Segment
 *
 * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version 3.0 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 *
 */

#include "ElementsKernel/Configuration.h"

#include <string>                         // for string
#include <boost/filesystem.hpp>           // for boost::filesystem

#include "ElementsKernel/Path.h"          // for Type and VARIABLE

using std::string;
using boost::filesystem::path;

namespace Elements {


string getConfigurationVariableName() {
  return Path::VARIABLE.at(Path::Type::configuration);
}


// instanciation of the most expected types
template path getConfigurationPath(const path& file_name);
template path getConfigurationPath(const string& file_name);

}  // namespace Elements