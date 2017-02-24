//
//  GenerateKPI.h
//  FIDOSDK
//
//  Created by hongyu on 04/01/2017.
//  Copyright © 2017 hongyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/bn.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#import "Helper.h"
#import "TagsEnumModel.h"




@interface GenerateKPI : NSObject

@property(nonatomic, strong) NSString *userid;
@property(nonatomic, strong) NSString *facetID;
@property(nonatomic, strong) NSString *appID;
@property(nonatomic, strong) NSString *keyID;
@property(nonatomic, strong) NSString * queryPublicKey;
@property(nonatomic, strong) NSString * queryPrivateKey;
@property (nonatomic , strong) NSString *privateKeyStr;
@property (nonatomic , strong) NSString *publicKeyStr;

- (id) initWithUser:(NSString *)userid facetId: (NSString *)facetid AppID: (NSString *)appid Type:(NSInteger)type KeyID: (NSString *)keyid AndKeySize:(int)keysize;

-(void)generatePair;
-(NSInteger)generateKeyFiles:(const char *)pubKeyFile : (const char *)priFeyFile :
(const unsigned char *)passwd : (int) passwd_len;

-(NSInteger)test;
-(NSString *)readTheKeyPir:(NSString *)KeyFile;

/*
 */
-(NSString *)getKeyID;
-(int)getIncrementCounter;

/*
 * sign
 *
 */
-(NSData *)RSASignWithType:(AlgAndEncodingEnum)AlgType withData:(NSData *)content;
-(NSData *)getPubkIntoData;
+ (void) deletePrivateKeyWithUser:(NSString *)userid facetId: (NSString *)facetid AppID: (NSString *)appid keyID: (NSString *)keyid ByTouchIDCallback:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
- (void)updateKeyPairAccessControlPrivateKeyCallBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
- (void) getPrivateKeyWithTouchIDCallback:(void(^ _Nonnull)(NSString *keyStr , NSError * _Nullable error))callBack;
/*
 
*/
- (BOOL)importKeyWithType:(KeyType)type andPath:(NSString*)path;
- (BOOL)importKeyWithType:(KeyType)type andkeyString:(NSString *)keyString;

//验证签名 Sha1 + RSA
- (BOOL)verifyString:(NSString *)string withSign:(NSString *)signString;
//验证签名 md5 + RSA
- (BOOL)verifyMD5String:(NSString *)string withSign:(NSString *)signString;

- (NSString *)signString:(NSString *)string;

- (NSString *)signMD5String:(NSString *)string;


- (NSString *) encryptWithPublicKey:(NSString*)content;
- (NSString *) decryptWithPrivatecKey:(NSString*)content;

/*
 ECC
 椭圆曲线的数量乘是这样定义的:设 E 为域 K 上的椭圆曲线，G 为 E 上的一点,这个点被一个正整数 k 相乘的乘法定义为 k 个 G 相加，因而有kG=G+G+ ... +G (共有k个G)若存在椭圆曲线上的另一点 N ≠ G，满足方程 kG = N。容易看出，给定 k 和 G，计算N 相对容易。而给定 N 和 G，计算 k = logG N 相对困难。这就是椭圆曲线离散对数问题。 离散对数求解是非常困难的。椭圆曲线离散对数问题比有限域上的离散对数问题更难求解。
 */
@end
