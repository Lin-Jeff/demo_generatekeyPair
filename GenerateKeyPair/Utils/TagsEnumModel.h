//
//  TagsEnumModel.h
//  FIDOSDK
//
//  Created by hongyu on 08/12/2016.
//  Copyright © 2016 hongyu. All rights reserved.
//
#define RSA_PRIKEY_PSW "i-Sprint_FIDO"
#define PRIVATE_KEY @"TouchIDPrivateKey"
#define PUBLIC_KEY @"TouchIDPublicKey"
#define PRIVATE_KEY_FILE "/private.pem"
#define PUBLIC_KEY_FILE  "/public.pem"
#define FILEPATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]


typedef enum {
    KeyTypePublic = 0,
    KeyTypePrivate
}KeyType;

#import <Foundation/Foundation.h>

@interface TagsEnumModel : NSObject

typedef enum {
    UAF_CMD_STATUS_ERR_UNKNOWN          = 0x01,
    TAG_UAFV1_REG_ASSERTION             = 0x3E01,
    TAG_UAFV1_AUTH_ASSERTION            = 0x3E02,
    TAG_UAFV1_KRD                       = 0x3E03,
    TAG_UAFV1_SIGNED_DATA               = 0x3E04,
    TAG_ATTESTATION_CERT                = 0x2E05,
    TAG_SIGNATURE                       = 0x2E06,
    TAG_ATTESTATION_BASIC_FULL          = 0x3E07,
    TAG_ATTESTATION_BASIC_SURROGATE     = 0x3E08,
    TAG_KEYID                           = 0x2E09,
    TAG_FINAL_CHALLENGE                 = 0x2E0A,
    TAG_AAID                            = 0x2E0B,
    TAG_PUB_KEY                         = 0x2E0C,
    TAG_COUNTERS                        = 0x2E0D,
    TAG_ASSERTION_INFO                  = 0x2E0E,
    TAG_AUTHENTICATOR_NONCE             = 0x2E0F,
    TAG_TRANSACTION_CONTENT_HASH        = 0x2E10,
    TAG_EXTENSION                       = 0x3E11,
    TAG_EXTENSION_NON_CRITICAL          = 0x3E12,
    TAG_EXTENSION_ID                    = 0x2E13,
    TAG_EXTENSION_DATA                  = 0x2E14
} TagsEnum;




typedef enum   {
    UAF_ALG_SIGN_SECP256R1_ECDSA_SHA256_RAW     = 0x01,//
    UAF_ALG_SIGN_SECP256R1_ECDSA_SHA256_DER     = 0x02,
    UAF_ALG_SIGN_RSASSA_PSS_SHA256_RAW          = 0x03,
    UAF_ALG_SIGN_RSASSA_PSS_SHA256_DER          = 0x04,
    UAF_ALG_SIGN_SECP256K1_ECDSA_SHA256_RAW     = 0x05,
    UAF_ALG_KEY_ECC_X962_RAW                    = 0x100,
    UAF_ALG_KEY_ECC_X962_DER                    = 0x101,
    UAF_ALG_KEY_RSA_2048_PSS_RAW                = 0x102,//
    UAF_ALG_KEY_RSA_2048_PSS_DER                = 0x103,
    UAF_ALG_SIGN_SECP256K1_ECDSA_SHA256_DER     = 0x06
} AlgAndEncodingEnum;
@end
