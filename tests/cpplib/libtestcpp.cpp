#include "libtestcpp.hpp"

namespace libtestcpp {
  testcpp::testcpp(int x): x(x) {}

  int testcpp::getX() const {
    return x + 123;
  }
}
