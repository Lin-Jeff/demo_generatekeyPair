//
//  GenerateECCkeyPair.m
//  GenerateKeyPair
//
//  Created by hongyu on 23/02/2017.
//  Copyright © 2017 hongyu. All rights reserved.
//

#import "GenerateECCkeyPair.h"
#import "TouchIDObj.h"

@interface GenerateECCkeyPair() {
    EC_KEY* _EC_pub;
    EC_KEY* _EC_pri;
}

@property (nonatomic , strong) TouchIDObj *shareObj;
@end


@implementation GenerateECCkeyPair


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


-(int)generateKeyFiles:(const char *)pubKeyFile : (const char *)priFeyFile :
(const unsigned char *)passwd : (int) passwd_len {
    EC_KEY *key1,*key2;
    EC_POINT *pubkey1,*pubkey2;
    EC_GROUP  *group1,*group2;
    int ret,nid,size,i,sig_len;
    unsigned char *signature,digest[32];
    BIO *berr;
    EC_builtin_curve *curves;
    int crv_len;
    char shareKey1[256],shareKey2[256];
    int  len1,len2;
    
    /* 构造 EC_KEY 数据结构 */
    key1=EC_KEY_new();
    if(key1==NULL)
    {
        printf("EC_KEY_new err!\n");
        return -1;
    }
    key2=EC_KEY_new();
    if(key2==NULL)
    {
        printf("EC_KEY_new err!\n");
        return -1;
    }
    /* 获取实现的椭圆曲线个数 */
//    crv_len = EC_get_builtin_curves(NULL, 0);
//    curves = (EC_builtin_curve *)malloc(sizeof(EC_builtin_curve) * crv_len);
    /* 获取椭圆曲线列表 */
//    EC_get_builtin_curves(curves, crv_len);
    /*
     nid=curves[0].nid;会有错误，原因是密钥太短
     */
    /* 选取一种椭圆曲线 */
    /* SECG secp256r1 is the same as X9.62 prime256v1 and hence omitted */
    nid=NID_X9_62_prime256v1;//curves[25].nid;
    /* 根据选择的椭圆曲线生成密钥参数 group */
    group1=EC_GROUP_new_by_curve_name(nid);
    if(group1==NULL)
    {
        printf("EC_GROUP_new_by_curve_name err!\n");
        return -1; }
    group2=EC_GROUP_new_by_curve_name(nid);
    if(group1==NULL)
    {printf("EC_GROUP_new_by_curve_name err!\n");
        return -1; }
    /* 设置密钥参数 */
    ret=EC_KEY_set_group(key1,group1);
    if(ret!=1)
    {
        printf("EC_KEY_set_group err.\n");
        return -1; }
    ret=EC_KEY_set_group(key2,group2);
    if(ret!=1)
    {
        printf("EC_KEY_set_group err.\n");
        return -1; }
    /* 生成密钥 */
    ret=EC_KEY_generate_key(key1);
    if(ret!=1)
    {
        printf("EC_KEY_generate_key err.\n");
        return -1; }
    ret=EC_KEY_generate_key(key2);
    if(ret!=1)
    {
        printf("EC_KEY_generate_key err.\n");
        return -1; }
    /* 检查密钥 */
    ret=EC_KEY_check_key(key1);
    if(ret!=1)
    {
        printf("check key err.\n");
        return -1; }
    /* 获取密钥大小 */
    size=ECDSA_size(key1);
    printf("size %d \n",size);
    for(i=0;i<32;i++){
        memset(&digest[i],i+1,1);
    }
    signature=malloc(size);
    ERR_load_crypto_strings();
    berr=BIO_new(BIO_s_file());
    BIO_set_fp(berr,stdout,BIO_NOCLOSE);
    /* 签名数据，本例未做摘要，可将 digest 中的数据看作是 sha1 摘要结果 */
    [Helper printDebug:[NSString stringWithFormat:@"orgin:%@",[[NSData alloc]initWithBytes:digest length:32]] ];
    ret=ECDSA_sign(0,digest,32,signature,&sig_len,key1);
    if(ret!=1)
    {
        ERR_print_errors(berr); printf("sign err!\n");
        return -1;
    }
    [Helper printDebug:[NSString stringWithFormat:@"sign :%@",[[NSData alloc]initWithBytes:signature length:sig_len]] ];
    /* 验证签名 */
    ret=ECDSA_verify(0,digest,32,signature,sig_len,key1);
    if(ret!=1)
    {
        ERR_print_errors(berr); printf("ECDSA_verify err!\n");
        return -1;
    }
    /* 获取对方公钥，不能直接引用 */
    pubkey2 = EC_KEY_get0_public_key(key2);
    /* 生成一方的共享密钥 */
    len1=ECDH_compute_key(shareKey1, 256, pubkey2, key1, NULL);
    pubkey1 = EC_KEY_get0_public_key(key1);
    /* 生成另一方共享密钥 */
    len2=ECDH_compute_key(shareKey2, 256, pubkey1, key2, NULL);
    if(len1!=len2)
    {
        printf("err\n");
    }
    else {
        ret=memcmp(shareKey1,shareKey2,len1);
        if(ret==0)
            printf("生成共享密钥成功\n");
        else
            printf("生成共享密钥失败\n");
    }
    printf("test ok!\n");
    
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
    
    if(PEM_write_bio_EC_PUBKEY(bp, key1) != 1)
    {
        printf("PEM_write_bio_EC_PUBKEY error!\n");
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
    
    if(PEM_write_bio_ECPrivateKey(bp, key1,
                                   NULL, (unsigned char *)RSA_PRIKEY_PSW,
                                   strlen(RSA_PRIKEY_PSW), NULL, NULL) != 1)
    {
        printf("PEM_write_bio_RSAPublicKey error!\n");
        return -1;
    }
    
    // 释放资源
    printf("Create private key ok!\n");
    BIO_free_all(bp);
    BIO_free(berr);
    EC_KEY_free(key1);
    EC_KEY_free(key2);
    free(signature);
//    free(curves);
    return 0;
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
    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
    certStr = [certStr stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
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
    EC_KEY *EC = NULL;
    NSString *ID = @"";
    ID = [NSString stringWithFormat:@"%@|_|%@|_|%@",_facetID,_appID,_keyID];
    bio = BIO_new_file(cPath,"rb");
    //    rsa=RSA_new();
    // read=PEM_read_bio_RSAPublicKey(in,&read,NULL,NULL);
    // read=PEM_read_bio_RSAPrivateKey(in,&read,mycb,"123456");
    // read=PEM_read_bio_RSAPrivateKey(in,&read,NULL,"123456");
    if (type == KeyTypePrivate) {
        EC=PEM_read_bio_ECPrivateKey(bio,&EC,NULL,"i-Sprint_FIDO");
        if(EC != NULL) {
            _EC_pri = EC;
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
            [Helper printErrorDebug:@"generate private EC key fail"];
        }
    }
    else {
        EC=PEM_read_bio_EC_PUBKEY(bio,&EC,NULL,NULL);
        if(EC != NULL) {
            _EC_pub = EC;
            _publicKeyStr = [self readTheKeyPir:path];
            [Helper printErrorDebug:[NSString stringWithFormat:@"public EC key String:%@" ,_publicKeyStr]];
            status = YES;
            //save the public key string in keychain
            //            NSString *publicKeyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PUBLIC_KEY, _userid,ID];
            [_shareObj addKeyPairString:_publicKeyStr service:_queryPublicKey callBack:^(id  _Nullable result, NSError * _Nullable error) {
                
            }];
        } else {
            [Helper printErrorDebug:@"generate public EC key fail"];
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
//ECDSA_SHA256
-(NSData *)ECDSA_SHA256SignWithType:(AlgAndEncodingEnum)AlgType withData:(NSData *)content {
    NSData *returnData = nil;
    if (!_EC_pri) {
        [Helper printDebug:@"please import private key first"];
        return returnData;
    }
    
    
    if (AlgType == UAF_ALG_SIGN_SECP256R1_ECDSA_SHA256_RAW) {
        int messageLength = (int)[content length];
        unsigned char *EM = (unsigned char *)malloc(256);
        bzero(EM, 256);
        unsigned char sha256[32];
        SHA256([content bytes], messageLength, sha256);
        
        int ret,size;
        unsigned int sig_len;
        unsigned char *signature;
//        BIO *berr;
        size=ECDSA_size(_EC_pri);
        signature=malloc(size);
//        ERR_load_crypto_strings();
//        berr=BIO_new(BIO_s_file());
//        BIO_set_fp(berr,stdout,BIO_NOCLOSE);
        

        [Helper printDebug:[NSString stringWithFormat:@"orgin:%@",[[NSData alloc]initWithBytes:sha256 length:32]] ];
        ret=ECDSA_sign(0,sha256,32,signature,&sig_len,_EC_pri);
        if(ret!=1)
        {
//            ERR_print_errors(berr);
            [Helper printDebug:@"sign err!\n"];
            
        } else {
           
            returnData = [[NSData alloc]initWithBytes:signature length:sig_len];
            
        }
        [Helper printDebug:[NSString stringWithFormat:@"signed data :%@",[[NSData alloc]initWithBytes:signature length:sig_len]] ];
        /* 验证签名 */
        ret=ECDSA_verify(0,sha256,32,signature,sig_len,_EC_pub);
        if(ret!=1)
        {
//            ERR_print_errors(berr);
            [Helper printDebug:@"ECDSA_verify err!\n"];
            
        }
//        BIO_free(berr);
    }
    
    return returnData;
}



-(int)testSign {
    int ret,nid,size,i,sig_len;
    unsigned char *signature,digest[32];
    BIO *berr;
    size=ECDSA_size(_EC_pri);
    signature=malloc(size);
    ERR_load_crypto_strings();
    berr=BIO_new(BIO_s_file());
    BIO_set_fp(berr,stdout,BIO_NOCLOSE);
    for(i=0;i<32;i++){
        memset(&digest[i],i+1,1);
    }

    /* 签名数据，本例未做摘要，可将 digest 中的数据看作是 sha1 摘要结果 */
    [Helper printDebug:[NSString stringWithFormat:@"orgin:%@",[[NSData alloc]initWithBytes:digest length:32]] ];
    ret=ECDSA_sign(0,digest,32,signature,&sig_len,_EC_pri);
    if(ret!=1)
    {
        ERR_print_errors(berr); printf("sign err!\n");
        return -1;
    }
    [Helper printDebug:[NSString stringWithFormat:@"sign :%@",[[NSData alloc]initWithBytes:signature length:sig_len]] ];
    /* 验证签名 */
    ret=ECDSA_verify(0,digest,32,signature,sig_len,_EC_pub);
    if(ret!=1)
    {
        ERR_print_errors(berr); printf("ECDSA_verify err!\n");
        return -1;
    }
    BIO_free(berr);
    return 0;
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
- (void) getPrivateKeyWithTouchIDCallback:(void(^ _Nonnull)(NSString *keyStr , NSError * _Nullable error))callBack {
    if(_shareObj && _queryPrivateKey) {
        
        if (_EC_pri) {//1.如果fidoclient没有退出，rsapri私钥一直保存在内存
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
                    if(b && _EC_pri) {
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
    EC_KEY *EC = NULL;
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
        EC = PEM_read_bio_ECPrivateKey(bio,&EC,NULL,"i-Sprint_FIDO");
        _EC_pri = EC;
        _privateKeyStr = keyString;
        if (EC != NULL && 1 == EC_KEY_check_key(EC)) {
            status = YES;
        } else {
            status = NO;
        }
    }
    else{
       EC = PEM_read_bio_EC_PUBKEY(bio,&EC,NULL,NULL);;
        _EC_pub = EC;
        if (EC != NULL) {
            status = YES;
        } else {
            status = NO;
        }
    }
    BIO_free_all(bio);
    //    [[NSFileManager defaultManager] removeItemAtPath:rsaFilePath error:nil];
    return status;
}


@end






