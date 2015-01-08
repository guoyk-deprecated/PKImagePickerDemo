PKImagePickerDemo
=================

**Replacement for UIIMagePickerController, which has camera and album integrated and easy to switch between them**

**This repo is forked from [https://github.com/pavankris/PKImagePickerDemo](https://github.com/pavankris/PKImagePickerDemo)**

**Image rotation, resize, crop added**

![PKImagePicker1](https://raw.githubusercontent.com/yanke-guo/PKImagePickerDemo/master/screenshot1.png)
![PKImagePicker2](https://raw.githubusercontent.com/yanke-guo/PKImagePickerDemo/master/screenshot2.png)

##Usage

```
#import 'PKImagePickerViewController.h'
PKImagePickerViewController *imagePicker = [[PKImagePickerViewController alloc]init];
imagePicker.delegate = self;
[self presentViewController:imagePicker animated:YES completion:nil];
```
