//
//  GenerateECCkeyPair.h
//  GenerateKeyPair
//
//  Created by hongyu on 23/02/2017.
//  Copyright © 2017 hongyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/ec.h> 
#include <openssl/ecdsa.h> 
#include <openssl/objects.h> 
#include <openssl/err.h>
#import "Helper.h"
#import "TagsEnumModel.h"

@interface GenerateECCkeyPair : NSObject

@property(nonatomic, strong) NSString *userid;
@property(nonatomic, strong) NSString *facetID;
@property(nonatomic, strong) NSString *appID;
@property(nonatomic, strong) NSString *keyID;
@property(nonatomic, strong) NSString * queryPublicKey;
@property(nonatomic, strong) NSString * queryPrivateKey;
@property (nonatomic , strong) NSString *privateKeyStr;
@property (nonatomic , strong) NSString *publicKeyStr;

- (id) initWithUser:(NSString *)userid facetId: (NSString *)facetid AppID: (NSString *)appid Type:(NSInteger)type KeyID: (NSString *)keyid AndKeySize:(int)keysize;
-(int)generateKeyFiles:(const char *)pubKeyFile : (const char *)priFeyFile :
(const unsigned char *)passwd : (int) passwd_len;
-(BOOL)importKeyWithType:(KeyType)type andPath:(NSString *)path;
-(NSData *)getPubkIntoData;

//test
-(NSData *)ECDSA_SHA256SignWithType:(AlgAndEncodingEnum)AlgType withData:(NSData *)content;
@end
