//
//  RSACrypto.hpp
//  
//
//  Created by Saroar Khandoker on 16.04.2024.
//

#ifndef RSACrypto_hpp
#define RSACrypto_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

unsigned char* rsaEncrypt(const unsigned char* data, size_t dataLen, const char* publicKey, int* outLen);

#ifdef __cplusplus
}
#endif

#endif /* RSACrypto_hpp */
