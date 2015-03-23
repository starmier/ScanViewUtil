//
//  UIZBarScanViewController.m
//  ScanViewUtil
//
//  Created by LYG on 15/3/23.
//  Copyright (c) 2015年 cndatacom. All rights reserved.
//

#import "UIZBarScanViewController.h"
#import "ZBarSDK.h"
#import <AVFoundation/AVFoundation.h>

//工具类一UIZBarScanViewController：利用ZBarSDK封装工具，耦合度低，调用工具的类作为工具类的delegate，通过协议对扫描解析出来的结果进行处理

#define SCANVIEW_WIDTH 200
#define SCANVIEW_HEIGHT 200

@interface UIZBarScanViewController ()<ZBarReaderViewDelegate>{
    
    //设置扫描画面
    UIView *_scanView;
    ZBarReaderView *_readerView;
    
    CGRect  _imageRect;
    UIImageView *_scanAnimationImageView;

}

@property (nonatomic,retain) ZBarReaderView *readerView;
//@property (strong,nonatomic)AVCaptureDevice * device;
//@property (strong,nonatomic)AVCaptureDeviceInput * input;
//@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
//@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (nonatomic, assign) BOOL isScanning;

@end

@implementation UIZBarScanViewController

@synthesize delegate;
@synthesize readerView;
//@synthesize device,input,output,preview;
@synthesize session,isScanning;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"ZBar Scan";
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    leftBtn.frame = CGRectMake(10, 0, 60, 40);
    [leftBtn setTitle:@"返回" forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    
    //初始化扫描界面
    [self setScanView];
}

-(void)setScanView {
    self.readerView = [[ZBarReaderView alloc]init];
    self.readerView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.readerView.readerDelegate = self;
    //关闭闪光灯
    self.readerView.torchMode = 0;
    [self.view addSubview:self.readerView];
    
    //计算扫描区域
//    CGFloat midy = CGRectGetMidY(self.readerView.frame);
    CGRect scanMaskRect = CGRectMake(50, 70, 220, 220);
    self.readerView.scanCrop = [self getScanCrop:scanMaskRect readerViewBounds:self.readerView.bounds];
    
    
    //初始化试图区域
    [self initCaptureFrame:self.readerView];
    [self startScan];
    
}
- (CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)rvBounds{
    
    CGFloat x,y,width,height;
    x = rect.origin.y / rvBounds.size.height;
    y = rect.origin.x / rvBounds.size.width;
    
    width = rect.size.height / rvBounds.size.height;
    height = rect.size.width / rvBounds.size.width;
    
    return CGRectMake(x, y, width, height);
}

#pragma mark- 初始化视图区域
-(void)initCaptureFrame:(UIView *)view{
    int width = view.bounds.size.width;
    int height = view.bounds.size.height;
    
    float alphaValue = 0.4f;
    CGRect rect = CGRectMake(0, 0, 220, 220);
    rect.origin.x = (view.bounds.size.width - rect.size.width) / 2;
    rect.origin.y = 70;
    
    [view setBackgroundColor:[UIColor clearColor]];
    
    //top
    CGRect rectTop = CGRectMake(0, 0, width, rect.origin.y);
    UIView *subViewTop = [[UIView alloc] initWithFrame:rectTop];
    subViewTop.backgroundColor = [UIColor blackColor];
    subViewTop.alpha = alphaValue;
    [view addSubview:subViewTop];
    
    
    //left
    CGRect rectLeft = CGRectMake(0, rect.origin.y, rect.origin.x, rect.size.height);
    UIView *subViewLeft = [[UIView alloc] initWithFrame:rectLeft];
    subViewLeft.backgroundColor = [UIColor blackColor];
    subViewLeft.alpha = alphaValue;
    [view addSubview:subViewLeft];
    
    //right
    CGRect rectRight = CGRectMake(rect.origin.x+rect.size.width, rect.origin.y, 0, rect.size.height);
    rectRight.size.width = width - rectRight.origin.x;
    UIView *subViewRight = [[UIView alloc] initWithFrame:rectRight];
    subViewRight.backgroundColor = [UIColor blackColor];
    subViewRight.alpha = alphaValue;
    [view addSubview:subViewRight];
    
    //bottom
    CGRect rectBtm = CGRectMake(0, rect.origin.y+rect.size.height, width, 0);
    rectBtm.size.height = height - rectBtm.origin.y;
    UIView *subViewBtm = [[UIView alloc] initWithFrame:rectBtm];
    subViewBtm.backgroundColor = [UIColor blackColor];
    subViewBtm.alpha = alphaValue;
    [view addSubview:subViewBtm];
    
    
    //提示语
    CGRect tipRect = rect;
    tipRect.origin.x -= 20;
    tipRect.size.width += 40;
    tipRect.origin.y = rect.origin.y + rect.size.height + 10;
    tipRect.size.height = 26;
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:tipRect];
    tipLabel.backgroundColor = [UIColor clearColor];
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.font = [UIFont boldSystemFontOfSize:12];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [tipLabel setText:@"将二维码显示在扫描框内，即可自动扫描"];
    tipLabel.hidden = YES;
    [view addSubview:tipLabel];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:rect];
    button.backgroundColor = [UIColor clearColor];
    CALayer *buttonLayer = button.layer;
    [buttonLayer setBorderWidth:1.0f];
    [buttonLayer setBorderColor:[UIColor whiteColor].CGColor];
    button.alpha = 0.2f;
    [view addSubview:button];
    
    
    rect = _imageRect;
    rect.size.height = 1;
    _scanAnimationImageView = [[UIImageView alloc] initWithFrame:rect];
    _scanAnimationImageView.image = [UIImage imageNamed:@"scanline@2x.png"];
    [view addSubview:_scanAnimationImageView];
    
    
    CGRect buttonRect = tipRect;
    buttonRect.origin.y += tipRect.size.height + 20;
    buttonRect.origin.x = rect.origin.x;// + (rect.size.width- 80)/2;
    buttonRect.size  = CGSizeMake(rect.size.width, 36);
    UIView *buttonView = [[UIView alloc] initWithFrame:buttonRect];
    buttonView.backgroundColor = [UIColor blackColor];
    buttonView.alpha = 0.2f;
    buttonView.layer.borderWidth = 2;
    buttonView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UIButton *lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    lightButton.frame = buttonRect;
    lightButton.backgroundColor = [UIColor clearColor];
    [lightButton setTitle:@"开灯" forState:UIControlStateNormal];
    [lightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [lightButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [lightButton addTarget:self action:@selector(onLightButtonHandle:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:buttonView];
    [view addSubview:lightButton];
}
#pragma mark -- 开灯
- (void)onLightButtonHandle:(id)sender
{
    UIButton *button = sender;
    
    [button setSelected:!button.selected];
    if (button.selected) {
        [button.layer setBorderWidth:2];
        [button.layer setBorderColor:[UIColor whiteColor].CGColor];
        [button setTitle:@"关灯" forState:UIControlStateNormal];
    }else
    {
        [button.layer setBorderWidth:0];
        [button.layer setBorderColor:[UIColor whiteColor].CGColor];
        [button setTitle:@"开灯" forState:UIControlStateNormal];
    }
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    __block BOOL enable = button.selected;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self enableCaptureTorch:enable];
    }];
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self enableCaptureTorch:enable];
//    });
    
}
/**
 *  开启或关闭照明灯
 *
 *  @param enable 开启或关闭状态
 */
- (void)enableCaptureTorch:(BOOL)enable
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch]) {
        NSLog(@"no torch");
    }else{
        [device lockForConfiguration:nil];
        if (enable) {
            [device setTorchMode: AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode: AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma mark -- scan
- (void)startScan
{
    self.isScanning = YES;
    if (self.session ) {
        [self.session startRunning];
    }
    if(self.readerView){
        [self.readerView start];
    }
    [self addScanAnimation];
}

- (void)stopScan
{
    [_scanAnimationImageView.layer removeAllAnimations];
    self.isScanning = NO;
    if (self.session) {
        [self.session stopRunning];
    }
    if (self.readerView) {
        [self.readerView stop];
    }
}

#pragma mark- 添加动画
- (void)addScanAnimation
{
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    theAnimation.fromValue = [NSNumber numberWithFloat:0];
    theAnimation.toValue = [NSNumber numberWithFloat:_imageRect.size.height];
    theAnimation.removedOnCompletion = NO;
    theAnimation.repeatCount = FLT_MAX;
    theAnimation.fillMode = kCAFillModeForwards;
    theAnimation.duration = 4;
    [_scanAnimationImageView.layer addAnimation:theAnimation forKey:@"ScanAnimation"];
}

#pragma mark -- ZBarReaderViewDelegate
-(void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image{
    
    NSString * result;
    for (ZBarSymbol *symbol in symbols) {
        
        NSLog(@"%@", symbol.data);
        
        if ([symbol.data canBeConvertedToEncoding:NSShiftJISStringEncoding])
            
        {
            result = [NSString stringWithCString:[symbol.data cStringUsingEncoding: NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
        }
        else
        {
            result = symbol.data;
        }
        if ([result length] > 0) {
            break;
        }
    }
    if ([result length] > 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(scanfinishedWithResult:viewCtl:)]) {
                [self.delegate scanfinishedWithResult:result viewCtl:self];
            }
            
        });
    }

}

-(void)cancel:(UIButton *)sender{
    [self.delegate scanCanceled:self];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
