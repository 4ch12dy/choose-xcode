//
//  ViewController.m
//  choose
//
//  Created by didi on 2019/7/20.
//  Copyright © 2019 didi. All rights reserved.
//

#import "ViewController.h"
#import "choose.h"
#import <mach-o/dyld.h>
@interface ViewController ()

@property(nonatomic,strong) UITextView* log;
@property(nonatomic,strong) UITextView* inputClass;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@", self);
    CGFloat screenWid = [[UIScreen mainScreen] bounds].size.width;
    _inputClass = [[UITextView alloc] initWithFrame:CGRectMake(50, 100, screenWid-2*50, 30)];
    _inputClass.backgroundColor = [UIColor purpleColor];
    _inputClass.textColor = [UIColor whiteColor];
    _inputClass.text  = @"ViewController";
    [self.view addSubview:_inputClass];
    
    UIButton* chz = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, screenWid-2*50, 50)];
    [chz setTitle:@"choose" forState:UIControlStateNormal];
    [chz setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [chz addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    [chz.layer setCornerRadius:9];
    chz.clipsToBounds=YES;
    [chz setBackgroundImage:[self imageFromColor:[self colorWithRGBValue:0x4a4c5b]] forState:UIControlStateNormal];
    [chz setBackgroundImage:[self imageFromColor:[self colorWithRGBValue:0x434551]] forState:UIControlStateHighlighted];

    [self.view addSubview:chz];
    
    _log = [[UITextView alloc] initWithFrame:CGRectMake(50, 300, screenWid-2*50, 150)];
    _log.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_log];
}



- (void)onClick:(UIButton*)sender{
    NSString* chzClass = _inputClass.text;
    NSArray* objArr = [choose choose:chzClass];
    _log.text = [NSString stringWithFormat:@"%@", objArr];
}


- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIColor *)colorWithRGBValue:(uint)value {
    uint r = (value & 0x00FF0000) >> 16;
    uint g = (value & 0x0000FF00) >> 8;
    uint b = (value & 0x000000FF);
    
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}


@end
