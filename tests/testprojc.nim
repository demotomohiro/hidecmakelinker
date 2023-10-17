import libtestc, neolib, testcmakecmd
import hidecmakelinkerpkg/libconf

writeHideCMakeToFile()

doAssert libtestc() == 12345
doAssert neolibProc() == "neolib"

doAssert someDefine == "some define string"
doAssert targetDefine == 98765

echo "test completed!"
