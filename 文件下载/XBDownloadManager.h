//
//  XBDownloadManager.h
//  文件下载
//
//  Created by lxb on 16/10/21.
//  Copyright © 2016年 huanshan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ProgressBlock)(CGFloat progress);
typedef void(^CompleteBlock)(NSError *error, NSString *filePath);

@interface XBDownloadManager : NSObject

//初始化操作
+(instancetype)shareInstance;

//开始下载文件
-(void)xb_download:(NSString *)url progress:(ProgressBlock)progress compeleted:(CompleteBlock)compelete;

//暂停下载文件
-(void)xb_pauseDownload;

@end
