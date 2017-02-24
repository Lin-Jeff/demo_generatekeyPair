
//
//  TouchIDObj.m
//  YESsafeToken
//
//  Created by LTH on 3/8/16.
//  Copyright © 2016 i-Sprint. All rights reserved.
//

#import "TouchIDObj.h"
//#import "TokenUtils.h"

#define PRIVATE_KEY @"TouchIDPrivateKey"
#define PUBLIC_KEY @"TouchIDPublicKey"
#import "Helper.h"

@implementation TouchIDObj

+ (TouchIDObj *)shareObject {
    static TouchIDObj *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[TouchIDObj alloc] init];
    });
    return sharedAccountManagerInstance;
}

- (void)addPwdItem:(NSString *)pwd service:(NSString *)serviceStr
{
    CFErrorRef error = NULL;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    kSecAccessControlTouchIDAny, &error);
    
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        NSLog(@">>>>> , %@", errorString);
        
        return;
    }
    
    // we want the operation to fail if there is an item which needs authentication so we will use
    // kSecUseNoAuthenticationUI
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: serviceStr,
                                 (__bridge id)kSecValueData: [pwd dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        NSString *errorString = [TouchIDObj keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];
        
         NSLog(@">>>>> , %@", message);
    });
}


/*
 serviceStr :  PRIVATE_KEY|_|faectID|_|appid|_|KeyId
 
 */

- (void)addKeyPairString:(NSString *)KeyString service:(NSString *)serviceStr callBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack
{
    
    CFErrorRef error = NULL;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    kSecAccessControlTouchIDAny, &error);
    
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        NSLog(@">>>>> , %@", errorString);
        callBack(nil , (__bridge_transfer  NSError*)error);
    }

    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: serviceStr,
                                 (__bridge id)kSecValueData: [KeyString dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };

//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        NSString *errorString = [TouchIDObj keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];
        
        if ([errorString isEqualToString:@"success"]) {
            
            callBack(nil , nil);
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
           callBack(nil , error1);
        }
//    });
}

+ (void) deletePairKeyWithServiceStr:(NSString *)serviceStr ByTouchIDCallback:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack {

    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serviceStr
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus sanityCheck = SecItemDelete((__bridge CFDictionaryRef)query);
    
        if (sanityCheck == errSecSuccess || sanityCheck == errSecItemNotFound) {//note no found and delete success
            [Helper printDebug:[NSString stringWithFormat:@"%@SoftwarePKI delete privateKey:%d ",serviceStr,sanityCheck]];
            callBack(nil,nil);
        } else {
            
            NSString *message = [NSString stringWithFormat:@"SoftwarePKI delete privateKey: %@",[TouchIDObj keychainErrorToString:sanityCheck]];
            [Helper printErrorDebug:message];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0x3 userInfo:userInfo];
            callBack(NULL , error1);
        }
    });

}

- (void )queryItemService:(NSString *)serviceStr  callBack:(void(^ _Nonnull)(NSString *result , NSError * _Nullable error))callBack {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serviceStr,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"Finger Print Authentication", @"")
                            };
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        CFErrorRef error = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            callBack(result , nil);
        } else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [TouchIDObj keychainErrorToString:status]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
            callBack(nil , error1);
        }
    });
}
/*
- (void)updateKeyPairAccessControlPrivateKeyWithServiceStr:(NSString *)serviceStr CallBack:(void(^ _Nonnull)(id _Nullable result , NSError * _Nullable error))callBack {
    
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serviceStr,
                            (__bridge id)kSecReturnData: @YES,
//                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"touch_ID_pwd", @"")
                            };
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        CFErrorRef error = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
            status = SecItemDelete((__bridge CFDictionaryRef)(query));
            if (status != errSecSuccess) {
                NSString *errorString = [TouchIDObj keychainErrorToString:status];
                message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
                callBack(nil , error1);
            } else {
                //            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                
                //            message = [NSString stringWithFormat:@"Result: %@\n", result];
                
                // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
                SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                                kSecAccessControlTouchIDAny, &error);
                
                if (sacObject == NULL || error != NULL) {
                    NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
                    
                    NSLog(@">>>>> , %@", errorString);
                    callBack(nil , (__bridge_transfer  NSError*)error);
                }
                
                // we want the operation to fail if there is an item which needs authentication so we will use
                // kSecUseNoAuthenticationUI
                //    NSString *pIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@.%@.%@", PRIVATE_KEY, userid,facetid];
                //    NSData *pTag = [pIdentifier dataUsingEncoding:NSUTF8StringEncoding];
                
                NSDictionary *attributes = @{
                                             (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                             (__bridge id)kSecAttrService: serviceStr,
                                             (__bridge id)kSecValueData: resultData,
                                             (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                             (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                             };
                
                //    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
                
                NSString *errorString = [TouchIDObj keychainErrorToString:status];
                NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];
                
                if ([errorString isEqualToString:@"success"]) {
                    
                    callBack(nil , nil);
                } else {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                    NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
                    callBack(nil , error1);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //              [tVC dismissViewControllerAnimated:YES completion:nil];
                });
            }
        } else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [TouchIDObj keychainErrorToString:status]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
            callBack(nil , error1);
        }
        //NSLog(@">>>>> : %@", message);
    });

}

- (void )queryItemUserId:(NSString *)userid facetId: (NSString *)facetid callBack:(void(^ _Nonnull)(SecKeyRef result , NSError * _Nullable error))callBack
{
    NSString *publicIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@|_|%@|_|%@", PRIVATE_KEY, userid,facetid];
    NSData *publicTag = [publicIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: publicIdentifier,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"touch_ID_pwd", @"")
                            };
    

        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
             callBack(((__bridge SecKeyRef)CFBridgingRelease(dataTypeRef)) , nil);
        }
        else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [TouchIDObj keychainErrorToString:status]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
            NSError *error1 = [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:userInfo];
            callBack(NULL , error1);
        }
}

- (void)deleteItemAsyncUserId:(NSString *)userid facetId: (NSString *)facetid
{
    NSString *publicIdentifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@"%@|_|%@|_|%@", PRIVATE_KEY, userid,facetid];
    NSData *publicTag = [publicIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: publicIdentifier
                            };
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        
        NSString *errorString = [TouchIDObj keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", errorString];
        
        NSLog(@">>>>> : %@", message);
//    });
}


//.............
- (void)deleteItemAsync:(NSString *)serviceStr
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serviceStr
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        
        NSString *errorString = [TouchIDObj keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", errorString];
        
        NSLog(@">>>>> : %@", message);
    });
}

- (void)updateItemAsync:(NSString *)serciceStr andUpdatePwd:(NSString *)newPwd
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serciceStr,
//                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"touch_ID_pwd", @"")
                            };
    
    NSData *updatedSecretPasswordTextData = [newPwd dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *changes = @{
                              (__bridge id)kSecValueData: updatedSecretPasswordTextData
                              };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        
        NSString *errorString = [TouchIDObj keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemUpdate status: %@", errorString];
        
        NSLog(@">>>>>> :%@", message);
    });
}

- (void)queryItemAsync:(NSString *)serviceStr takeVC:(UIViewController *)tVC;
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: serviceStr,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"touch_ID_pwd", @"")
                            };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
            
            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            
            message = [NSString stringWithFormat:@"Result: %@\n", result];
            
//            [TokenUtils setPwdInAES:result];
            //NSLog(@">>>>> %@",   [TokenUtils getPwdFromAES]);
          dispatch_async(dispatch_get_main_queue(), ^{
//              [tVC dismissViewControllerAnimated:YES completion:nil];
          });
        }
        else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [TouchIDObj keychainErrorToString:status]];
        }
        //NSLog(@">>>>> : %@", message);
    });
}*/

+ (NSString *)keychainErrorToString:(OSStatus)error {
    NSString *message = [NSString stringWithFormat:@"%ld", (long)error];
    
    switch (error) {
        case errSecSuccess:
            message = @"success";
            break;
            
        case errSecDuplicateItem:
            message = @"error item already exists";
            break;
            
        case errSecItemNotFound :
            message = @"error item not found";
            break;
            
        case errSecAuthFailed:
            message = @"error item authentication failed";
            break;
            
        default:
            break;
    }
    return message;
}

/************************************************************************
 * KeyID和Counter的存储 
 *
 *
 *
 *
 *
 ************************************************************************/
//add keyid
- (void)addKeyIDByKey: (NSString *)facetidappid KeyID: (NSString *)keyid {
    if(facetidappid.length > 0 && keyid.length > 0) {
        NSDictionary* query = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
                               facetidappid,(__bridge id)kSecAttrAccount,
                               (__bridge id)kCFBooleanTrue,(__bridge id)kSecReturnData,nil];
        CFTypeRef result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
        if(status == noErr) {
            status = SecItemDelete((__bridge CFDictionaryRef)(query));
            
        }
        NSMutableDictionary* dic = [NSMutableDictionary dictionary];
        [dic setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [dic setObject:facetidappid forKey:(__bridge id)kSecAttrAccount];
        [dic setObject:[keyid dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        
        status = SecItemAdd((CFDictionaryRef)dic, NULL);
        [Helper printErrorDebug:[TouchIDObj keychainErrorToString:status]];
    }
}
//保存keyID到keychain的key是facetid|_|appid
- (NSString *)selKeyIDByFacetid_Appid: (NSString *)facetidAppid {
    if(facetidAppid.length > 0) {
        NSDictionary* query = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
                               facetidAppid,(__bridge id)kSecAttrAccount,
                               (__bridge id)kCFBooleanTrue,(__bridge id)kSecReturnData,nil];
        CFTypeRef result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
        [Helper printErrorDebug:[TouchIDObj keychainErrorToString:status]];
        if(status == noErr) {
            return [[NSString alloc] initWithData:CFBridgingRelease(result) encoding:NSUTF8StringEncoding];
        }
    }
    
    return @"";
}

-(NSString *)getKeyIDByFacetid_Appid: (NSString *)facetidAppid  {
    [Helper printDebug:[NSString stringWithFormat:@"keyID: %@",[self selKeyIDByFacetid_Appid:facetidAppid]]];
    return [self selKeyIDByFacetid_Appid:facetidAppid];
}


//保存IncrementCounter到keychain的key是facetid|_|appid|_|IncrementCounter
//add keyid
- (void)addIncrementCounterByKey: (NSString *)facetidappid IncrementCounter: (int)IC {
    if(facetidappid.length > 0 ) {
        NSDictionary* query = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
                               [NSString stringWithFormat:@"%@|_|IncrementCounter",facetidappid],(__bridge id)kSecAttrAccount,
                               (__bridge id)kCFBooleanTrue,(__bridge id)kSecReturnData,nil];
        CFTypeRef result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
        if(status == noErr) {
            status = SecItemDelete((__bridge CFDictionaryRef)(query));
            
        }
        
        
        NSMutableDictionary* dic = [NSMutableDictionary dictionary];
        [dic setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [dic setObject:[NSString stringWithFormat:@"%@|_|IncrementCounter",facetidappid] forKey:(__bridge id)kSecAttrAccount];
        [dic setObject:[[NSString stringWithFormat:@"%d",IC] dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        
        status = SecItemAdd((CFDictionaryRef)dic, NULL);
        [Helper printErrorDebug:[TouchIDObj keychainErrorToString:status]];
    }
}

- (NSString *)selIncrementCounter: (NSString *)facetidappid {
    if(facetidappid.length > 0 ) {
        NSDictionary* query = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
                               [NSString stringWithFormat:@"%@|_|IncrementCounter",facetidappid],(__bridge id)kSecAttrAccount,
                               (__bridge id)kCFBooleanTrue,(__bridge id)kSecReturnData,nil];
        CFTypeRef result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
        if(status == noErr) {
            return [[NSString alloc] initWithData:CFBridgingRelease(result) encoding:NSUTF8StringEncoding];
            
        }
    }
    return @"0";
}
-(int)getIncrementCounterByFacetid_Appid: (NSString *)facetidAppid {
    int counter = [[self selIncrementCounter:facetidAppid] intValue];
    [Helper printDebug:[NSString stringWithFormat:@"IncrementCounter: %ld",(long)counter]];
    //++
    [self addIncrementCounterByKey:facetidAppid IncrementCounter:counter+1];
    return counter;
}

@end
