//
//  lltfunc.hpp
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/7.
//

#ifndef lltfunc_hpp
#define lltfunc_hpp

#include <stdio.h>
#include <Accelerate/Accelerate.h>

#ifdef __cplusplus
extern "C" {
#endif
UInt8* specGen(long buffStart,long buffSize,long strideSample,float** audioBufs,long dftWindowSample,long frameIncSample,long coefsNum,long datasize,long longerpolationSample,float *frame,float *hammingWindow,FFTSetup fftSetup,float scale,long resizeX,long resizeY,float lamp,float ramp);
void doInit(long dftWindowSample,long sampleRate,float *hammingWindow,float *scale);
#ifdef __cplusplus
}
#endif

#endif /* lltfunc_hpp */
