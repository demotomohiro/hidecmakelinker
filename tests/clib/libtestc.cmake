if (NOT LIBTESTC_PATH)
  set(LIBTESTC_PATH ${CMAKE_CURRENT_LIST_DIR})
endif ()

macro(libtestc_init)
  add_library(testc STATIC ${LIBTESTC_PATH}/libtestc.c)
  target_include_directories(testc PUBLIC ${LIBTESTC_PATH})
endmacro()
