//
//  UIZBarScanViewController.h
//  ScanViewUtil
//
//  Created by LYG on 15/3/23.
//  Copyright (c) 2015年 cndatacom. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIZBarScanViewController;

/**
 *  扫描回调协议
 */
@protocol ZBarScanDidFinishedDelegate <NSObject>
/**
 *  扫描结束回调
 *
 *  @param result  结果
 *  @param viewCtl 扫描视图控制器
 */
- (void)scanfinishedWithResult:(NSString *)result viewCtl:(UIZBarScanViewController *)viewCtrl;
/**
 *  扫描取消
 *
 *  @param result 扫描视图控制器
 */
- (void)scanCanceled:(UIZBarScanViewController *)viewCtrl;

@end

/**
 *  zBar扫描视图控制器
 */
@interface UIZBarScanViewController : UIViewController

@property(nonatomic,assign) id <ZBarScanDidFinishedDelegate>delegate;

- (void)startScan;

- (void)stopScan;

@end
