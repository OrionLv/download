//
//  XBDownloadManager.m
//  文件下载
//
//  Created by lxb on 16/10/21.
//  Copyright © 2016年 huanshan. All rights reserved.
//

#import "XBDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface XBDownloadManager () <NSURLSessionDataDelegate>

/**NSURLSession*/
@property (nonatomic, strong)NSURLSession *session;

/**NSURLSessionTask*/
@property (nonatomic, strong) NSURLSessionDataTask *task;

/**文件的总长度*/
@property (nonatomic, assign) NSInteger currentLength;

/**写文件的流对象*/
@property (nonatomic, strong) NSOutputStream *stream;

/**文件的下载路径*/
@property (nonatomic, copy) NSString *url;

/**文件下载的进度*/
@property (nonatomic, copy) ProgressBlock progress;

/**文件完成时候的操作*/
@property (nonatomic, copy) CompleteBlock compelte;

@end

//下载文件所需要的URL
#define FileURL self.url

//文件名(沙盒中的文件名)
#define FileName [self md5:FileURL]

//文件的存放路径(cache)
#define CacheFilePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:FileName]

//存储文件总长度的存放路径(cache)
#define TotalLengthFilePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"totalLength.plist"]

//文件已经下载的长度
#define FileInterger [[[NSFileManager defaultManager] attributesOfItemAtPath:CacheFilePath error:nil][NSFileSize] integerValue]

@implementation XBDownloadManager

static XBDownloadManager *_manger;

#pragma mark - 单例的初始化操作
+(instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manger = [[self alloc] init];
    });
    return _manger;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manger = [super allocWithZone:zone];
    });
    
    return _manger;
}

#pragma mark - 懒加载文件
-(NSURLSession *)session
{
    if(!_session)
    {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

-(NSOutputStream *)stream
{
    if(!_stream)
    {
        _stream = [NSOutputStream outputStreamToFileAtPath:CacheFilePath append:YES];
    }
    return _stream;
}

-(NSURLSessionDataTask *)task
{
    if(!_task)
    {
        NSInteger totalLength = [[NSDictionary dictionaryWithContentsOfFile:TotalLengthFilePath][FileName] integerValue];
        
        if(totalLength && FileInterger == totalLength)
        {
            NSLog(@"文件已经下载过了");
            return nil;
        }
        
        //创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:FileURL]];
        
        //设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", FileInterger];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        //创建data任务
        _task = [self.session dataTaskWithRequest:request];
    }
    
    return _task;
}

#pragma mark - 下载处理
-(void)xb_download:(NSString *)url progress:(ProgressBlock)progress compeleted:(CompleteBlock)compelete
{
    self.url = url;
    
    //启动任务
    [self.task resume];
    
    //赋值
    self.progress = progress;
    
    self.compelte = compelete;

}

-(void)xb_pauseDownload
{
    [self.task suspend];
}

#pragma mark - <NSURLSessionDataDelegate>
/**接收到响应*/
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    //打开流
    [self.stream open];
    
    //获得服务器这次请求返回数据的总长度
    self.currentLength = [response.allHeaderFields[@"Content-Length"] integerValue] + FileInterger;
    
    //存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:TotalLengthFilePath];
    
    if(dict == nil)
    {
        dict = [NSMutableDictionary dictionary];
    }
    dict[FileName] = @(self.currentLength);
    
    [dict writeToFile:TotalLengthFilePath atomically:YES];
    
    //接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**接收到服务器返回的数据（这个方法被调用的次数可能会有点多）*/
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //写入数据
    [self.stream write:data.bytes maxLength:data.length];
    
    //目前的下载长度
    NSInteger filecurrentLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:CacheFilePath error:nil][NSFileSize] integerValue];
    
    self.progress(1.0 * filecurrentLength / self.currentLength);
    
}

/**请求完毕*/
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //完成调用Block
    self.compelte(error, CacheFilePath);
    
    //关闭流
    [self.stream close];
    self.stream = nil;
    
    //清除任务
    self.task = nil;
    
    self.progress = nil;
}


#pragma mark - 文件加密处理
-(NSString *)md5:(NSString *)str
{
    
    if (str == nil) {
        return nil;
    }
    const char *cstr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (unsigned int)strlen(cstr), result);
    
    return [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]];
}

@end
