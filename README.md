# SynopsisFramework
OS X Framework to parse Synopsis metadata, run spotlight searches, and sort results based on metadata contents.

### Dependencies:
* OpenCV 3.3 + 
* Tensorflow 1.2 + 

## Build Instructions

Due to the size of Tensorflow and OpenCV binaries, they are not included in the source tree. If you want to compile Synopsis.framework from source, you need to also compile OpenCV and Tensorflow in a manner compatible with the Synopsis build process.

* OpenCV - please follow the instructions on our wiki https://github.com/Synopsis/Synopsis-Framework/wiki/Building-OpenCV-for-Synopsis - and ensure if you code sign you enable other code signing flags --deep.

Place the compiled OpenCV2.framework into the OpenCV subfolder so the XCode project finds it.
