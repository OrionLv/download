//
//  ViewController.m
//  文件下载
//
//  Created by lxb on 16/10/21.
//  Copyright © 2016年 huanshan. All rights reserved.
//

#import "ViewController.h"
#import "XBDownloadManager.h"

@interface ViewController ()

/**下载*/
@property (nonatomic, strong)XBDownloadManager *manger;
/**进度label*/
@property (weak, nonatomic) IBOutlet UILabel *progressLable;

@end

@implementation ViewController

#pragma mark - 控件初始化的操作
- (void)viewDidLoad {
    [super viewDidLoad];
   
    NSLog(@"%@", NSHomeDirectory());
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

#pragma mark - 点击事件处理
//开始下载
- (IBAction)beginDownLoad:(id)sender {
    
    self.manger = [XBDownloadManager shareInstance];
    
    [self.manger xb_download:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4" progress:^(CGFloat progress) {

        
        NSLog(@"%f", progress);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
          
            self.progressLable.text = [NSString stringWithFormat:@"%.1f%%", progress * 100];
        });
        
        
    } compeleted:^(NSError *error, NSString *filePath) {
       
        NSLog(@"%@",filePath);
        
    }];

}

//暂停下载
- (IBAction)pauseDownLoad:(id)sender {
    
    [self.manger xb_pauseDownload];
    
}




@end
