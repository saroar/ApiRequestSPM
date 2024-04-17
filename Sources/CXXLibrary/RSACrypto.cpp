#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include "RSACrypto.hpp"

extern "C" {
    // Function to encrypt data using RSA PKCS1v1.5
    unsigned char* rsaEncrypt(const unsigned char* data, size_t dataLen, const char* publicKey, int* outLen) {
        BIO *bio = BIO_new_mem_buf((void*)publicKey, -1);
        RSA *rsa = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);

        if (!rsa) {
            ERR_print_errors_fp(stderr);
            return nullptr;
        }

        unsigned char* encrypted = (unsigned char*)malloc(RSA_size(rsa));
        *outLen = RSA_public_encrypt(dataLen, data, encrypted, rsa, RSA_PKCS1_PADDING);

        if (*outLen == -1) {
            ERR_print_errors_fp(stderr);
            free(encrypted);
            encrypted = nullptr;
        }

        RSA_free(rsa);
        BIO_free_all(bio);

        return encrypted;
    }
}
