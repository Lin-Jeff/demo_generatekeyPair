//
//  Helper.h
//  navigate@SRPL
//
//  Created by hongyu on 8/5/16.
//  Copyright © 2016 hongyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
//#import "Utils.h"


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBandAlpha(rgbValue , alphavalue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alphavalue]

#define _httpContentTypeHeader @"Content-Type"
#define _contentTypeJSON @"application/json"
#define GET  @"GET"
#define POST @"POST"

#define YESSAFEERRORDOMAIN @"YESSAFE_ERROR_DOMAIN"


typedef NS_ENUM(NSInteger, FIDO_Operation) {
    FIDO_Reg = 0,
    FIDO_Auth ,
    FIDO_Dereg
};

typedef enum {
    NO_ERROR                    = 0x0, //
    WAIT_USER_ACTION            = 0x1, //
    INSECURE_TRANSPORT          = 0x2, //
    USER_CANCELLED              = 0x3, //
    UNSUPPORTED_VERSION         = 0x4, //
    NO_SUITABLE_AUTHENTICATOR   = 0x5, //
    PROTOCOL_ERROR              = 0x6, //
    UNTRUSTED_FACET_ID          = 0x7, //
    UNKNOWN                     = 0xFF //
} ErrorCode;

typedef NS_ENUM(short, UAFxType) {
    DISCOVER                        = 0,
    DISCOVER_RESULT                 = 1,
    CHECK_POLICY                    = 2,
    CHECK_POLICY_RESULT             = 3,
    UAF_OPERATION                   = 4,
    UAF_OPERATION_RESULT            = 5,
    UAF_OPERATION_COMPLETION_STATUS = 6
};

typedef enum {
    Reg              = 1, //
    Auth      = 2, //
} RequestType;


@interface Helper : NSObject<NSURLSessionDelegate>
//...
+ (CAGradientLayer *)setgradient:(NSArray *)array withSuperV:(UIView *) superV;
//...
+ (UIImage *)ArcimageWithColor:(UIColor *)color size:(CGSize)size Radius:(CGFloat)radius;
//根据提供的图片size设置btn的imageEdgeInsets
+(void)CustomBtnSetInsert:(UIButton *)btn withImg:(UIImage *)img;
//get file path
+ (NSString *)filePath:(NSString *)fileName;

//use for log
+(void)enableLog:(BOOL)b;
//判断是否调试模式
+(BOOL)isDebug ;
+(void)printDebug:(NSString *)mes;
//get sigle initialize
+(Helper *)sharedInstance;
//NSURLSecction request
+ (NSMutableURLRequest *)buildRequest:(NSString *)endpoint method:(NSString *)method body:(NSData *)body;
- (void)performRequest:(NSMutableURLRequest *)request Callback:(void(^ _Nonnull)( id _Nullable result , NSError * _Nullable error))callback;
/*
 *添加多section参数，输入自定义configure的section
 */
- (void)performWithDefaultSectionRequest:(NSMutableURLRequest *)request Callback:(void(^ _Nonnull)( id _Nullable result , NSError * _Nullable error ))callback ;


+(NSData * _Nullable )dictionaryToJSON:(NSDictionary * _Nonnull)dict;

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC;

//iOS获取当天0点
+ (NSDate *)zeroOfDate;

#pragma mark ---------start---------文件操作
/**
 *  获取沙盒路径
 *
 *  @param filename 新加入的目录路径
 *
 *  @return NSString全路径
 */
+ (NSString *)sandBoxPath:(NSString *)filename;

/**
 *  获得下载文件的文件夹路径
 *
 *  @param fileName 文件名称
 *
 *  @return NSString
 */
+ (NSString *)downFolderOfSandBoxPath:(NSString *)fileName;

/**
 *  获得本地下载的文件列表数组
 *
 *  @return NSMutableArray
 */
+ (NSMutableArray *)getSandBoxOfDownFileArray;

/**
 *  清除沙盒中下载的文件(下载和临时)
 *
 *  @param fileArray 需要清除的文件数组
 *
 *  @return BOOL YES:清除成功  NO:清除失败
 */
+ (NSMutableArray *)clearSandBoxOfDownFileWithFileArray:(NSMutableArray *)fileArray;

/**
 *  创建文件夹
 */
+ (void)createDownFile;

/**
 *  写入文件
 *
 *  @param sourcePath     来源路径
 *  @param targetFileName 目的文件名称
 */
+ (NSString *)writeFileWithSourcePath:(NSString *)sourcePath withTargetFileName:(NSString *)targetFileName;

/**
 *  删除临时目录中的文件
 *
 *  @param sourcePath 来源路径
 */
+ (void)deleteFileWithSourcePath:(NSString *)sourcePath;

/**
 *  截取出路径中的文件名称
 *
 *  @param filePath 文件路径
 *
 *  @return NSString
 */
+ (NSString *)cutOutFileNameWithFilePath:(NSString *)filePath;

+ (NSString *)cutOutFileTypeWithFilePath:(NSString *)filePath;

/**
 *  判断此文件是否存在
 *
 *  @param fileName 文件的路径
 *
 *  @return BOOL yes:存在  no:不存在
 */
+ (BOOL)judgeIsExistOfFilePath:(NSString *)filePath;

/**
 *  alert view controller
 *
 *  VC  在哪个viewcontoller
 *  mes message
 *  ok／cancel 是否需要显示Ok／cancel按钮
 *  okHandel／cancelHandel 相应的ok／cancel 按钮的点击事件处理
 *
 */
+ (void)showOkayCancelAlert:(UIViewController *)VC mes:(NSString *)mes ok:(BOOL)ok cancel:(BOOL)canel okHandel:(void(^)())okHandel cancemHandel:(void(^)())cancemHandel;

/**
 *  get the path which you Provide the dir and filename
 *
 *
 */
+ (NSString *)filePathDir:(NSString *)dir name:(NSString *)fileName;


/*
 *获取初始化设置是否完成
 */
+ (void)setStateInitializeSetting;
+ (void)setStateInitializeSetFinished;
+ (BOOL)getInitializeSetState;

/*
 *判断值是否为空，空返回空字符串
 */
+(NSString *)isNullValue:(id)value;


/*
 * 缓存地图到本地
 *
 *
 *
 */
+(BOOL)saveMap:(UIImage *)img;
+(void)removeMap;
+(NSString *)getMapPath;

/*
 * 缓存cover到本地
 *
 *
 *
 */
+(BOOL)saveCover:(NSData *)data WithName:(NSString *)name;
+(void)removeCover;
+(NSString *)getCoverPath:(NSString *)name;
+(BOOL)isCoverExist:(NSString *)name;


/*
 *获取设备信息
 */

+(NSString *)getDeviceInfo;

/*
 *  PostStats
 *
 */
-(void)postStatsRequest:(NSArray *)headers :(NSArray *)values Callback:(void(^ _Nonnull)())callback;


/*
 *
 * build X-Callback-URL Transport
 *
 *
 *
 */
//+(NSString *)buildXCallbackURL:(NSString *)targetUrl :(UAFxType)requestType :(UAFxType)responseType :(NSString *)Key :(NSString *)state :jsonStr:(NSString *)json;

//json格式字符串转字典：
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString ;
//字典转json格式字符串：
+ (NSString*)dictionaryToJsonStr:(NSDictionary *)dic;

/*
 *   检测设备指纹
 */
+ (NSString *)checkFinger;

#pragma UIAlterView function
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message withDelegate:(id)delegate;
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message delegate:(id)_delegate;
+(void)showUIAlertView:(NSString *)title andmessage:(NSString *)message delegate:(id)_delegate withTag:(NSInteger)tag;

//将十进制转化为二进制,设置返回NSString 长度
+ (NSString *)decimalTOBinary:(uint16_t)tmpid backLength:(int)length;


//use for log
+(void)enableLog:(BOOL)b;
//判断是否调试模式
+(BOOL)isDebug ;
+(void)printDebug:(NSString *)mes;
+(void)printErrorDebug:(NSString *)mes;
//当使用iOS自带的base64解析API的时候如果长度不是双数的话要补=字符
+(BOOL)isBase64Str:(NSString *)originStr;

+(NSString *)SerializationReceiveBase64Str:(NSString *)originStr;

// BCrypt parameters
+(NSMutableString *)gensalt:(int)log_rounds;
+(NSString *)generateKeyID;
@end
