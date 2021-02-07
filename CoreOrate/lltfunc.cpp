#include "lltfunc.hpp"
#include "jet.cpp"
#include <Accelerate/Accelerate.h>
#include <vector>
#include <iostream>
typedef long long ll;
using namespace std;
inline float bufAccess(long x,long buffStart,long buffSize,long strideSample, float** audioBufs) {
    return audioBufs[(int)(buffStart+floor((double)x/(double)strideSample))%buffSize][x%strideSample];
}
void doInit(long dftWindowSample,long sampleRate,float *hammingWindow,float *scale) {
    cout<<" "<<hammingWindow<<endl;
    double hammingCorrectCoefficient=0;
    for (ll i=0;i<dftWindowSample;i++) {
        hammingWindow[i]=0.53836-(1-0.53836)*cos(2.0*M_PI*i/(double)(dftWindowSample-1));
        hammingCorrectCoefficient+=hammingWindow[i]*hammingWindow[i];
    }
    *scale=0.5*sampleRate*hammingCorrectCoefficient;
}
UInt8* specGen(long buffStart,long buffSize,long strideSample,float** audioBufs,long dftWindowSample,long frameIncSample,long coefsNum,long datasize,long interpolationSample,float *frame,float *hammingWindow,FFTSetup fftSetup,float scale,long resizeX,long resizeY,float lamp,float ramp) {
    ll log2n=log2(interpolationSample);
    //signal process
    vector<float*>spectr;
    for (ll i=dftWindowSample/2;1;i+=frameIncSample) { //if dftWindowSample is odd then take the lower bound!
        float *coefs=new float[coefsNum];
        ll leftEdg=i-dftWindowSample/2;
        ll rightEdg=(frameIncSample%2?i+dftWindowSample/2:i+dftWindowSample/2+1);
        if (rightEdg>=datasize) {
            delete[] coefs;
            break;
        }
        
        //leftEdg...rightEdg (inclusive)
        for (ll j=leftEdg;j<=rightEdg;j++) {
            frame[j-leftEdg]=bufAccess(j, buffStart, buffSize, strideSample, audioBufs);
            //hamming window
            frame[j-leftEdg]*=hammingWindow[j-leftEdg];
        }
        for (ll j=dftWindowSample;j<interpolationSample;j++) frame[j]=0;
        //execute fourier transform
        
        float *input=new float[interpolationSample];
        float *output=new float[interpolationSample];
        for (ll i=0;i<interpolationSample;i++) input[i]=frame[i];
        COMPLEX_SPLIT complexInp;
        complexInp.realp=new float[interpolationSample/2];
        complexInp.imagp=new float[interpolationSample/2];
        
        vDSP_ctoz((COMPLEX*)input,2,&complexInp,1,interpolationSample/2);
        vDSP_fft_zrip(fftSetup,&complexInp,1,log2n,FFT_FORWARD);
        
        coefs[0]=complexInp.realp[0]*complexInp.realp[0];
        for (ll j=1;j<coefsNum;j++) {
            coefs[j]=complexInp.realp[j]*complexInp.realp[j]+complexInp.imagp[j]*complexInp.imagp[j];
            coefs[j]/=4;
        }
        
        for (ll j=0;j<coefsNum;j++) {
            coefs[j]=10*log10(coefs[j]/scale);
        }
        spectr.push_back(coefs);
        
        delete[] input;
        delete[] output;
        delete[] complexInp.realp;
        delete[] complexInp.imagp;
    }
    
    float **src=new float*[spectr.size()];
    for (ll i=0;i<spectr.size();i++) src[i]=spectr[i];
    
    float **dst=new float*[resizeX];
    
    for (ll i=0;i<resizeX;i++) {
        dst[i]=new float[resizeY];
    }
    for (ll i=0;i<resizeX;i++) {
        for (ll j=0;j<resizeY;j++) {
            dst[i][j]=src[(int)((double)i/resizeX*spectr.size())][int((double)j/resizeY*coefsNum)];
        }
    }
    
    for (ll i=0;i<spectr.size();i++) delete[] spectr[i];
    delete[] src;
    
    UInt8* rturn=new UInt8[resizeX*resizeY*3];
    double minRng=lamp,maxRng=ramp;
    for (ll i=0;i<resizeX;i++) {
        for (ll j=0;j<resizeY;j++) {
            double thePix=(dst[i][j]-minRng)/(maxRng-minRng);
            ll fin=thePix*256;
            fin=max(fin,0ll);
            fin=min(fin,255ll);
            rturn[(i*resizeY+j)*3]=jetMap[fin][0];
            rturn[(i*resizeY+j)*3+1]=jetMap[fin][1];
            rturn[(i*resizeY+j)*3+2]=jetMap[fin][2];
        }
    }
    for (ll i=0;i<resizeX;i++) delete[] dst[i];
    delete[] dst;
    return rturn;
}
