//
//  ViewController.m
//  ScanViewUtil
//
//  Created by LYG on 15/3/23.
//  Copyright (c) 2015年 cndatacom. All rights reserved.
//

#import "ViewController.h"
#import "UIZBarScanViewController.h"


@interface ViewController ()<ZBarScanDidFinishedDelegate,UIAlertViewDelegate>{
    UIZBarScanViewController *_scanVC;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)zbarScanAction:(id)sender {

    UIZBarScanViewController *zbarScanVC = [[UIZBarScanViewController alloc]init];
    zbarScanVC.delegate = self;
    UINavigationController *zbarNVC = [[UINavigationController alloc]initWithRootViewController:zbarScanVC];
    [self presentViewController:zbarNVC animated:YES completion:nil];
    
}


#pragma mark -- ZBarScanDidFinishedDelegate
/**
 *  扫描结束回调
 *
 *  @param result  结果
 *  @param viewCtl 扫描视图控制器
 */
- (void)scanfinishedWithResult:(NSString *)result viewCtl:(UIZBarScanViewController *)viewCtrl{
    _scanVC = viewCtrl;
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil
                                                    message:result
                                                   delegate:self
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:@"Ok", nil];
    [alert show];
}
/**
 *  扫描取消
 *
 *  @param result 扫描视图控制器
 */
- (void)scanCanceled:(UIZBarScanViewController *)viewCtrl{
    [viewCtrl stopScan];
    _scanVC = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [_scanVC startScan];
    }else{
        [_scanVC stopScan];
        [_scanVC dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
