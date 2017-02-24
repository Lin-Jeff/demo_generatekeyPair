//
//  ViewController.m
//  GenerateKeyPair
//
//  Created by hongyu on 23/02/2017.
//  Copyright © 2017 hongyu. All rights reserved.
//

#import "ViewController.h"
#import "GenerateECCkeyPair.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *pubPath = [NSString stringWithFormat:@"%@%s",FILEPATH,PUBLIC_KEY_FILE];
    NSString *priPath = [NSString stringWithFormat:@"%@%s",FILEPATH,PRIVATE_KEY_FILE];

    GenerateECCkeyPair *object = [[GenerateECCkeyPair alloc] initWithUser:@"" facetId:@"facetID" AppID:@"appID" Type:FIDO_Reg KeyID:@"keyid" AndKeySize:256];
    int b = [object generateKeyFiles:[pubPath UTF8String] :[priPath UTF8String] :NULL :0];
    if (b < 0 ) {
        NSLog(@"generatePair fail");
    } else {
        [object importKeyWithType:KeyTypePublic andPath:pubPath];
        [object importKeyWithType:KeyTypePrivate andPath:priPath];
        [Helper printDebug:[NSString stringWithFormat:@"public cert : %@ \n and the length is:%d",[object getPubkIntoData],[[object getPubkIntoData] length]]];
        [object ECDSA_SHA256SignWithType:UAF_ALG_SIGN_SECP256R1_ECDSA_SHA256_RAW withData:[@"this is a test data for ESDSA_SHA256 Alg" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
