//
//  MyImagePickerViewController.h
//  cameratestapp
//
//  Created by pavan krishnamurthy on 6/24/14.
//  Copyright (c) 2014 pavan krishnamurthy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PKImagePickerResizeView : UIView

@property (nonatomic, assign) CGRect selectedRect;

@end

@protocol PKImagePickerViewControllerDelegate <NSObject>

-(void)imageSelected:(UIImage*)img;
-(void)imageSelectionCancelled;

@end

@interface PKImagePickerViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic,assign) BOOL isSquare;
@property(nonatomic,weak) id<PKImagePickerViewControllerDelegate> delegate;

@end
