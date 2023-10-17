import libtestcpp
import libtestc
import hidecmakelinkerpkg/libconf

writeHideCMakeToFile()

proc test() =
  let x = initTestcpp(54321)
  doAssert x.getX() == 54321 + 123

  doAssert libtestc() == 12345

  echo "test completed"

test()
