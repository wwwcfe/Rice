//
//  DetailViewController.h
//  Rice
//
//  Created by wwwcfe on 2014/09/20.
//  Copyright (c) 2014年 wwwcfe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

