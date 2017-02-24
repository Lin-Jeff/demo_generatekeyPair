//
//  TouchIDObj.h
//  YESsafeToken
//
//  Created by LTH on 3/8/16.
//  Copyright © 2016 i-Sprint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Helper.h"

@interface TouchIDObj : NSObject
+ (TouchIDObj *)shareObject ;
- (void)addPwdItem:(NSString *)pwd service:(NSString *)serviceStr;

- (void)deleteItemAsync:(NSString *)serviceStr;

- (void)updateItemAsync:(NSString *)serciceStr andUpdatePwd:(NSString *)newPwd;

- (void)queryItemAsync:(NSString *)serviceStr takeVC:(UIViewController *)tVC;

//...

//- (void)addKeyPair:(SecKeyRef)privateKey userId:(NSString *)userid facetId: (NSString *)facetid callBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
- (void )queryItemService:(NSString *)serviceStr  callBack:(void(^ _Nonnull)(NSString *result , NSError * _Nullable error))callBack;
//- (void)deleteItemAsyncUserId:(NSString *)userid facetId: (NSString *)facetid;
- (void)addKeyPairString:(NSString *)KeyString service:(NSString *)serviceStr callBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
+ (void) deletePairKeyWithServiceStr:(NSString *)serviceStr ByTouchIDCallback:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
- (void)updateKeyPairAccessControlPrivateKeyWithServiceStr:(NSString *)serviceStr CallBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack;
/*
 * keyId 和 counter
 *
 * 保存keyID到keychain的key是facetid|_|appid
 *
 */
- (void)addKeyIDByKey: (NSString *)facetidappid KeyID: (NSString *)keyid;
- (NSString *)selKeyIDByFacetid_Appid: (NSString *)facetidAppid;
-(NSString *)getKeyIDByFacetid_Appid: (NSString *)facetidAppid;
- (void)addIncrementCounterByKey: (NSString *)facetidappid IncrementCounter: (int)IC;
- (NSString *)selIncrementCounter: (NSString *)facetidappid;
-(int)getIncrementCounterByFacetid_Appid: (NSString *)facetidAppid;
@end
