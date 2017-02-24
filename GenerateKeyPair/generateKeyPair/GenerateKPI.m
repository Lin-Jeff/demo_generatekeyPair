//
//  GenerateKPI.m
//  FIDOSDK
//
//  Created by hongyu on 04/01/2017.
//  Copyright © 2017 hongyu. All rights reserved.
//

#import "GenerateKPI.h"
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/md5.h>

#import "TouchIDObj.h"

typedef enum {
    RSA_PADDING_TYPE_NONE       = RSA_NO_PADDING,
    RSA_PADDING_TYPE_PKCS1      = RSA_PKCS1_PADDING,
    RSA_PADDING_TYPE_SSLV23     = RSA_SSLV23_PADDING
}RSA_PADDING_TYPE;

#define  PADDING   RSA_NO_PADDING

#define RSA_KEY_LENGTH 2048
static const char rnd_seed[] = "string to make the random number generator initialized";




@interface GenerateKPI() {
    RSA* _rsa_pub;
    RSA* _rsa_pri;
}
@property (nonatomic , strong) TouchIDObj *shareObj;

@end

@implementation GenerateKPI


- (id) initWithUser:(NSString *)userid facetId: (NSString *)facetid AppID: (NSString *)appid Type:(NSInteger)type KeyID: (NSString *)keyid AndKeySize:(int)keysize{
    self = [super init];
    if (self) {
        
        if (userid == nil) {
            _userid = @"";
        } else {
            _userid = userid;
        }
        _facetID = facetid;
        _appID = appid;
        
        _shareObj = [TouchIDObj shareObject];
        NSString *ID = @"";
        if (keyid.length <= 0 || !keyid) {
            NSString *tempKeyId = [_shareObj selKeyIDByFacetid_Appid:[NSString stringWithFormat:@"%@|_|%@",facetid,appid]];
            _keyID = tempKeyId;
            ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",facetid,appid,tempKeyId];
        }else {
            _keyID = keyid;
            ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",facetid,appid,keyid];
            [_shareObj addKeyIDByKey:[NSString stringWithFormat:@"%@|_|%@",facetid,appid] KeyID:keyid];
            [_shareObj addIncrementCounterByKey:[NSString stringWithFormat:@"%@|_|%@",facetid,appid] IncrementCounter:2];//IncrementCounter
        }
        
        _queryPrivateKey = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, userid,ID];
        
        _queryPublicKey = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PUBLIC_KEY, userid,ID];
       
    }
    return self;
}


-(NSString *)getKeyID {
    NSString * str = [_shareObj getKeyIDByFacetid_Appid:[NSString stringWithFormat:@"%@|_|%@",_facetID,_appID]];
    return str;
}
-(int)getIncrementCounter {
   int c =  [_shareObj getIncrementCounterByFacetid_Appid:[NSString stringWithFormat:@"%@|_|%@",_facetID,_appID]];
    return c;
}


/************************************************************************
 * RSA密钥生成函数
 *
 * file: test_rsa_genkey.c
 * gcc -Wall -O2 -o test_rsa_genkey test_rsa_genkey.c -lcrypto
 *
 * author: tonglulin@gmail.com by www.qmailer.net
 ************************************************************************/
-(void)generatePair
{
    /* 产生RSA密钥 */
    RSA *rsa = RSA_generate_key(2048, 65537, NULL, NULL);
    
    printf("BIGNUM: %s\n", BN_bn2hex(rsa->n));
    
    /* 提取私钥 */
    printf("PRIKEY:\n");
    PEM_write_RSAPrivateKey(stdout, rsa, NULL, NULL, 0, NULL, NULL);
    
    /* 提取公钥 */
    unsigned char *n_b = (unsigned char *)calloc(RSA_size(rsa), sizeof(unsigned char));
    unsigned char *e_b = (unsigned char *)calloc(RSA_size(rsa), sizeof(unsigned char));
    
    int n_size = BN_bn2bin(rsa->n, n_b);
    int b_size = BN_bn2bin(rsa->e, e_b);
    
    RSA *pubrsa = RSA_new();
    pubrsa->n = BN_bin2bn(n_b, n_size, NULL);
    pubrsa->e = BN_bin2bn(e_b, b_size, NULL);
    
    printf("PUBKEY: \n");
    PEM_write_RSAPublicKey(stdout, pubrsa);
    
    /* 生成pem格式的公钥和私钥  */
    int ret;
    BIO *out1,*in1;
    const EVP_CIPHER *enc=NULL;
    enc=EVP_des_ede3_ofb();
    out1=BIO_new_file("pri.pem","w");
    // ret=PEM_write_bio_RSAPrivateKey(out,r,enc,NULL,0,mycb,"123456");
    // ret=PEM_write_bio_RSAPrivateKey(out,r,enc,NULL,0,NULL,"123456");
    ret=PEM_write_bio_RSAPrivateKey(out1,rsa,enc,NULL,0,NULL,NULL);
    if(ret!=1) {
        RSA_free(rsa);
        RSA_free(pubrsa);
        BIO_free(out1);
        return ;
    }
    BIO_flush(out1);
    BIO_free(out1);
    out1=BIO_new_file("pub.pem","w");
    ret=PEM_write_bio_RSAPublicKey(out1,pubrsa);
    if(ret!=1)
    {
        RSA_free(rsa);
        RSA_free(pubrsa);
        BIO_free(out1);
        return ;
    }
    BIO_flush(out1);
    BIO_free(out1);
    RSA_free(rsa);
    RSA_free(pubrsa);
    
}

-(NSInteger)generateKeyFiles:(const char *)pubKeyFile : (const char *)priFeyFile :
(const unsigned char *)passwd : (int) passwd_len {
    RSA *rsa = NULL;
//    RAND_seed(rnd_seed, sizeof(rnd_seed));
    rsa = RSA_generate_key(RSA_KEY_LENGTH, RSA_F4, NULL, NULL);//这里执行较长
    if(rsa == NULL)
    {
        printf("RSA_generate_key error!\n");
        return -1;
    }/*
    BIO *out1;const EVP_CIPHER *enc=NULL;
    int ret;
    enc=EVP_des_ede3_ofb();
    out1=BIO_new_file(priFeyFile,"w");
    // ret=PEM_write_bio_RSAPrivateKey(out,r,enc,NULL,0,mycb,"123456");
    // ret=PEM_write_bio_RSAPrivateKey(out,r,enc,NULL,0,NULL,"123456");
    ret=PEM_write_bio_RSAPrivateKey(out1,rsa,enc,NULL,0,NULL,"i-Sprint_FIDO");
    if(ret!=1)
    {
        RSA_free(rsa);
        BIO_free(out1);
        return -1;
    }
    BIO_flush(out1);
    BIO_free(out1);
    out1=BIO_new_file(pubKeyFile,"w");
    ret=PEM_write_bio_RSAPublicKey(out1,rsa);
    if(ret!=1)
    {
        RSA_free(rsa);
        BIO_free(out1);
        return -1;
    }
    BIO_flush(out1);
    BIO_free(out1);
    */
    
    // 开始生成公钥文件
    BIO *bp = BIO_new(BIO_s_file());
    if(NULL == bp)
    {
        printf("generate_key bio file new error!\n");
        return -1;
    }
    
    if(BIO_write_filename(bp, (void *)pubKeyFile) <= 0)
    {
        printf("BIO_write_filename error!\n");
        return -1;
    }
    
    if(PEM_write_bio_RSAPublicKey(bp, rsa) != 1)
    {
        printf("PEM_write_bio_RSAPublicKey error!\n");
        return -1;
    }
    
    // 公钥文件生成成功，释放资源
    printf("Create public key ok!\n");
    BIO_free_all(bp);
    
    // 生成私钥文件
    bp = BIO_new_file(priFeyFile, "w+");
    if(NULL == bp)
    {
        printf("generate_key bio file new error2!\n");
        return -1;
    }
    
    if(PEM_write_bio_RSAPrivateKey(bp, rsa,
                                   NULL, (unsigned char *)RSA_PRIKEY_PSW,
                                   strlen(RSA_PRIKEY_PSW), NULL, NULL) != 1)
    {
        printf("PEM_write_bio_RSAPublicKey error!\n");
        return -1;
    }
    
    // 释放资源
    printf("Create private key ok!\n");
    BIO_free_all(bp);
    RSA_free(rsa);  
    
    return 0;  
}

// 打开公钥文件，返回EVP_PKEY结构的指针
EVP_PKEY* open_public_key(const char *keyfile)
{
    EVP_PKEY* key = NULL;
    RSA *rsa = NULL;
    
    OpenSSL_add_all_algorithms();
    BIO *bp = BIO_new(BIO_s_file());;
    BIO_read_filename(bp, keyfile);
    if(NULL == bp)
    {
        printf("open_public_key bio file new error!\n");
        return NULL;
    }
    
    rsa = PEM_read_bio_RSAPublicKey(bp, NULL, NULL, NULL);
    if(rsa == NULL)
    {
        printf("open_public_key failed to PEM_read_bio_RSAPublicKey!\n");
        BIO_free(bp);
        RSA_free(rsa);
        
        return NULL;
    }
    
    printf("open_public_key success to PEM_read_bio_RSAPublicKey!\n");
    key = EVP_PKEY_new();
    if(NULL == key)
    {
        printf("open_public_key EVP_PKEY_new failed\n");
        RSA_free(rsa);
        
        return NULL;
    }
    
    EVP_PKEY_assign_RSA(key, rsa);
    return key;
}

// 打开私钥文件，返回EVP_PKEY结构的指针
EVP_PKEY* open_private_key(const char *keyfile, const unsigned char *passwd)
{
    EVP_PKEY* key = NULL;
    RSA *rsa = RSA_new();
    OpenSSL_add_all_algorithms();
    BIO *bp = NULL;
    bp = BIO_new_file(keyfile, "rb");
    if(NULL == bp)
    {
        printf("open_private_key bio file new error!\n");
        
        return NULL;
    }
    
    rsa = PEM_read_bio_RSAPrivateKey(bp, &rsa, NULL, (void *)passwd);
    if(rsa == NULL)
    {
        printf("open_private_key failed to PEM_read_bio_RSAPrivateKey!\n");
        BIO_free(bp);
        RSA_free(rsa);
        
        return NULL;
    }
    
    printf("open_private_key success to PEM_read_bio_RSAPrivateKey!\n");
    key = EVP_PKEY_new();
    if(NULL == key)
    {
        printf("open_private_key EVP_PKEY_new failed\n");
        RSA_free(rsa);
        
        return NULL;
    }
    
    EVP_PKEY_assign_RSA(key, rsa);
    return key;
}

-(NSString *)readTheKeyPir:(NSString *)KeyFile
{   //pem 文件的内容整个信息
    NSString *certStr = [NSString stringWithContentsOfFile:KeyFile encoding:NSUTF8StringEncoding error:nil];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----BEGIN RSA PUBLIC KEY-----" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END RSA PUBLIC KEY-----" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
//    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END RSA PRIVATE KEY-----" withString:@""];
    return certStr;
}

-(NSData *)getPubkIntoData {
    NSString *certStr = [_publicKeyStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    certStr = [certStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----BEGIN RSA PUBLIC KEY-----" withString:@""];
    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END RSA PUBLIC KEY-----" withString:@""];
    return [[NSData alloc] initWithBase64EncodedString:certStr options:0];//说明public key的内容是DER encode 后再base64
    //    return [_publicKeyStr dataUsingEncoding:NSUTF8StringEncoding];
}

/************************************************************************
 * 由public／private key string 生成RSA public／private key
 *
 *
 *
 *
 *
 ************************************************************************/

#pragma mark - public methord
-(BOOL)importKeyWithType:(KeyType)type andPath:(NSString *)path
{
    __block BOOL status = NO;
    const char* cPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    BIO *bio = NULL;
    RSA *rsa = NULL;
    NSString *ID = @"";
    ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",_facetID,_appID,_keyID];
    bio = BIO_new_file(cPath,"rb");
//    rsa=RSA_new();
    // read=PEM_read_bio_RSAPublicKey(in,&read,NULL,NULL);
    // read=PEM_read_bio_RSAPrivateKey(in,&read,mycb,"123456");
    // read=PEM_read_bio_RSAPrivateKey(in,&read,NULL,"123456");
    if (type == KeyTypePrivate) {
        rsa=PEM_read_bio_RSAPrivateKey(bio,&rsa,NULL,"i-Sprint_FIDO");
        if(rsa->d!=NULL) {
            _rsa_pri = rsa;
            _privateKeyStr = [self readTheKeyPir:path];
            status = YES;
           //save the private key string in keychain
//            NSString *privateKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, _userid,ID];
            [_shareObj addKeyPairString:_privateKeyStr service:_queryPrivateKey callBack:^(id  _Nullable result, NSError * _Nullable error) {
                if (error) {
                    status = NO;
                } else {
                    status = YES;
                }
            }];

        } else {
            [Helper printErrorDebug:@"generate private RSA key fail"];
        }
    }
    else {
        rsa=PEM_read_bio_RSAPublicKey(bio,&rsa,NULL,NULL);
        if(rsa != NULL) {
            _rsa_pub = rsa;
            _publicKeyStr = [self readTheKeyPir:path];
            [Helper printErrorDebug:[NSString stringWithFormat:@"public RSA key String:%@" ,_publicKeyStr]];
            status = YES;
            //save the public key string in keychain
//            NSString *publicKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PUBLIC_KEY, _userid,ID];
            [_shareObj addKeyPairString:_publicKeyStr service:_queryPublicKey callBack:^(id  _Nullable result, NSError * _Nullable error) {
                
            }];
        } else {
            [Helper printErrorDebug:@"generate public RSA key fail"];
        }
    }
    BIO_free(bio);
    
    
   /*
    BIO_read_filename(bio, cPath);
    if (type == KeyTypePrivate) {
        rsa = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, (unsigned char *)RSA_PRIKEY_PSW);
        if (_rsa_pri) {
            RSA_free(_rsa_pri);
        }
        _rsa_pri = rsa;
        if (rsa != NULL && 1 == RSA_check_key(rsa)) {
            status = YES;
            // get private str
            _privateKeyStr = [self readTheKeyPir:path];
        } else {
            status = NO;
            [Helper printErrorDebug:@"generate private RSA key success"];
        }
    }
    else {
        rsa = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
        if (_rsa_pub) {
            RSA_free(_rsa_pub);
        }
        _rsa_pub = rsa;
        if (rsa != NULL) {
            status = YES;
            // get public str
            _publicKeyStr = [self readTheKeyPir:path];
            [Helper printDebug:[NSString stringWithFormat:@"public key pir:%@",_publicKeyStr]];
        } else {
            status = NO;
            [Helper printErrorDebug:@"generate public RSA key fail"];
        }
    }
    
    BIO_free_all(bio);*/
    
    /* 无论成不成功，都必须删除文件*/
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL b = [manager removeItemAtPath:path error:nil];
    
    NSString *str = b ? @"remove the pem success" : @"remove the pem fail";
    [Helper printDebug:str];
    
    return status;
    
}


+ (void) deletePrivateKeyWithUser:(NSString *)userid facetId: (NSString *)facetid AppID: (NSString *)appid keyID: (NSString *)keyid ByTouchIDCallback:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack {
    NSString *ID = @"";
    ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",facetid,appid,keyid];
    NSString *privateKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, userid,ID];
    
    
    
    [TouchIDObj deletePairKeyWithServiceStr:privateKeyIdentifier ByTouchIDCallback:^(id  _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"delete KeyPair fail"];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
            callBack(nil , error1);
        } else {
            callBack(nil,nil);
            [Helper printDebug:[NSString stringWithFormat:@"delete KeyPair success %@",ID]];
        }
    }];
}

- (void)updateKeyPairAccessControlPrivateKeyCallBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack {
    if(_shareObj && _queryPrivateKey) {//假如用户在注册一半过程中把fidoclient退出，那默认这次注册作废
        NSString *ID = @"";
//        ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",_facetID,_appID,_keyID];
//        NSString *privateKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, _userid,ID];
        [_shareObj updateKeyPairAccessControlPrivateKeyWithServiceStr:_queryPrivateKey CallBack:^(id  _Nullable result, NSError * _Nullable error) {
            if (error) {
                [Helper printDebug:@"update KeyPair fail"];
                NSString *message = [NSString stringWithFormat:@"update KeyPair fail"];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
                callBack(nil , error1);
            } else {
                callBack(nil , nil);
            }
        }];
    } else {
        [Helper printDebug:@"update KeyPair fail"];
        NSString *message = [NSString stringWithFormat:@"update KeyPair fail"];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
        NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
        callBack(nil , error1);
    }
}

- (void) getPrivateKeyWithTouchIDCallback:(void(^ _Nonnull)(NSString *keyStr , NSError * _Nullable error))callBack {
    if(_shareObj && _queryPrivateKey) {
        
        if (_rsa_pri) {//1.如果fidoclient没有退出，rsapri私钥一直保存在内存
            callBack(nil,nil);
            
        } else {//2.fidoclient退出,author重新打开fidoclient
            //        NSString *ID = @"";
            //        ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",_facetID,_appID,_keyID];
            //        NSString *privateKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, _userid,ID];
            [_shareObj queryItemService:_queryPrivateKey callBack:^(id  _Nullable result, NSError * _Nullable error) {
                if (error) {
                    NSString *message = [NSString stringWithFormat:@"query KeyPair fail"];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                    NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
                    callBack(nil , error1);
                } else {
                    
                    BOOL b = [self importKeyWithType:KeyTypePrivate andkeyString:result];
                    if(b && _rsa_pri) {
                        callBack(nil , nil);
                    } else {
                        NSString *message = [NSString stringWithFormat:@"query KeyPair fail"];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                        NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
                        callBack(nil , error1);
                    }
                }
            }];
        }
    } else {
        
        NSString *message = [NSString stringWithFormat:@"query KeyPair fail"];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
        NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
        callBack(nil , error1);
    }

}



- (BOOL)importKeyWithType:(KeyType)type andkeyString:(NSString *)keyString
{
    if (!keyString) {
        return NO;
    }
    BOOL status = NO;
    BIO *bio = NULL;
    RSA *rsa = NULL;
//    bio = BIO_new(BIO_s_file());
    if ((bio = BIO_new_mem_buf([keyString UTF8String], (int)keyString.length)) == NULL)       //从字符串读取RSA公钥
    {
        [Helper printDebug:@"BIO_new_mem_buf failed!"];
    }
//    NSString* temPath = NSTemporaryDirectory();
//    NSString* rsaFilePath = [temPath stringByAppendingPathComponent:@"RSAKEY"];
//    NSString* formatRSAKeyString = [self formatRSAKeyWithKeyString:keyString andKeytype:type];
//    BOOL writeSuccess = [keyString writeToFile:rsaFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    if (!writeSuccess) {
//        return NO;
//    }
//    const char* cPath = [rsaFilePath cStringUsingEncoding:NSUTF8StringEncoding];
//    BIO_read_filename(bio, cPath);
    if (type == KeyTypePrivate) {
        
//        rsa = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);   //从bio结构中得到rsa结构
        rsa=PEM_read_bio_RSAPrivateKey(bio,&rsa,NULL,"i-Sprint_FIDO");
        _rsa_pri = rsa;
        _privateKeyStr = keyString;
        if (rsa != NULL && 1 == RSA_check_key(rsa)) {
            status = YES;
        } else {
            status = NO;
        }
    }
    else{
        rsa = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
        _rsa_pub = rsa;
        if (rsa != NULL) {
            status = YES;
        } else {
            status = NO;
        }
    }
    
    BIO_free_all(bio);
//    [[NSFileManager defaultManager] removeItemAtPath:rsaFilePath error:nil];
    return status;
}


#pragma mark RSA sha1验证签名
//signString为base64字符串
- (BOOL)verifyString:(NSString *)string withSign:(NSString *)signString
{
    if (!_rsa_pub) {
        NSLog(@"please import public key first");
        return NO;
    }
    
    const char *message = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int messageLength = (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = [[NSData alloc]initWithBase64EncodedString:signString options:0];
    unsigned char *sig = (unsigned char *)[signatureData bytes];
    unsigned int sig_len = (int)[signatureData length];
    
    
    
    
    unsigned char sha1[20];
    SHA1((unsigned char *)message, messageLength, sha1);
    int verify_ok = RSA_verify(NID_sha1
                               , sha1, 20
                               , sig, sig_len
                               , _rsa_pub);
    
    if (1 == verify_ok){
        return   YES;
    }
    return NO;
    
    
}
#pragma mark RSA MD5 验证签名
- (BOOL)verifyMD5String:(NSString *)string withSign:(NSString *)signString
{
    if (!_rsa_pub) {
        NSLog(@"please import public key first");
        return NO;
    }
    
    const char *message = [string cStringUsingEncoding:NSUTF8StringEncoding];
    // int messageLength = (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSData *signatureData = [[NSData alloc]initWithBase64EncodedString:signString options:0];
    unsigned char *sig = (unsigned char *)[signatureData bytes];
    unsigned int sig_len = (int)[signatureData length];
    
    unsigned char digest[MD5_DIGEST_LENGTH];
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, message, strlen(message));
    MD5_Final(digest, &ctx);
    int verify_ok = RSA_verify(NID_md5
                               , digest, MD5_DIGEST_LENGTH
                               , sig, sig_len
                               , _rsa_pub);
    if (1 == verify_ok){
        return   YES;
    }
    return NO;
    
}

- (NSString *)signString:(NSString *)string
{
    if (!_rsa_pri) {
        NSLog(@"please import private key first");
        return nil;
    }
    const char *message = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int messageLength = (int)strlen(message);
    unsigned char *sig = (unsigned char *)malloc(256);
    unsigned int sig_len;
    
    unsigned char sha1[20];
    SHA1((unsigned char *)message, messageLength, sha1);
    
    
    int rsa_sign_valid = RSA_sign(NID_sha1
                                  , sha1, 20
                                  , sig, &sig_len
                                  , _rsa_pri);
    if (rsa_sign_valid == 1) {
        NSData* data = [NSData dataWithBytes:sig length:sig_len];
        
        NSString * base64String = [data base64EncodedStringWithOptions:0];
        free(sig);
        return base64String;
    }
    
    free(sig);
    return nil;
}
- (NSString *)signMD5String:(NSString *)string
{
    if (!_rsa_pri) {
        NSLog(@"please import private key first");
        return nil;
    }
    const char *message = [string cStringUsingEncoding:NSUTF8StringEncoding];
    //int messageLength = (int)strlen(message);
    unsigned char *sig = (unsigned char *)malloc(256);
    unsigned int sig_len;
    
    unsigned char digest[MD5_DIGEST_LENGTH];
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, message, strlen(message));
    MD5_Final(digest, &ctx);
    
    int rsa_sign_valid = RSA_sign(NID_md5
                                  , digest, MD5_DIGEST_LENGTH
                                  , sig, &sig_len
                                  , _rsa_pri);
    
    if (rsa_sign_valid == 1) {
        NSData* data = [NSData dataWithBytes:sig length:sig_len];
        
        NSString * base64String = [data base64EncodedStringWithOptions:0];
        free(sig);
        return base64String;
    }
    
    free(sig);
    return nil;
    
    
}

-(NSData *)RSASignWithType:(AlgAndEncodingEnum)AlgType withData:(NSData *)content {
    NSData *returnData = nil;
    if (!_rsa_pri) {
        [Helper printDebug:@"please import private key first"];
        return returnData;
    }


    if (AlgType == UAF_ALG_SIGN_RSASSA_PSS_SHA256_RAW) {
        //em
        int messageLength = (int)[content length];
        unsigned char *EM = (unsigned char *)malloc(256);
        bzero(EM, 256);
        //        unsigned int sig_len;
        const EVP_MD *md = EVP_sha256();
        unsigned char sha256[32];
        SHA256([content bytes], messageLength, sha256);
        
        int status;
        //    int length  = (int)65;//[content length];
        
        int flen = [self getBlockSizeWithRSA_PADDING_TYPE:PADDING andRSA:_rsa_pri];
        
        unsigned char encData[500];// = (char*)malloc(flen);
        bzero(encData, 500);
        
        int ret = RSA_padding_add_PKCS1_PSS(_rsa_pri, EM, sha256, md, 32);
   
        if (!ret) {
            
            [Helper printDebug:@"RSA_padding_add_PKCS1_PSS fail"];
            return returnData;
        }

        status = RSA_private_encrypt(flen, EM, encData, _rsa_pri, PADDING);
        
        if (status > 0){
            returnData = [[NSData alloc]initWithBytes:encData length:status];
        }
        free(EM);
    }else if (AlgType == UAF_ALG_SIGN_SECP256R1_ECDSA_SHA256_RAW) {
        
    }
    
    return returnData;
}


/*          
 */
- (NSString *) encryptWithPublicKey:(NSString*)content
{
    if (!_rsa_pub) {
        NSLog(@"please import public key first");
        return nil;
    }
    int status;
    int length  = (int)[content length];
    unsigned char input[length + 1];
    bzero(input, length + 1);
    int i = 0;
    for (; i < length; i++)
    {
        input[i] = [content characterAtIndex:i];
    }
    
    NSInteger  flen = [self getBlockSizeWithRSA_PADDING_TYPE:PADDING andRSA:_rsa_pub];
    
    char *encData = (char*)malloc(flen);
    bzero(encData, flen);
    status = RSA_public_encrypt(length, (unsigned char*)input, (unsigned char*)encData, _rsa_pub, PADDING);
    
    if (status){
        NSData *returnData = [NSData dataWithBytes:encData length:status];
        free(encData);
        encData = NULL;
        
        //NSString *ret = [returnData base64EncodedString];
        NSString *ret = [returnData base64EncodedStringWithOptions: NSDataBase64Encoding64CharacterLineLength];
        return ret;
    }
    
    free(encData);
    encData = NULL;
    
    return nil;
}

- (NSString *) decryptWithPrivatecKey:(NSString*)content
{
    if (!_rsa_pri) {
        NSLog(@"please import private key first");
        return nil;
    }    int status;
    
    //NSData *data = [content base64DecodedData];
    NSData *data = [[NSData alloc]initWithBase64EncodedString:content options:NSDataBase64DecodingIgnoreUnknownCharacters];
    int length = (int)[data length];
    
    NSInteger flen = [self getBlockSizeWithRSA_PADDING_TYPE:PADDING andRSA:_rsa_pri];
    char *decData = (char*)malloc(flen);
    bzero(decData, flen);
    
    status = RSA_private_decrypt(length, (unsigned char*)[data bytes], (unsigned char*)decData, _rsa_pri, PADDING);
    
    if (status)
    {
        NSMutableString *decryptString = [[NSMutableString alloc] initWithBytes:decData length:strlen(decData) encoding:NSASCIIStringEncoding];
        free(decData);
        decData = NULL;
        
        return decryptString;
    }
    
    free(decData);
    decData = NULL;
    
    return nil;
}

- (int)getBlockSizeWithRSA_PADDING_TYPE:(RSA_PADDING_TYPE)padding_type andRSA:(RSA*)rsa
{
    int len = RSA_size(rsa);
    
    if (padding_type == RSA_PADDING_TYPE_PKCS1 || padding_type == RSA_PADDING_TYPE_SSLV23) {
        len -= 11;
    }
    
    return len;
}

-(NSString*)formatRSAKeyWithKeyString:(NSString*)keyString andKeytype:(KeyType)type
{
    NSInteger lineNum = -1;
    NSMutableString *result = [NSMutableString string];
    
    if (type == KeyTypePrivate) {
        [result appendString:@"-----BEGIN PRIVATE KEY-----\n"];
        lineNum = 79;
    }else if(type == KeyTypePublic){
        [result appendString:@"-----BEGIN PUBLIC KEY-----\n"];
        lineNum = 76;
    }
    
    int count = 0;
    for (int i = 0; i < [keyString length]; ++i) {
        unichar c = [keyString characterAtIndex:i];
        if (c == '\n' || c == '\r') {
            continue;
        }
        [result appendFormat:@"%c", c];
        if (++count == lineNum) {
            [result appendString:@"\n"];
            count = 0;
        }
    }
    if (type == KeyTypePrivate) {
        [result appendString:@"\n-----END PRIVATE KEY-----"];
        
    }else if(type == KeyTypePublic){
        [result appendString:@"\n-----END PUBLIC KEY-----"];
    }
    return result;
    
}


//static const unsigned char zeroes[] = {0,0,0,0,0,0,0,0};
//int RSA_padding_add_PKCS1_PSS1(RSA *rsa, unsigned char *EM,
//                              const unsigned char *mHash,
//                              const EVP_MD *Hash, int sLen)
//{
//    return RSA_padding_add_PKCS1_PSS_mgf1(rsa, EM, mHash, Hash, NULL, sLen);
//}
//
//int RSA_padding_add_PKCS1_PSS_mgf11(RSA *rsa, unsigned char *EM,
//                                    const unsigned char *mHash,
//                                    const EVP_MD *Hash, const EVP_MD *mgf1Hash, int sLen)
//{
//    int i;
//    int ret = 0;
//    int hLen, maskedDBLen, MSBits, emLen;
//    unsigned char *H, *salt = NULL, *p;
//    EVP_MD_CTX ctx;
//    
//    if (mgf1Hash == NULL)
//        mgf1Hash = Hash;
//    
//    hLen = EVP_MD_size(Hash);
//    if (hLen < 0)
//        goto err;
//    /*
//     0211      * Negative sLen has special meanings:
//     0212      *  -1  sLen == hLen
//     0213      *  -2  salt length is maximized
//     0214      *  -N  reserved
//     0215      */
//    if      (sLen == -1)    sLen = hLen;
//    else if (sLen == -2)    sLen = -2;
//    else if (sLen < -2)
//    {
//        RSAerr(RSA_F_RSA_PADDING_ADD_PKCS1_PSS_MGF1, RSA_R_SLEN_CHECK_FAILED);
//        goto err;
//    }
//    
//    MSBits = (BN_num_bits(rsa->n) - 1) & 0x7;
//    emLen = RSA_size(rsa);
//    if (MSBits == 0)
//    {
//        *EM++ = 0;
//        emLen--;
//    }
//    if (sLen == -2)
//    {
//        sLen = emLen - hLen - 2;
//    }
//    else if (emLen < (hLen + sLen + 2))
//    {
//        RSAerr(RSA_F_RSA_PADDING_ADD_PKCS1_PSS_MGF1,RSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE);
//        goto err;
//    }
//    if (sLen > 0)
//    {
//        salt = OPENSSL_malloc(sLen);
//        if (!salt)
//        {
//            RSAerr(RSA_F_RSA_PADDING_ADD_PKCS1_PSS_MGF1,ERR_R_MALLOC_FAILURE);
//            goto err;
//        }
//        if (RAND_bytes(salt, sLen) <= 0)
//            goto err;
//    }
//    maskedDBLen = emLen - hLen - 1;
//    H = EM + maskedDBLen;
//    EVP_MD_CTX_init(&ctx);
//    if (!EVP_DigestInit_ex(&ctx, Hash, NULL)
//        || !EVP_DigestUpdate(&ctx, zeroes, sizeof zeroes)
//        || !EVP_DigestUpdate(&ctx, mHash, hLen))
//        goto err;
//    if (sLen && !EVP_DigestUpdate(&ctx, salt, sLen))
//        goto err;
//    if (!EVP_DigestFinal_ex(&ctx, H, NULL))
//        goto err;
//    EVP_MD_CTX_cleanup(&ctx);
//    
//    /* Generate dbMask in place then perform XOR on it */
//    if (PKCS1_MGF1(EM, maskedDBLen, H, hLen, mgf1Hash))
//        goto err;
//    
//    p = EM;
//    
//    /* Initial PS XORs with all zeroes which is a NOP so just update
//     * pointer. Note from a test above this value is guaranteed to
//     * be non-negative.
//     */
//    p += emLen - sLen - hLen - 2;
//    *p++ ^= 0x1;
//    if (sLen > 0)
//    {
//        for (i = 0; i < sLen; i++)
//            *p++ ^= salt[i];
//    }
//    if (MSBits)
//        EM[0] &= 0xFF >> (8 - MSBits);
//    
//    /* H is already in place so just set final 0xbc */
//    
//    EM[emLen - 1] = 0xbc;
//    
//    ret = 1;
//    
//err:
//    if (salt)
//        OPENSSL_free(salt);
//    
//    return ret;
//    
//}


@end

