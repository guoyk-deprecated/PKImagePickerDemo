//
//  MyImagePickerViewController.m
//  cameratestapp
//
//  Created by pavan krishnamurthy on 6/24/14.
//  Copyright (c) 2014 pavan krishnamurthy. All rights reserved.
//

#import "PKImagePickerViewController.h"
#import "UIImage+fixOrientation.h"
#import <AVFoundation/AVFoundation.h>

// MARK: - Resize Overlay

@interface PKImagePickerResizeView()

@property (nonatomic, retain) UIImageView * buttonImageView;

@end

@implementation PKImagePickerResizeView

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor clearColor];
    self.buttonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PKImageBundle.bundle/resize"]];
    [self addSubview:self.buttonImageView];
  }
  return self;
}

- (void)setSelectedRect:(CGRect)selectedRect
{
  _selectedRect = selectedRect;
  [self setNeedsLayout];
  [self setNeedsDisplay];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  self.buttonImageView.center = CGPointMake(CGRectGetMaxX(self.selectedRect), CGRectGetMaxY(self.selectedRect));
}

- (void)drawRect:(CGRect)rect
{
  [super drawRect:rect];
  
  UIBezierPath * path = [UIBezierPath bezierPathWithRect:self.selectedRect];
  path.lineWidth = 4.f;
  [[UIColor whiteColor] setStroke];
  [path stroke];
}

@end

// MARK: - Selected View

typedef NS_ENUM(NSInteger, PKPanTarget) {
  PKPanTargetBox,
  PKPanTargetButton,
  PKPanTargetImage
};

@interface PKImageSelectedView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, retain) PKImagePickerResizeView * resizeView;
@property (nonatomic, retain) UIImageView * capturedImageView;

@property (nonatomic, retain) UIPinchGestureRecognizer * pinch;
@property (nonatomic, retain) UIPanGestureRecognizer * pan;
@property (nonatomic, retain) UIRotationGestureRecognizer * rotation;

@property (nonatomic, assign) BOOL isSquare;

@property (nonatomic, assign) CGFloat scaleValue;
@property (nonatomic, assign) CGFloat rotationValue;
@property (nonatomic, assign) CGPoint imageOffsetValue;
@property (nonatomic, assign) CGPoint boxOffsetValue;
@property (nonatomic, assign) CGPoint buttonOffsetValue;

@property (nonatomic, assign) PKPanTarget panTarget;

@end

@implementation PKImageSelectedView

- (id)initWithFrame:(CGRect)frame
{
  if(self = [super initWithFrame:frame]) {
    self.scaleValue = 1.f;
    self.panTarget = PKPanTargetBox;
    
    self.resizeView = [PKImagePickerResizeView new];
    self.resizeView.selectedRect = CGRectMake(20, 20, 200, 200);
    self.boxOffsetValue = CGPointMake(20, 20);
    self.buttonOffsetValue = CGPointMake(CGRectGetWidth(self.resizeView.selectedRect), CGRectGetHeight(self.resizeView.selectedRect));
    self.userInteractionEnabled = true;
    
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureAction:)];
    self.pan   = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureAction:)];
    self.rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureAction:)];
    [self addGestureRecognizer:self.pinch];
    [self addGestureRecognizer:self.pan];
    [self addGestureRecognizer:self.rotation];
    
    self.pinch.delegate = self;
    self.pan.delegate   = self;
    self.rotation.delegate = self;
  }
  return self;
}

- (void)setIsSquare:(BOOL)isSquare
{
  _isSquare = isSquare;
  
  self.resizeView.buttonImageView.hidden = isSquare;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  self.resizeView.frame = self.bounds;
}

- (void)setCapturedImageView:(UIImageView *)capturedImageView
{
  _capturedImageView = capturedImageView;
  self.imageOffsetValue = _capturedImageView.frame.origin;
  [self addSubview:capturedImageView];
}

- (void)insertResizeView
{
  [self addSubview: self.resizeView];
}

// MARK: - Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return gestureRecognizer != self.pan && otherGestureRecognizer != self.pan;
}

- (void)onGestureAction:(UIGestureRecognizer*)what
{
  if (what == _pan) {
    if (what.state == UIGestureRecognizerStateBegan) {
      CGPoint loc = [_pan locationInView:self];
      CGRect target = [self convertRect:self.resizeView.selectedRect fromView:self.resizeView];
      CGRect button = [self convertRect:self.resizeView.buttonImageView.frame fromView:self.resizeView];
      button = CGRectInset(button, -20, -20);
      if (CGRectContainsPoint(button, loc) && !self.isSquare) {
        self.panTarget = PKPanTargetButton;
        [_pan setTranslation:self.buttonOffsetValue inView:self];
      }
      else if (CGRectContainsPoint(target, loc)) {
        self.panTarget = PKPanTargetBox;
        [_pan setTranslation:self.boxOffsetValue inView:self];
      } else {
        self.panTarget = PKPanTargetImage;
        [_pan setTranslation:self.imageOffsetValue inView:self];
      }
    } else if (what.state == UIGestureRecognizerStateEnded) {
      switch (self.panTarget) {
        case PKPanTargetImage:
          self.imageOffsetValue = [_pan translationInView:self];
          break;
        case PKPanTargetButton:
          self.buttonOffsetValue = [_pan translationInView:self];
          break;
        case PKPanTargetBox:
          self.boxOffsetValue = [_pan translationInView:self];
          break;
        default:
          break;
      }
    } else if (what.state == UIGestureRecognizerStateChanged) {
      switch (self.panTarget) {
        case PKPanTargetImage:
          self.imageOffsetValue = [_pan translationInView:self];
          break;
        case PKPanTargetButton:
          self.buttonOffsetValue = [_pan translationInView:self];
          break;
        case PKPanTargetBox:
          self.boxOffsetValue = [_pan translationInView:self];
          break;
        default:
          break;
      }
    }
  } else if (what == _pinch) {
    if (what.state == UIGestureRecognizerStateBegan) {
      _pinch.scale = self.scaleValue;
    } else if (what.state == UIGestureRecognizerStateEnded) {
      self.scaleValue = _pinch.scale;
    } else if (what.state == UIGestureRecognizerStateChanged) {
      self.scaleValue = _pinch.scale;
    }
  } else if (what == _rotation) {
    if (what.state == UIGestureRecognizerStateBegan) {
      _rotation.rotation = self.rotationValue;
    } else if (what.state == UIGestureRecognizerStateEnded) {
      self.rotationValue = _rotation.rotation;
    } else if (what.state == UIGestureRecognizerStateChanged) {
      self.rotationValue = _rotation.rotation;
    }
  }
  [self commitGesture];
}

- (CGAffineTransform)imageTransform
{
  return
  CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformMakeRotation(self.rotationValue), CGAffineTransformMakeScale(self.scaleValue, self.scaleValue)), CGAffineTransformMakeTranslation(self.imageOffsetValue.x, self.imageOffsetValue.y));
}

- (UIImage*)outputImage
{
  CIImage * ciimage = [CIImage imageWithCGImage:self.capturedImageView.image.CGImage];
  CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(-self.rotationValue);
  CIImage * rotated = [ciimage imageByApplyingTransform:rotationTransform];
  CGRect cropRect = CGRectMake(self.resizeView.selectedRect.origin.x - self.capturedImageView.frame.origin.x, self.resizeView.selectedRect.origin.y - self.capturedImageView.frame.origin.y, self.resizeView.selectedRect.size.width, self.resizeView.selectedRect.size.height);
  NSLog(@"Crop: %@", NSStringFromCGRect(cropRect));
  CGRect cropRectEnlarged = CGRectApplyAffineTransform(cropRect, CGAffineTransformMakeScale(rotated.extent.size.width / self.capturedImageView.frame.size.width, rotated.extent.size.height / self.capturedImageView.frame.size.height));
  CGRect cropRectAdjusted = CGRectMake(rotated.extent.origin.x + cropRectEnlarged.origin.x, rotated.extent.origin.y + rotated.extent.size.height - cropRectEnlarged.origin.y - cropRectEnlarged.size.height, cropRectEnlarged.size.width, cropRectEnlarged.size.height);
  //return [UIImage imageWithCIImage: rotated];
  return [UIImage imageWithCIImage:[rotated imageByCroppingToRect:cropRectAdjusted]];
}

- (void)commitGesture
{
  self.capturedImageView.transform = [self imageTransform];
  if (self.panTarget != PKPanTargetImage) {
    self.buttonOffsetValue = CGPointMake(self.buttonOffsetValue.x, MAX(100, self.buttonOffsetValue.y));
    self.buttonOffsetValue = CGPointMake(MAX(100, self.buttonOffsetValue.x), self.buttonOffsetValue.y);
    self.resizeView.selectedRect = CGRectMake(self.boxOffsetValue.x, self.boxOffsetValue.y, self.buttonOffsetValue.x, self.buttonOffsetValue.y);
  }
}

@end

// MARK: - ViewController

@interface PKImagePickerViewController ()

@property(nonatomic,strong) AVCaptureSession *captureSession;
@property(nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;
@property(nonatomic,strong) AVCaptureDevice *captureDevice;
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property(nonatomic,assign) BOOL isCapturingImage;
@property(nonatomic,strong) UIImageView *capturedImageView;
@property(nonatomic,strong) UIImagePickerController *picker;
@property(nonatomic,strong) PKImageSelectedView *imageSelectedView;
@property(nonatomic,strong) UIImage *selectedImage;

@end

@implementation PKImagePickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

-(void)loadView
{
  self.view = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
}

-(BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.captureSession = [[AVCaptureSession alloc]init];
  self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
  
  self.capturedImageView = [[UIImageView alloc]init];
  self.capturedImageView.frame = self.view.frame; // just to even it out
  self.capturedImageView.backgroundColor = [UIColor clearColor];
  self.capturedImageView.userInteractionEnabled = YES;
  self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
  
  self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
  self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  self.captureVideoPreviewLayer.frame = self.view.bounds;
  [self.view.layer addSublayer:self.captureVideoPreviewLayer];
  
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  if (devices.count > 0) {
    self.captureDevice = devices[0];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    
    [self.captureSession addInput:input];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.captureSession addOutput:self.stillImageOutput];
    
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
      _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
      _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    
    UIButton *camerabutton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds)/2-50, CGRectGetHeight(self.view.bounds)-100, 100, 100)];
    [camerabutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/take-snap"] forState:UIControlStateNormal];
    [camerabutton addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [camerabutton setTintColor:[UIColor blueColor]];
    [camerabutton.layer setCornerRadius:20.0];
    [self.view addSubview:camerabutton];
    
    UIButton *flashbutton = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 36, 36)];
    [flashbutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/flash"] forState:UIControlStateNormal];
    [flashbutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/flashselected"] forState:UIControlStateSelected];
    [flashbutton addTarget:self action:@selector(flash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashbutton];
    
    UIButton *frontcamera = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-57, 10, 47, 25)];
    [frontcamera setImage:[UIImage imageNamed:@"PKImageBundle.bundle/front-camera"] forState:UIControlStateNormal];
    [frontcamera addTarget:self action:@selector(showFrontCamera:) forControlEvents:UIControlEventTouchUpInside];
    [frontcamera setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:frontcamera];
  }
  
  UIButton *album = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 46, CGRectGetHeight(self.view.frame) - 46, 36, 36)];
  [album setImage:[UIImage imageNamed:@"PKImageBundle.bundle/library"] forState:UIControlStateNormal];
  [album addTarget:self action:@selector(showalbum:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:album];
  
  UIButton *cancel = [[UIButton alloc]initWithFrame:CGRectMake(10, CGRectGetHeight(self.view.frame) - 46, 36, 36)];
  [cancel setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
  [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:cancel];
  
  self.picker = [[UIImagePickerController alloc]init];
  self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  self.picker.delegate = self;
  
  self.imageSelectedView = [[PKImageSelectedView alloc]initWithFrame:self.view.frame];
  self.imageSelectedView.isSquare = self.isSquare;
  self.imageSelectedView.backgroundColor = [UIColor blackColor];
  self.imageSelectedView.capturedImageView = self.capturedImageView;
  UIView *overlayView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-60, CGRectGetWidth(self.view.frame), 60)];
  [overlayView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.9]];
  [self.imageSelectedView insertResizeView];
  [self.imageSelectedView addSubview:overlayView];
  UIButton *selectPhotoButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(overlayView.frame)-46,CGRectGetHeight(overlayView.frame) - 10 - 36, 36, 36)];
  [selectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/selected"] forState:UIControlStateNormal];
  [selectPhotoButton addTarget:self action:@selector(photoSelected:) forControlEvents:UIControlEventTouchUpInside];
  [overlayView addSubview:selectPhotoButton];
  
  UIButton *cancelSelectPhotoButton = [[UIButton alloc]initWithFrame:CGRectMake(10, CGRectGetHeight(overlayView.frame) - 10 - 36, 36, 36)];
  [cancelSelectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
  [cancelSelectPhotoButton addTarget:self action:@selector(cancelSelectedPhoto:) forControlEvents:UIControlEventTouchUpInside];
  [overlayView addSubview:cancelSelectPhotoButton];
}

-(void)viewWillAppear:(BOOL)animated
{
  [self.captureSession startRunning];
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [self.captureSession stopRunning];
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(IBAction)capturePhoto:(id)sender
{
  self.isCapturingImage = YES;
  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in _stillImageOutput.connections)
  {
    for (AVCaptureInputPort *port in [connection inputPorts])
    {
      if ([[port mediaType] isEqual:AVMediaTypeVideo] )
      {
        videoConnection = connection;
        break;
      }
    }
    if (videoConnection) { break; }
  }
  
  [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
    
    if (imageSampleBuffer != NULL) {
      
      NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
      UIImage *capturedImage = [[UIImage alloc]initWithData:imageData scale:1].fixOrientation;
      self.isCapturingImage = NO;
      self.capturedImageView.image = capturedImage;
      [self.view addSubview:self.imageSelectedView];
      self.selectedImage = capturedImage;
      imageData = nil;
    }
  }];
  
  
}

-(IBAction)flash:(UIButton*)sender
{
  if ([self.captureDevice isFlashAvailable]) {
    if (self.captureDevice.flashActive) {
      if([self.captureDevice lockForConfiguration:nil]) {
        self.captureDevice.flashMode = AVCaptureFlashModeOff;
        [sender setTintColor:[UIColor grayColor]];
        [sender setSelected:NO];
      }
    }
    else {
      if([self.captureDevice lockForConfiguration:nil]) {
        self.captureDevice.flashMode = AVCaptureFlashModeOn;
        [sender setTintColor:[UIColor blueColor]];
        [sender setSelected:YES];
      }
    }
    [self.captureDevice unlockForConfiguration];
  }
}

-(IBAction)showFrontCamera:(id)sender
{
  if (self.isCapturingImage != YES) {
    if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
      // rear active, switch to front
      self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
      
      [self.captureSession beginConfiguration];
      AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
      for (AVCaptureInput * oldInput in self.captureSession.inputs) {
        [self.captureSession removeInput:oldInput];
      }
      [self.captureSession addInput:newInput];
      [self.captureSession commitConfiguration];
    }
    else if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
      // front active, switch to rear
      self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
      [self.captureSession beginConfiguration];
      AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
      for (AVCaptureInput * oldInput in self.captureSession.inputs) {
        [self.captureSession removeInput:oldInput];
      }
      [self.captureSession addInput:newInput];
      [self.captureSession commitConfiguration];
    }
    
    // Need to reset flash btn
  }
}
-(IBAction)showalbum:(id)sender
{
  [self presentViewController:self.picker animated:YES completion:nil];
  //
}

-(IBAction)photoSelected:(id)sender
{
  
  [self dismissViewControllerAnimated:YES completion:^{
    if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UIImage * image = [self.imageSelectedView outputImage];
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate imageSelected: image];
        });
      });
    }
    [self.imageSelectedView removeFromSuperview];
  }];
}

-(IBAction)cancelSelectedPhoto:(id)sender
{
  [self.imageSelectedView removeFromSuperview];
}

-(IBAction)cancel:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:^{
    if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
      [self.delegate imageSelectionCancelled];
    }
    
  }];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  self.selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
  
  [self dismissViewControllerAnimated:YES completion:^{
    self.capturedImageView.image = self.selectedImage.fixOrientation;
    [self.view addSubview:self.imageSelectedView];
  }];
  
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
