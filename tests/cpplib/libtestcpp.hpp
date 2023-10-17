#pragma once

namespace libtestcpp {
  class testcpp {
    public:
      testcpp(int x);

      int getX() const;

    private:
      int x;
  };
}
