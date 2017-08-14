# Synopsis Framework
OS X Framework to parse Synopsis metadata, run spotlight searches, and sort results based on metadata contents, and optionaly analyze video and generate metadata dictionaries.

### Dependencies:
* OpenCV 3.3 + (included)
* zstd (included)

Optional:
* Tensorflow 1.2 + (Analysis only).

## Build Instructions

Synopsis framework can be compiled to provide just metadata reading / parsing / comparison - or in addition, providing analysis as well. These two build options are provided because Analysis requires the additional dependency on Tensorflow, which due to size and complexity needs to be compiled seperately.


### Decode (Metadata read only)
To build a decode only Synopsis framework, simply check out the latest git repo, and compile the 'decoder' target. We include a small OpenCV2.framework pre-compiled in the git repo (without IPP)


### Analysis (Metadata generation, analysis, writing and reading)
To compile the with analyzer source, you need to also compile Tensorflow in a manner compatible with the Synopsis build process. You can optionally compile OpenCV with Intel Performance Primitives (IPP) for theoretical performance increases at a cost of 150MB additional binary size due to IPPICV library size. Our included OpenCV2.Framework has IPP disabled for easier deployment and smaller file size.

* OpenCV - please follow the instructions on our wiki https://github.com/Synopsis/Synopsis-Framework/wiki/Building-OpenCV-for-Synopsis - and ensure if you code sign you enable other code signing flags --deep.

* Tensorflow instructions coming.

Place the compiled OpenCV2.framework into the OpenCV subfolder so the XCode project finds it.


