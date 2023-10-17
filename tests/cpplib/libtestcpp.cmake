if (NOT LIBTESTCPP_PATH)
  set(LIBTESTCPP_PATH ${CMAKE_CURRENT_LIST_DIR})
endif ()

macro(libtestcpp_init)
  add_library(testcpp STATIC ${LIBTESTCPP_PATH}/libtestcpp.cpp)
  target_include_directories(testcpp PUBLIC ${LIBTESTCPP_PATH})
endmacro()
