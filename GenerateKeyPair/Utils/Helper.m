//
//  Helper.m
//  navigate@SRPL
//
//  Created by hongyu on 8/5/16.
//  Copyright © 2016 hongyu. All rights reserved.
//

#import "Helper.h"
#import <LocalAuthentication/LocalAuthentication.h>
//#import "SaveLogInFile.h"

//#import "LDownRequestObject.h"
//#import "CoreDataManager.h"

// BCrypt parameters
#define BCRYPT_SALT_LEN  16
#define GENSALT_DEFAULT_LOG2_ROUNDS 10

#define FILEPATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define PRIVATE_KEY_FILE "/private.pem"
#define PUBLIC_KEY_FILE  "/public.pem"


static bool enableLog = false;
@implementation Helper

//背景渐变...
+ (CAGradientLayer *)setgradient:(NSArray *)array withSuperV:(UIView *) superV{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = superV.frame;
    superV.layer.frame = superV.frame;
    NSMutableArray *colors = [[NSMutableArray alloc]init];
    for (int i = 0; i < array.count; i++) {
        [colors addObject:(id)[(UIColor *)[array objectAtIndex:i] CGColor]];
    }
    gradient.colors = colors;
    return gradient;
    //    [self.view.layer insertSublayer:gradient atIndex:0];
}

//...
//在正方体里面画圆
+ (UIImage *)ArcimageWithColor:(UIColor *)color size:(CGSize)size Radius:(CGFloat)radius
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddArc(context, width/2, height/2, radius, 0, 2*M_PI, 0);
    
    CGContextClosePath(context);
    // 填充半透明黑色
    //    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.5);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextDrawPath(context, kCGPathEOFill);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

//CunstomBtnSetInsert
//根据提供的图片size设置btn的imageEdgeInsets
+(void)CustomBtnSetInsert:(UIButton *)btn withImg:(UIImage *)img {
    
    CGSize size = img.size;
    CGFloat A = size.height/size.width;
    if (A != 1) {
        CGFloat factor =  (A > 1) ? (size.width/size.height):(size.height/size.width);
        CGFloat virtualH = (A >= 1) ? CGRectGetHeight(btn.frame) : (CGRectGetWidth(btn.frame) * factor);
        CGFloat virtualW = (A >= 1) ? (CGRectGetHeight(btn.frame) * factor) : CGRectGetWidth(btn.frame);
        CGFloat distanceH = (CGRectGetHeight(btn.frame) - virtualH)/2;
        CGFloat distanceW = ABS(CGRectGetWidth(btn.frame) - virtualW)/2;
        
            btn.imageEdgeInsets = UIEdgeInsetsMake(distanceH,
                                                               distanceW,
                                                               distanceH, distanceW);
    }
}

+ (NSString *)filePath:(NSString *)fileName {
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *pathString = [NSString stringWithFormat:@"%@",fileName];
    NSString *sendListPath = [documentsDir stringByAppendingPathComponent:pathString];
    return sendListPath;
}

+ (NSString *)filePathDir:(NSString *)dir name:(NSString *)fileName {
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dirPath = [documentsDir stringByAppendingPathComponent:dir];
    if (![manager fileExistsAtPath:dirPath] ) {
        [manager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *savePath = [dirPath stringByAppendingPathComponent:fileName];
    return savePath;
}

//scale the image by devices
+ (UIImage *)convertViewToImage:(UIView*)v Size:(CGSize)size{
    CGSize s = size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+(void)enableLog:(BOOL)b {
    enableLog = b ? true : false;
}
+(BOOL)isDebug {
    return enableLog;
}

+(void)printDebug:(NSString *)mes {
    if (enableLog) {
        NSLog(@"***DebugMes***: %@ \n\n",mes);
        //...save the log for debug
        //        SaveLogInFile *logFile = [SaveLogInFile sharedInstance];
        //        [logFile writefile:[NSString stringWithFormat:@"Debug: %@",mes]];
    }
}

+(void)printErrorDebug:(NSString *)mes {
    if (enableLog) {
        NSLog(@"\n\n***DebugMes—警告⚠️***: %@\n\n",mes);
        //...save the log for debug
        //        SaveLogInFile *logFile = [SaveLogInFile sharedInstance];
        //        [logFile writefile:[NSString stringWithFormat:@"Debug: %@",mes]];
    }
}
+(BOOL)isBase64Str:(NSString *)originStr {
    NSString *str = originStr;
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    str = [str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSInteger remainder = str.length%4;//当使用iOS自带的base64解析API的时候如果长度不是双数的话要补=字符
    if (remainder > 1 && remainder < 3) {
        str = [NSString stringWithFormat:@"%@==",str];
    } else if (remainder > 2) {
        str = [NSString stringWithFormat:@"%@=",str];
    }
    NSString *regex = @"^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isValid = [predicate evaluateWithObject:str];
    return isValid;
}



+ (NSMutableURLRequest *)buildRequest:(NSString *)endpoint method:(NSString *)method body:(NSData *)body {
   NSString *urlStr = [endpoint stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlStr = [urlStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (url) {
        [Helper printDebug:[NSString stringWithFormat:@"url:%@",url]];
    } else {
        [Helper printDebug:@"error url"];
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    request.HTTPMethod = method;
    [request addValue:_contentTypeJSON forHTTPHeaderField:_httpContentTypeHeader];
    if (body) {
        request.HTTPBody = body;
    }
    return request;
}

//单例...
+(Helper *)sharedInstance
{
    static Helper *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [Helper new];
    });
    return sharedManager;
}

- (void)performRequest:(NSMutableURLRequest *)request Callback:(void(^ _Nonnull)( id _Nullable result , NSError * _Nullable error ))callback {
    NSURLSessionConfiguration *configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    __block NSURLSessionDataTask *task;

    task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            NSString *debugM = [NSString stringWithFormat:@"error:%@",error];
            [Helper printDebug:debugM];
            callback(nil,error);
            return ;
        }
        NSHTTPURLResponse *response1 = (NSHTTPURLResponse *)response;
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
            NSInteger statusCode = response1.statusCode;
            if (statusCode != 200) {
                NSString *debugMes = [NSString stringWithFormat:@"error: status :%@\nrequest url:%@",[response1.allHeaderFields objectForKey:@"Status"],request.URL];
                [Helper printDebug:debugMes];
                
                callback(nil, [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:@{NSLocalizedDescriptionKey : [response1.allHeaderFields objectForKey:@"Status"]}]);
                return;
            }
            if (json) {
                
                callback(json , nil);
            } else if(jsonError){
                callback(nil , jsonError);
            }
        }else {
            callback(nil , [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:@{NSLocalizedDescriptionKey : @"The receive data is null!"}]);
        }
    }];
    [task resume];
}

//nssession delegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    
}
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if(challenge.protectionSpace.authenticationMethod
        == NSURLAuthenticationMethodServerTrust) {
        [Helper printDebug:@"服务端证书认证！"];
        
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        NSData * remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"testserver" ofType:@"cer"];
        NSData *localCertificateData = [NSData dataWithContentsOfFile:cerPath];
        if ([remoteCertificateData isEqual:localCertificateData]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
           completionHandler(NSURLSessionAuthChallengeUseCredential,
                             [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        }
}

//get the default session
- (NSURLSession *)getCurrentSession
{
    @autoreleasepool {
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        return [NSURLSession sessionWithConfiguration:defaultConfig delegate:nil delegateQueue:nil];
    }
}

- (void)performWithDefaultSectionRequest:(NSMutableURLRequest *)request Callback:(void(^ _Nonnull)( id _Nullable result , NSError * _Nullable error ))callback {
    NSURLSession *session = [self getCurrentSession];
    __block NSURLSessionDataTask *task;
    
    task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            NSString *debugM = [NSString stringWithFormat:@"error:%@",error];
            [Helper printDebug:debugM];
            callback(nil,error);
            return ;
        }
        NSHTTPURLResponse *response1 = (NSHTTPURLResponse *)response;
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
            NSInteger statusCode = response1.statusCode;
            if (statusCode != 200) {
                NSString *debugMes = [NSString stringWithFormat:@"error: status :%@\nrequest url:%@",[response1.allHeaderFields objectForKey:@"Status"],request.URL];
                [Helper printDebug:debugMes];
                
                callback(nil, [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0xFF userInfo:@{NSLocalizedDescriptionKey : [response1.allHeaderFields objectForKey:@"Status"]}]);
                return;
            }
            if (json) {
                
                callback(json , nil);
            } else if(jsonError){
                callback(nil , jsonError);
            }
        }else {
            callback(nil , [NSError errorWithDomain:YESSAFEERRORDOMAIN code:0 userInfo:@{NSLocalizedDescriptionKey : @"The receive data is null!"}]);
        }
    }];
    [task resume];
}

-(NSData *)dictionaryToJSON:(NSDictionary *)dict {
    NSError *jsonError;
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (json && !jsonError) {
        return json;
    }
    [Helper printDebug:jsonError.localizedDescription];
    return nil;
}
/*
 *  PostStats
 *
 */
//-(void)postStatsRequest:(NSArray *)headers :(NSArray *)values  Callback:(void(^ _Nonnull)())callback{
//    [Helper printDebug:[NSString stringWithFormat:@"stats: %@",headers]];
//    CommonValues *com = [CommonValues shareObject];
////    __block __weak Helper* weakself = self;
//    UIDevice *device = [UIDevice currentDevice];
//    NSString *type = device.model;       //获取设备
//    NSString *systemName = device.systemName;
//    NSString *systemVersion = device.systemVersion;//获取当前系统的版本
//    
//    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[Utils GetSerialNumber],@"machineId",
//                            [NSString stringWithFormat:@"%@_%@",systemName,systemVersion],@"machineName"
//                            ,type,@"machineType"
//                            ,headers,@"statsHeaders"
//                            ,values,@"statsValues"
//                            , nil];
//    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
//    NSMutableURLRequest *request = [Helper buildRequest:[com getUrlWithType:PostAppFeedbackUrl] method:POST body:data];
//    __block __weak Helper* wself = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        __strong Helper* sself = wself;
//        [sself performRequest:request Callback:^(id  _Nullable result, NSError * _Nullable error) {
//            [Helper printDebug:[NSString stringWithFormat:@"postStatsRequest%@",result]];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //return to list
//                callback();
//                
//                
//            });
//           /* if (error) {
//                [Helper printDebug:error.localizedDescription];
//                [Helper showOkayCancelAlert:self mes:error.localizedDescription ok:YES cancel:NO okHandel:^{
//                } cancemHandel:^{
//                }];
//                return ;
//            }
//            NSDictionary *dict = [result objectForKey:@"result"];
//            if (![dict objectForKey:@"ok"]) {
//                [Helper printDebug:[result objectForKey:@"message"]];
//                [Helper showOkayCancelAlert:self mes:[result objectForKey:@"message"] ok:YES cancel:NO okHandel:^{
//                    
//                } cancemHandel:^{
//                    
//                }];
//                return ;
//            } else {
//                [Helper showOkayCancelAlert:self mes:@"Commit successfully, Thank you for your feedback!" ok:YES cancel:NO okHandel:^{
//                    
//                } cancemHandel:^{
//                    
//                }];
//            }*/
//        }];
//    });
//    
//    
//
//}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    }else {
        result = window.rootViewController;
    }
    return result;
}

#pragma mark 文件操作---------start---------
/**
 *  获取沙盒路径
 *
 *  @param filename 新加入的目录路径
 *
 *  @return NSString全路径
 */
+ (NSString *)sandBoxPath:(NSString *)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory=[paths objectAtIndex:0];//Documents目录
    return [documentsDirectory stringByAppendingPathComponent:filename];
}

/**
 *  获得下载文件的文件夹路径
 *
 *  @param fileName 文件名称
 *
 *  @return NSString
 */
+ (NSString *)downFolderOfSandBoxPath:(NSString *)fileName
{
    return [[Helper sandBoxPath:@"fileDown"] stringByAppendingPathComponent:fileName];
}

/**
 *  获得本地下载的文件列表数组
 *
 *  @return NSMutableArray
 */
//+ (NSMutableArray *)getSandBoxOfDownFileArray
//{
//    NSMutableArray *fileArray = [[NSMutableArray alloc]init];
//    NSString *downFolderPath = [Helper downFolderOfSandBoxPath:@""];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    //先查看文件夹存不存在
//    BOOL folderExist = [fileManager fileExistsAtPath:downFolderPath];
//    if (!folderExist) {//不存在创建
//        BOOL folderCreate = [fileManager createDirectoryAtPath:downFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
//        if (folderCreate) {
//            NSLog(@"创建成功");
//        }else {
//            NSLog(@"创建失败");
//        }
//    }
//    //文件Model
//    NSArray *downLoadedArray = [[LDownRequestObject shareDownRequestObject].coreDataManager selectCoreDataWithDownLoaded];
//    for (DownLoaded *downLoaded in downLoadedArray) {
//        DownLoadFile *downLoadFile = [[LDownRequestObject shareDownRequestObject].coreDataManager selectCoreDataWithDownLoadFileWithLoadUrl:downLoaded.fileUrl];
//        if (downLoadFile && [fileManager fileExistsAtPath:[Helper downFolderOfSandBoxPath:downLoadFile.fileLocPath]]) {
//            [fileArray addObject:downLoadFile];
//        }
//    }
//    return fileArray;
//}

/**
 *  清除沙盒中下载的文件
 *
 *  @param fileArray 需要清除的文件数组
 *
 *  @return BOOL YES:清除成功  NO:清除失败
 */
//+ (NSMutableArray *)clearSandBoxOfDownFileWithFileArray:(NSMutableArray *)fileArray
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *error = nil;
//    //倒序遍历
//    for (int i = [fileArray count]-1; i >= 0; i --) {
//        DownLoadFile *downLoadFile = [fileArray objectAtIndex:i];
//        BOOL fileExist = [fileManager fileExistsAtPath:[Helper downFolderOfSandBoxPath:downLoadFile.fileLocPath]];
//        //如果文件名称和时间相同则删除
//        if (fileExist) {
//            [fileManager removeItemAtPath:[Helper downFolderOfSandBoxPath:downLoadFile.fileLocPath] error:&error];
//            [fileArray removeObjectAtIndex:i];//移除
//            //删除已下载数据库
//            [[LDownRequestObject shareDownRequestObject].coreDataManager deleteCoreDataWithFileUrl:downLoadFile.fileUrl];
//            //同时删除downLoadFile数据库表中的数据
//            [[LDownRequestObject shareDownRequestObject].coreDataManager deleteCoreDataOfDownLoadFileWithFileUrl:downLoadFile.fileUrl];
//        }
//    }
//    return fileArray;
//}

/**
 *  创建文件夹
 */
+ (void)createDownFile
{
    NSString *downFolderPath = [Helper downFolderOfSandBoxPath:@""];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //先查看文件夹存不存在
    BOOL folderExist = [fileManager fileExistsAtPath:downFolderPath];
    if (!folderExist) {//不存在创建
        BOOL folderCreate = [fileManager createDirectoryAtPath:downFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (folderCreate) {
            NSLog(@"创建成功");
        }else {
            NSLog(@"创建失败");
        }
    }
}

/**
 *  写入文件
 *
 *  @param sourcePath     来源路径
 *  @param targetFileName 目的文件名称
 */
+ (NSString *)writeFileWithSourcePath:(NSString *)sourcePath withTargetFileName:(NSString *)targetFileName
{
    [Helper createDownFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *myData = [fileManager contentsAtPath:sourcePath]; // 从一个文件中读取数据
    BOOL create = [fileManager createFileAtPath:[Helper downFolderOfSandBoxPath:targetFileName] contents:myData attributes:nil];
    if (create) {
        NSLog(@"%@-文件写入成功",targetFileName);
        return targetFileName;
    }else {
        NSLog(@"%@-文件写入失败",targetFileName);
        return nil;
    }
}

/**
 *  删除临时目录中的文件
 *
 *  @param sourcePath 来源路径
 */
+ (void)deleteFileWithSourcePath:(NSString *)sourcePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL remove = [fileManager removeItemAtPath:sourcePath error:&error];
    if (remove) {
        NSLog(@"移除成功");
    }else {
        NSLog(@"移除失败");
    }
}

/**
 *  截取出路径中的文件名称
 *
 *  @param filePath 文件路径
 *
 *  @return NSString
 */
+ (NSString *)cutOutFileNameWithFilePath:(NSString *)filePath
{
    //截取出1.pdf  http://192.168.191.1/complaince/files/1.pdf
    NSInteger lineLocation = [filePath rangeOfString:@"/"].location;
    while (lineLocation != NSNotFound) {
        filePath = [filePath substringFromIndex:lineLocation+1];
        lineLocation = [filePath rangeOfString:@"/"].location;
    }
    return filePath;
}

+ (NSString *)cutOutFileTypeWithFilePath:(NSString *)filePath
{
    //pdf  http://192.168.191.1/complaince/files/1.pdf
    NSInteger docLocation = [filePath rangeOfString:@"."].location;
    while (docLocation != NSNotFound) {
        filePath = [filePath substringFromIndex:docLocation+1];
        docLocation = [filePath rangeOfString:@"."].location;
    }
    return filePath;
}

/**
 *  判断此文件是否存在
 *
 *  @param fileName 文件的路径
 *
 *  @return BOOL yes:存在  no:不存在
 */
+ (BOOL)judgeIsExistOfFilePath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExist = [fileManager fileExistsAtPath:filePath];
    return fileExist;
}

+ (void)showOkayCancelAlert:(UIViewController *)VC mes:(NSString *)mes ok:(BOOL)ok cancel:(BOOL)canel okHandel:(void(^)())okHandel cancemHandel:(void(^)())cancemHandel {
    NSString *title = @"";//NSLocalizedString(@"A Short Title Is Best", nil);
    NSString *message = NSLocalizedString(@"A message should be a short, complete sentence.", nil);
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:mes preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        cancemHandel();
        [Helper printDebug:@"The \"Okay/Cancel\" alert's cancel action occured."];
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        okHandel();
        [Helper printDebug:@"The \"Okay/Cancel\" alert's other action occured."];
        
    }];
    
    // Add the actions.
    ok    ? [alertController addAction:otherAction] : [Helper printDebug:@"The \"Okay"];
    canel ? [alertController addAction:cancelAction] : [Helper printDebug:@"The \"cancel"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [VC presentViewController:alertController animated:YES completion:nil];
    });
}


#pragma UIAlterView function
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message withDelegate:(id)delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:NSLocalizedStringFromTable(@"Confirm",@"Localizable",nil) otherButtonTitles: nil];
    [alert show];
    
}
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message delegate:(id)_delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:_delegate cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel",@"Localizable",nil) otherButtonTitles: NSLocalizedStringFromTable(@"Confirm",@"Localizable",nil),nil];
    [alert show];
}
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message delegate:(id)_delegate withTag:(NSInteger)tag;
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:_delegate cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel",@"Localizable",nil) otherButtonTitles: NSLocalizedStringFromTable(@"Confirm",@"Localizable",nil),nil];
    alert.tag = tag;
    [alert show];
}

//获取初始化设置是否完成
+ (void)setStateInitializeSetting {
    NSUserDefaults *myton = [NSUserDefaults standardUserDefaults];
    [myton setValue:@"N" forKey:@"InitializeSetStateFinish"];
    [myton synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setStateInitializeSetFinished {
    NSUserDefaults *myton = [NSUserDefaults standardUserDefaults];
    [myton setValue:@"Y" forKey:@"InitializeSetStateFinish"];
    [myton synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getInitializeSetState {
    NSUserDefaults *myton = [NSUserDefaults standardUserDefaults];
    if ([[myton objectForKey:@"InitializeSetStateFinish"] isEqualToString:@"Y"]) {
        return true;
    }
    else {
        return false;
    }
}

+ (void)showPopMessageInView:(UIView *)view Mes:(NSString *)mes {
    
}

//...
+(NSString *)isNullValue:(id)value {
    BOOL b = [value isKindOfClass:[NSNull class]];
    if (b) {
         return @"";
    } else {
        NSRange range = [(NSString *)value rangeOfString:@"<null>"];
        NSRange range1 = [(NSString *)value rangeOfString:@"(null)"];
        if ( (range.location != NSNotFound) || (range1.location != NSNotFound)) {
            return @"";
        } else return value;
    }
}

/*
 * 缓存地图到本地
 *
 *
 *
 */
+(BOOL)saveMap:(UIImage *)img {
    NSString *dirPath = [Helper filePath:@"CusMap"];
    NSData *data = UIImagePNGRepresentation(img);
    BOOL b =[Helper createFile:data fileName:@"map.png" FilePath:dirPath];
    return b;
}

+(void)removeMap {
    NSError *error;
    NSString *path = [[Helper filePath:@"CusMap"] stringByAppendingPathComponent:@"map.png"];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:path error:&error];
}

+(NSString *)getMapPath{
    NSString *path = [[Helper filePath:@"CusMap"] stringByAppendingPathComponent:@"map.png"];
    return path;
}

/*
 * 缓存cover到本地
 *
 *
 *
 */
+(BOOL)saveCover:(NSData *)data WithName:(NSString *)name{
    NSString *dirPath = [Helper filePath:@"CoverDown"];
    BOOL b =[Helper createFile:data fileName:name FilePath:dirPath];
    return b;
}

+(void)removeCover {
    NSError *error;
    NSString *path = [Helper filePath:@"CoverDown"] ;
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:path error:&error];
}

+(NSString *)getCoverPath:(NSString *)name{
    NSString *path = [Helper filePathDir:@"CoverDown" name:name];
    return path;
}

+(BOOL)isCoverExist:(NSString *)name {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:[Helper getCoverPath:name]]) {
        return YES;
    } else return NO;
}

//create dir for map
+(BOOL)createFile:(NSData *)data fileName:(NSString *)name  FilePath:(NSString *)path {
    BOOL b = NO;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *path1 = [path stringByAppendingPathComponent:name];
    if (![manager fileExistsAtPath:path1]) {
        b = [data writeToFile:path1 atomically:YES];
    }
    return b;
}

/*
 *获取设备信息
 */

+(NSString *)getDeviceInfo {
    UIDevice *device = [UIDevice currentDevice];
    NSString *name = device.model;       //获取设备
    NSString *systemName = device.systemName;
    NSString *systemVersion = device.systemVersion;//获取当前系统的版本
    return [NSString stringWithFormat:@"%@_%@:%@",name,systemName,systemVersion];
}
//iOS获取当天0点
+ (NSDate *)zeroOfDate
 {

     NSCalendar *calendar = [NSCalendar currentCalendar];
     
     NSDate *now = [NSDate date];
     
     NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
     NSDate *startDate = [calendar dateFromComponents:components];
     NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
     return endDate;
}

//build X-Callback-URL Transport
//+(NSString *)buildXCallbackURL:(NSString *)targetUrl :(UAFxType)requestType :(UAFxType)responseType :(NSString *)Key :(NSString *)state :jsonStr:(NSString *)json {
//    NSString *requestTypeStr,*responseTypeStr;
//    requestTypeStr = @""; responseTypeStr = @"";
//    if (requestType == UAF_OPERATION) {
//        requestTypeStr = @"UAF_OPERATION";
//    }
//    if (responseType == UAF_OPERATION_RESULT) {
//        responseTypeStr = @"UAF_OPERATION_RESULT";
//    }
//    if (responseType == UAF_OPERATION_COMPLETION_STATUS) {
//        responseTypeStr = @"UAF_OPERATION_COMPLETION_STATUS";
//    }
//    NSString *str = [NSString stringWithFormat:@"%@://x-callback-url/%d?x-success=%@://x-callback-url/%d&key=%@&state=%@&json=%@",targetUrl,requestType,@"com.i-sprint.DemoApp",responseType,Key,state,json];
//    return str;
//}

/*!

* @brief 把格式化的JSON格式的字符串转换成字典

* @param jsonString JSON格式的字符串

* @return 返回字典

*/

//json格式字符串转字典：

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        
        return nil;
        
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        [Helper printDebug:[NSString stringWithFormat:@"json解析失败：%@",err]];
        return nil;
        
    }
    
    return dic;
    
}

//字典转json格式字符串：

+ (NSString*)dictionaryToJsonStr:(NSDictionary *)dic

{
    
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //NSJSONWritingPrettyPrinted  是有换位符的。
    //
    //如果NSJSONWritingPrettyPrinted 是nil 的话 返回的数据是没有 换位符的
}


/*
 *   检测设备指纹
 *
 *
 *
 */


+ (NSString *)checkFinger {
    NSString *message = nil;
    //初始化上下文对象
    LAContext* context = [[LAContext alloc] init];
    //错误对象
    NSError* error = nil;
    //NSString* result = @"Authentication is needed to access your notes.";
    
    //首先使用canEvaluatePolicy 判断设备支持状态
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        //支持指纹验证
        //        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:result reply:^(BOOL success, NSError *error) {
        //            if (success) {
        //                //验证成功，主线程处理UI
        //            }
        //            else
        //            {
        //                NSLog(@"%@",error.localizedDescription);
        //                switch (error.code) {
        //                    case LAErrorSystemCancel:
        //                    {
        //                        NSLog(@"Authentication was cancelled by the system");
        //                        //切换到其他APP，系统取消验证Touch ID
        //                        break;
        //                    }
        //                    case LAErrorUserCancel:
        //                    {
        //                        NSLog(@"Authentication was cancelled by the user");
        //                        //用户取消验证Touch ID
        //                        break;
        //                    }
        //                    case LAErrorUserFallback:
        //                    {
        //                        NSLog(@"User selected to enter custom password");
        //                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //                            //用户选择输入密码，切换主线程处理
        //                        }];
        //                        break;
        //                    }
        //                    default:
        //                    {
        //                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //                            //其他情况，切换主线程处理
        //                        }];
        //                        break;
        //                    }
        //                }
        //            }
        //        }];
    }
    else
    {
        //不支持指纹识别，LOG出错误详情
        switch (error.code) {
            case LAErrorTouchIDNotEnrolled:
            {
                NSLog(@"TouchID is not enrolled");
                message = NSLocalizedString(@"ERROR_TOUCHID_NOT_ENROLL", @""); //@"TouchID is not enrolled";
                break;
            }
            case LAErrorPasscodeNotSet:
            {
                NSLog(@"A passcode has not been set");
                message = NSLocalizedString(@"Fingerprint authentication is disabled or your device does not support it.", @""); //@"A passcode has not been set";
                break;
            }
            default:
            {
                NSLog(@"TouchID not available");
                message = NSLocalizedString(@"ERROR_TOUCHID_NOT_AVAILABLE", @""); //@"TouchID not available";
                break;
            }
        }
        
        NSLog(@"%@",error.localizedDescription);
        //[self showPasswordAlert];
    }
    
    return message;
}


//将十进制转化为二进制,设置返回NSString 长度
+ (NSString *)decimalTOBinary:(uint16_t)tmpid backLength:(int)length
{
    NSString *a = @"";
    while (tmpid)
    {
        a = [[NSString stringWithFormat:@"%d",tmpid%2] stringByAppendingString:a];
        if (tmpid/2 < 1) {
            break;
        }
        tmpid = tmpid/2 ;
    }
    
    if (a.length <= length)
    {
        NSMutableString *b = [[NSMutableString alloc]init];;
        for (int i = 0; i < length - a.length; i++)
        {
            [b appendString:@"0"];
        }
        
        a = [b stringByAppendingString:a];
    }
    
    return a;
    
}

+(NSString *)SerializationReceiveBase64Str:(NSString *)originStr {
    NSString *str = originStr;
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    str = [str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSInteger remainder = str.length%4;//当使用iOS自带的base64解析API的时候如果长度不是双数的话要补=字符
    if (remainder > 1 && remainder < 3) {
        str = [NSString stringWithFormat:@"%@==",str];
    } else if (remainder > 2) {
        str = [NSString stringWithFormat:@"%@=",str];
    }
    return str;
}

+(NSMutableString *)gensalt:(int)log_rounds {
    if (log_rounds < 4 || log_rounds > 31) {
        [Helper printDebug:@"Bad number of rounds"];
    }
    NSMutableString *rs = [[NSMutableString alloc]init];
    char rnd[BCRYPT_SALT_LEN];
    
    //random byte的范围
    for(int i = 0; i < BCRYPT_SALT_LEN; i++) {
        int s = (arc4random() % 256);
        rnd[i] = s;
    }
    
    [rs appendString:@"$2a$"];
    if (log_rounds < 10) {
        [rs appendString:@"0"];
    }
    [rs appendString:[NSString stringWithFormat:@"%d",log_rounds]];
    [rs appendString:@"$"];
    
    NSData *adata = [[NSData alloc] initWithBytes:rnd length:BCRYPT_SALT_LEN];
    NSString *base64Encoded = [adata base64EncodedStringWithOptions:0];//encode
    [Helper printDebug:[NSString stringWithFormat:@"gensalt base64 encode:%@",base64Encoded]];
    [rs appendString:base64Encoded];
    return rs;
}
+(NSString *)generateKeyID {
    
    NSString *keyId = [NSString stringWithFormat:@"isprint-KeyID-key-%@",[Helper gensalt:BCRYPT_SALT_LEN]];
    //    NSData *nsdataFromBase64String = [keyId dataUsingEncoding:NSUTF8StringEncoding];
    //
    //    // encode NSString from the NSData
    //    keyId = [nsdataFromBase64String base64EncodedStringWithOptions:0];
    //return @"nPuYmaADw0wV09TfZo5Y1HjXpz3IjnBI3aPizY5XrfU";
    return keyId;
}

@end
